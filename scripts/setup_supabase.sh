#!/usr/bin/env bash
# Canyons Connect — one-shot Supabase setup.
#
# After you authenticate the CLI once, this links (or creates) the project,
# applies the schema + RLS + storage + seed, sets the Edge Function secrets,
# deploys the functions, fetches your anon key, and writes env.json for the app.
#
# Usage:
#   supabase login                               # one-time (opens a browser)
#   scripts/setup_supabase.sh <project-ref>      # link an existing project
#   CREATE=1 scripts/setup_supabase.sh           # or create a brand-new project
#
# Optional env vars:
#   SUPABASE_DB_PASSWORD   db password (else you're prompted on link)
#   PROJECT_NAME           default "Canyons Connect"      (CREATE mode)
#   REGION                 default "us-west-1"            (CREATE mode)
#   ORG_ID                 org to create under (else first org)  (CREATE mode)
set -euo pipefail

cd "$(dirname "$0")/.."

command -v supabase >/dev/null \
  || { echo "Install the CLI first:  brew install supabase/tap/supabase"; exit 1; }

if ! supabase projects list >/dev/null 2>&1; then
  echo "You're not logged in. Run:  supabase login   (opens a browser), then re-run."
  exit 1
fi

REF="${1:-${SUPABASE_PROJECT_REF:-}}"

# --- Optionally create a new project -----------------------------------------
if [ -z "$REF" ] && [ "${CREATE:-0}" = "1" ]; then
  ORG="${ORG_ID:-$(supabase orgs list -o json \
    | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const a=JSON.parse(s);process.stdout.write(a[0]?.id||"")})')}"
  [ -n "$ORG" ] || { echo "No organization found. Set ORG_ID."; exit 1; }
  PW="${SUPABASE_DB_PASSWORD:-$(openssl rand -base64 18)}"
  echo "==> Creating project '${PROJECT_NAME:-Canyons Connect}' in org $ORG ..."
  OUT=$(supabase projects create "${PROJECT_NAME:-Canyons Connect}" \
        --org-id "$ORG" --db-password "$PW" --region "${REGION:-us-west-1}" -o json)
  REF=$(echo "$OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const o=JSON.parse(s);process.stdout.write(o.id||o.ref||"")})')
  echo "    Created ref: $REF"
  echo "    DB password: $PW   <-- SAVE THIS"
  export SUPABASE_DB_PASSWORD="$PW"
fi

[ -n "$REF" ] || { echo "Provide a project ref:  scripts/setup_supabase.sh <ref>   (or CREATE=1)"; exit 1; }

echo "==> Linking $REF"
if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
  supabase link --project-ref "$REF" --password "$SUPABASE_DB_PASSWORD"
else
  supabase link --project-ref "$REF"
fi

echo "==> Applying migrations (schema, RLS, storage, seed)"
supabase db push

echo "==> Setting Edge Function secrets (non-empty values only)"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
grep -vE '^\s*#|^\s*$' supabase/.env | grep -E '=.+$' > "$TMP" || true
if [ -s "$TMP" ]; then supabase secrets set --env-file "$TMP"; fi

echo "==> Deploying Edge Functions"
supabase functions deploy \
  oauth-start oauth-callback connect-credentials disconnect-integration \
  sync-now sync-scheduled canvas-webhook

echo "==> Writing env.json (SUPABASE_URL + anon key)"
URL="https://${REF}.supabase.co"
ANON="$(supabase projects api-keys --project-ref "$REF" -o json 2>/dev/null \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const a=JSON.parse(s);const k=a.find(x=>x.name==="anon");process.stdout.write(k?k.api_key:"")}catch(e){}})' || true)"
if [ -n "$ANON" ]; then
  printf '{\n  "SUPABASE_URL": "%s",\n  "SUPABASE_ANON_KEY": "%s"\n}\n' "$URL" "$ANON" > env.json
  echo "    Wrote env.json"
else
  printf '{\n  "SUPABASE_URL": "%s",\n  "SUPABASE_ANON_KEY": "PASTE_ANON_KEY_FROM_DASHBOARD"\n}\n' "$URL" > env.json
  echo "    Couldn't fetch the anon key automatically — paste it into env.json (Dashboard → Settings → API)."
fi

echo
echo "✅ Backend ready. Run the app live:"
echo "     flutter run -d chrome --dart-define-from-file=env.json"
echo
echo "Still to do in the dashboard: Auth → Providers → enable Google (+ Email),"
echo "and add redirect URLs (web origin + canyonsconnect://login-callback)."
echo "Enable the 1-minute sync cron per supabase/README.md."
