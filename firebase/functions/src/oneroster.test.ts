// Run with: npm test   (builds, then node --test)
// Exercises the OneRoster client against an in-memory fake Skyward server.
import { test } from "node:test";
import * as assert from "node:assert/strict";
import { OneRosterClient, normalizeBase, filterValue, type FetchLike } from "./oneroster";

const BASE = "https://sky.example.org/API/ims/oneroster/v1p1";
const TOKEN_URL = "https://sky.example.org/API/oauth/token";

function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...headers },
  });
}

const STUDENT = { sourcedId: "stu-1", identifier: "123456", givenName: "Ryan", email: "ryan@students.example.org" };
const OWNER = { expectedEmail: "Ryan@students.example.org" };

function fakeServer(opts: { gradebook?: boolean } = {}) {
  const calls: string[] = [];
  let tokens = 0;
  const fetchImpl: FetchLike = async (url, init) => {
    calls.push(url);
    if (url === TOKEN_URL) {
      assert.equal(init?.method, "POST");
      assert.match(String((init?.headers as any).Authorization), /^Basic /);
      tokens += 1;
      return json({ access_token: `tok${tokens}`, expires_in: 3600 });
    }
    const auth = (init?.headers as any)?.Authorization;
    if (auth !== `Bearer tok${tokens}`) return json({}, 401);
    const u = new URL(url);
    const p = u.pathname.replace("/API/ims/oneroster/v1p1", "");
    if (p === "/students/123456") return json({}, 404);
    if (p === "/students" && u.searchParams.get("filter") === "identifier='123456'") {
      return json({ users: [STUDENT] });
    }
    if (p === "/students" && u.searchParams.get("filter") === `email='${STUDENT.email}'`) {
      return json({ users: [STUDENT] });
    }
    if (p === "/students" && u.searchParams.get("filter")) return json({ users: [] });
    if (p === "/students/stu-1/classes") {
      return json({
        classes: [
          { sourcedId: "c3", title: "AP Chemistry", periods: ["3"], location: "118", status: "active" },
          { sourcedId: "c1", title: "AP Calculus BC", periods: ["1"], location: "214", status: "active" },
          { sourcedId: "cx", title: "Dropped", periods: ["2"], status: "tobedeleted" },
        ],
      });
    }
    if (p === "/classes/c1/teachers") return json({ users: [{ givenName: "Amy", familyName: "Chen" }] });
    if (p === "/classes/c3/teachers") return json({ users: [{ givenName: "Luis", familyName: "Reyes" }] });
    if (p.endsWith("/results")) {
      if (!opts.gradebook) return json({}, 403);
      if (p === "/classes/c1/students/stu-1/results") {
        return json({
          results: [
            { sourcedId: "r1", score: 18, scoreDate: "2026-10-01", lineItem: { sourcedId: "li-hw" } },
            { sourcedId: "r2", score: 91.4, scoreDate: "2026-09-30", lineItem: { sourcedId: "li-q1" } },
          ],
        });
      }
      return json({ results: [] });
    }
    if (p === "/lineItems/li-hw") return json({ lineItem: { title: "Homework 4", resultValueMax: 20 } });
    if (p === "/lineItems/li-q1") {
      return json({ lineItem: { title: "Q1 Term Grade", gradingPeriod: { title: "Q1" }, resultValueMax: 100 } });
    }
    return json({}, 404);
  };
  return { fetchImpl, calls, tokenCount: () => tokens };
}

test("normalizeBase accepts root or full path", () => {
  assert.equal(normalizeBase("https://x.org/API/"), "https://x.org/API/ims/oneroster/v1p1");
  assert.equal(normalizeBase("https://x.org/API/ims/oneroster/v1p1/"), "https://x.org/API/ims/oneroster/v1p1");
});

test("filterValue strips quotes", () => {
  assert.equal(filterValue("12' OR '1"), "12%20OR%201");
});

test("maps classes and teachers in period order; skips gradebook when forbidden", async () => {
  const srv = fakeServer();
  const client = new OneRosterClient({
    baseUrl: BASE,
    tokenUrl: TOKEN_URL,
    clientId: "id",
    clientSecret: "secret",
    fetchImpl: srv.fetchImpl,
  });
  const out = await client.fetchStudentData("123456", { ...OWNER, now: new Date("2026-11-08") });
  assert.deepEqual(
    out.periods.map((p) => [p.period, p.period_index, p.class_name, p.room, p.teacher]),
    [
      ["1", 0, "AP Calculus BC", "214", "Amy Chen"],
      ["3", 1, "AP Chemistry", "118", "Luis Reyes"],
    ]
  );
  assert.deepEqual(out.grades, []);
  // One token for the whole sync, and results only asked once after a 403.
  assert.equal(srv.tokenCount(), 1);
  assert.equal(srv.calls.filter((c) => c.endsWith("/results") || c.includes("/results?")).length, 1);
});

test("prefers the term grade line item over the newest assignment", async () => {
  const srv = fakeServer({ gradebook: true });
  const client = new OneRosterClient({
    baseUrl: BASE,
    tokenUrl: TOKEN_URL,
    clientId: "id",
    clientSecret: "secret",
    fetchImpl: srv.fetchImpl,
  });
  const out = await client.fetchStudentData("123456", { ...OWNER, now: new Date("2026-11-08") });
  assert.deepEqual(out.grades, [
    { course: "AP Calculus BC", school_year: "2026-27", teacher: "Amy Chen", term: "Q1", grade: "A-", percent: 91.4 },
  ]);
});

test("refreshes the token once on 401", async () => {
  const srv = fakeServer();
  let first = true;
  const flaky: FetchLike = async (url, init) => {
    if (first && url !== TOKEN_URL) {
      first = false;
      return json({}, 401);
    }
    return srv.fetchImpl(url, init);
  };
  const client = new OneRosterClient({ baseUrl: BASE, tokenUrl: TOKEN_URL, clientId: "id", clientSecret: "s", fetchImpl: flaky });
  const out = await client.fetchStudentData("123456", OWNER);
  assert.equal(out.periods.length, 2);
  assert.equal(srv.tokenCount(), 2);
});

test("requires a token URL with client credentials", () => {
  assert.throws(() => new OneRosterClient({ baseUrl: BASE, clientId: "id", clientSecret: "s" }), /SKYWARD_TOKEN_URL/);
});

function client(srv = fakeServer()) {
  return new OneRosterClient({ baseUrl: BASE, tokenUrl: TOKEN_URL, clientId: "id", clientSecret: "s", fetchImpl: srv.fetchImpl });
}

test("refuses a student record that belongs to someone else", async () => {
  await assert.rejects(
    client().fetchStudentData("123456", { expectedEmail: "someone.else@students.example.org" }),
    (e: any) => e.status === 403
  );
});

test("finds the student by email when no student number is given", async () => {
  const out = await client().fetchStudentData("", OWNER);
  assert.equal(out.periods.length, 2);
});

test("unknown student number is a 404", async () => {
  await assert.rejects(client().fetchStudentData("999", OWNER), (e: any) => e.status === 404);
});
