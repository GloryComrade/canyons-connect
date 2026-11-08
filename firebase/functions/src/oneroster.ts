// OneRoster 1.1 REST client for the district's Skyward (Qmlativ) API server.
//
// Auth: OAuth 2.0 client credentials (preferred, what Skyward's API server
// issues as a "key and secret"), or a static bearer token as a fallback.
// Rostering (students, classes, teachers) and gradebook (results/lineItems)
// are separate OneRoster services; a district may grant only rostering, so
// grade calls are best-effort and never fail the whole sync.
//
// Everything network-facing goes through `fetchImpl` so tests can inject a
// fake server.

export type FetchLike = (url: string, init?: RequestInit) => Promise<Response>;

export interface OneRosterConfig {
  /** e.g. https://skyward.example.org/API/ims/oneroster/v1p1 (no trailing slash needed). */
  baseUrl: string;
  /** OAuth2 client-credentials token endpoint. Required when clientId is set. */
  tokenUrl?: string;
  clientId?: string;
  clientSecret?: string;
  /** Static bearer token, used only when no client id/secret is configured. */
  apiKey?: string;
  /** Page size for collection calls. */
  pageSize?: number;
  fetchImpl?: FetchLike;
}

export interface PeriodRow {
  period: string;
  period_index: number;
  class_name: string;
  room?: string | null;
  teacher?: string | null;
  day_type?: string;
}

export interface GradeRow {
  course: string;
  term: string;
  grade: string;
  school_year: string;
  percent?: number | null;
  teacher?: string | null;
}

export interface SkywardPayload {
  periods: PeriodRow[];
  grades: GradeRow[];
}

export class OneRosterError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = "OneRosterError";
  }
}

/** Build a config from environment variables (see env.example). */
export function configFromEnv(env: NodeJS.ProcessEnv = process.env): OneRosterConfig | null {
  const baseUrl = (env.SKYWARD_API_BASE ?? "").trim();
  if (!baseUrl) return null;
  return {
    baseUrl: normalizeBase(baseUrl),
    tokenUrl: (env.SKYWARD_TOKEN_URL ?? "").trim() || undefined,
    clientId: (env.SKYWARD_CLIENT_ID ?? "").trim() || undefined,
    clientSecret: (env.SKYWARD_CLIENT_SECRET ?? "").trim() || undefined,
    apiKey: (env.SKYWARD_API_KEY ?? "").trim() || undefined,
  };
}

/**
 * Accept either the server root or the full OneRoster path and always return
 * the `.../ims/oneroster/v1p1` base.
 */
export function normalizeBase(raw: string): string {
  const trimmed = raw.replace(/\/+$/, "");
  if (/\/ims\/oneroster\/v1p\d$/i.test(trimmed)) return trimmed;
  return `${trimmed}/ims/oneroster/v1p1`;
}

/** OneRoster filter values are single-quoted; drop quotes so input can't break out. */
export function filterValue(v: string): string {
  return encodeURIComponent(v.replace(/'/g, "").trim());
}

export class OneRosterClient {
  private token: { value: string; expiresAt: number } | null = null;
  private readonly fetchImpl: FetchLike;
  private readonly base: string;

  constructor(private readonly cfg: OneRosterConfig) {
    this.fetchImpl = cfg.fetchImpl ?? ((url, init) => fetch(url, init));
    this.base = normalizeBase(cfg.baseUrl);
    if (cfg.clientId && !cfg.tokenUrl) {
      throw new OneRosterError("SKYWARD_TOKEN_URL is required with SKYWARD_CLIENT_ID");
    }
  }

  private async authHeader(forceRefresh = false): Promise<string | null> {
    const { clientId, clientSecret, tokenUrl, apiKey } = this.cfg;
    if (clientId && clientSecret && tokenUrl) {
      if (!forceRefresh && this.token && this.token.expiresAt > Date.now() + 30_000) {
        return `Bearer ${this.token.value}`;
      }
      const basic = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
      const res = await this.fetchImpl(tokenUrl, {
        method: "POST",
        headers: {
          Authorization: `Basic ${basic}`,
          "Content-Type": "application/x-www-form-urlencoded",
          Accept: "application/json",
        },
        body: "grant_type=client_credentials",
      });
      if (!res.ok) throw new OneRosterError(`token request failed: ${res.status}`, res.status);
      const body: any = await res.json();
      if (!body?.access_token) throw new OneRosterError("token response had no access_token");
      const ttl = Number(body.expires_in ?? 3600);
      this.token = { value: String(body.access_token), expiresAt: Date.now() + ttl * 1000 };
      return `Bearer ${this.token.value}`;
    }
    return apiKey ? `Bearer ${apiKey}` : null;
  }

  /** GET a path under the OneRoster base. Retries once with a fresh token on 401. */
  async get(pathAndQuery: string): Promise<{ body: any; headers: Headers }> {
    const url = pathAndQuery.startsWith("http") ? pathAndQuery : `${this.base}${pathAndQuery}`;
    for (let attempt = 0; attempt < 2; attempt++) {
      const auth = await this.authHeader(attempt > 0);
      const headers: Record<string, string> = { Accept: "application/json" };
      if (auth) headers.Authorization = auth;
      const res = await this.fetchImpl(url, { headers });
      if (res.status === 401 && attempt === 0 && this.cfg.clientId) continue;
      if (!res.ok) throw new OneRosterError(`GET ${stripQuery(pathAndQuery)} failed: ${res.status}`, res.status);
      return { body: await res.json(), headers: res.headers };
    }
    throw new OneRosterError(`GET ${stripQuery(pathAndQuery)} unauthorized`, 401);
  }

  /** Page through a collection endpoint, returning every item under `key`. */
  async list(path: string, key: string, maxItems = 2000): Promise<any[]> {
    const size = this.cfg.pageSize ?? 100;
    const out: any[] = [];
    const sep = path.includes("?") ? "&" : "?";
    for (let offset = 0; offset < maxItems; offset += size) {
      const { body, headers } = await this.get(`${path}${sep}limit=${size}&offset=${offset}`);
      const page: any[] = Array.isArray(body?.[key]) ? body[key] : [];
      out.push(...page);
      const total = Number(headers.get("x-total-count") ?? NaN);
      if (page.length < size) break;
      if (!Number.isNaN(total) && offset + size >= total) break;
    }
    return out;
  }

  /**
   * Find the student by sourcedId, then by district identifier (student
   * number), then by username. With no key, look the student up by email.
   * Returns the OneRoster user object.
   */
  async findStudent(key: string, email?: string): Promise<any> {
    const k = key.trim();
    if (!k) {
      if (!email) throw new OneRosterError("student ID or email is required");
      return this.findOne("email", email);
    }
    try {
      const { body } = await this.get(`/students/${encodeURIComponent(k)}`);
      const u = body?.user ?? body?.student;
      if (u?.sourcedId) return u;
    } catch (e) {
      if (!(e instanceof OneRosterError) || (e.status !== 404 && e.status !== 400)) throw e;
    }
    for (const field of ["identifier", "username"]) {
      const u = await this.findOne(field, k).catch((e) => {
        if (e instanceof OneRosterError && e.status === 404) return null;
        throw e;
      });
      if (u) return u;
    }
    throw new OneRosterError("student not found", 404);
  }

  private async findOne(field: string, value: string): Promise<any> {
    const { body } = await this.get(`/students?filter=${field}%3D'${filterValue(value)}'&limit=2`);
    const users: any[] = body?.users ?? [];
    if (users.length > 1) throw new OneRosterError(`more than one student matches ${field}`);
    if (!users.length) throw new OneRosterError("student not found", 404);
    return users[0];
  }

  /**
   * Pull the student's classes, teachers, and (if allowed) grades.
   *
   * `expectedEmail` is the signed-in user's verified email. The district key
   * can read every student, so the record must belong to the person asking:
   * its OneRoster email has to match. Pass null only for local probing.
   */
  async fetchStudentData(
    studentKey: string,
    opts: { expectedEmail: string | null; now?: Date }
  ): Promise<SkywardPayload> {
    const now = opts.now ?? new Date();
    const expected = opts.expectedEmail?.trim().toLowerCase() ?? null;
    const student = await this.findStudent(studentKey, expected ?? undefined);
    if (expected !== null) {
      const actual = String(student.email ?? "").trim().toLowerCase();
      if (!actual || actual !== expected) {
        throw new OneRosterError("that student record does not belong to this account", 403);
      }
    }
    const sid: string = student.sourcedId;
    const classes = (await this.list(`/students/${encodeURIComponent(sid)}/classes`, "classes")).filter(
      (c) => (c?.status ?? "active") === "active"
    );
    if (!classes.length) throw new OneRosterError("no classes for student");

    const year = schoolYear(now);
    const rows: Array<PeriodRow & { sortKey: number }> = [];
    const grades: GradeRow[] = [];
    let gradebookAllowed = true;

    for (const cls of classes) {
      const cid: string = cls.sourcedId;
      const teacher = await this.list(`/classes/${encodeURIComponent(cid)}/teachers`, "users", 10)
        .then((ts) => teacherName(ts.find((t) => t?.status !== "tobedeleted") ?? ts[0]))
        .catch(() => null);
      const name = String(cls.title ?? cls.classCode ?? "Class");
      const period = firstPeriod(cls);
      rows.push({
        period: period ?? "",
        period_index: 0,
        class_name: name,
        room: cls.location ?? cls.metadata?.room ?? null,
        teacher,
        day_type: "regular",
        sortKey: periodSortKey(period),
      });

      if (!gradebookAllowed) continue;
      try {
        const results = await this.list(
          `/classes/${encodeURIComponent(cid)}/students/${encodeURIComponent(sid)}/results`,
          "results",
          500
        );
        const g = await this.pickGrade(results);
        if (g) grades.push({ course: name, school_year: year, teacher, ...g });
      } catch (e) {
        // 401/403/404 here means the gradebook service isn't granted; stop asking.
        if (e instanceof OneRosterError && [401, 403, 404, 501].includes(e.status ?? 0)) {
          gradebookAllowed = false;
        } else {
          throw e;
        }
      }
    }

    rows.sort((a, b) => a.sortKey - b.sortKey || a.class_name.localeCompare(b.class_name));
    const periods = rows.map(({ sortKey, ...r }, i) => ({
      ...r,
      period: r.period || String(i + 1),
      period_index: i,
    }));
    return { periods, grades };
  }

  /**
   * From a class's results, prefer term/final grade line items (Skyward
   * exposes report-card marks this way), else the most recent result.
   */
  private async pickGrade(results: any[]): Promise<Omit<GradeRow, "course" | "school_year" | "teacher"> | null> {
    const scored = results.filter((r) => r && r.status !== "tobedeleted" && (r.score != null || r.metadata?.letter));
    if (!scored.length) return null;

    const withItems = await Promise.all(
      scored.slice(0, 50).map(async (r) => {
        const ref = r.lineItem?.sourcedId;
        if (!ref) return { r, li: null as any };
        const li = await this.get(`/lineItems/${encodeURIComponent(ref)}`)
          .then(({ body }) => body?.lineItem ?? null)
          .catch(() => null);
        return { r, li };
      })
    );

    const isTerm = (li: any) =>
      /term|quarter|semester|final|report|grading period|\bq[1-4]\b|\bs[12]\b/i.test(
        `${li?.title ?? ""} ${li?.category?.title ?? ""} ${li?.description ?? ""}`
      );
    const ts = (x: { r: any }) => Date.parse(x.r.scoreDate ?? x.r.dateLastModified ?? "") || 0;
    const sorted = withItems.sort((a, b) => ts(b) - ts(a));
    const best = sorted.find((x) => isTerm(x.li)) ?? sorted[0];

    const raw = best.r.score != null ? Number(best.r.score) : null;
    const max = best.li?.resultValueMax != null ? Number(best.li.resultValueMax) : null;
    const percent =
      raw == null || Number.isNaN(raw) ? null : max && max > 0 && max !== 100 ? round1((raw / max) * 100) : round1(raw);
    const letter = best.r.metadata?.letter ?? best.r.metadata?.grade ?? letterFromPercent(percent);
    const term = best.li?.gradingPeriod?.title ?? best.li?.title ?? best.r.metadata?.term ?? "Current";
    return { term: String(term), grade: String(letter), percent };
  }
}

function stripQuery(p: string): string {
  return p.split("?")[0];
}

function teacherName(t: any): string | null {
  if (!t) return null;
  const given = (t.givenName ?? "").trim();
  const family = (t.familyName ?? "").trim();
  const full = [given, family].filter(Boolean).join(" ");
  return full || null;
}

function firstPeriod(cls: any): string | null {
  const p = Array.isArray(cls.periods) ? cls.periods[0] : cls.periods ?? cls.metadata?.period;
  if (p == null || p === "") return null;
  return String(p).trim();
}

function periodSortKey(p: string | null): number {
  if (!p) return 999;
  const m = p.match(/\d+/);
  return m ? Number(m[0]) : 500;
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function schoolYear(now: Date): string {
  const y = now.getFullYear();
  const start = now.getMonth() >= 6 ? y : y - 1;
  return `${start}-${String(start + 1).slice(2)}`;
}

export function letterFromPercent(p: number | null): string {
  if (p == null || Number.isNaN(p)) return "—";
  if (p >= 93) return "A";
  if (p >= 90) return "A-";
  if (p >= 87) return "B+";
  if (p >= 83) return "B";
  if (p >= 80) return "B-";
  if (p >= 77) return "C+";
  if (p >= 73) return "C";
  if (p >= 70) return "C-";
  if (p >= 60) return "D";
  return "F";
}
