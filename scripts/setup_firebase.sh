#!/usr/bin/env bash
# Canyons Connect — Firebase setup.
#
# After you authenticate once, this configures FlutterFire (writes
# lib/firebase_options.dart), installs + builds the Cloud Functions, and deploys
# Firestore rules, Storage rules, and Functions.
#
# Prereqs (install once):
#   npm install -g firebase-tools
#   dart pub global activate flutterfire_cli
#
# Usage:
#   firebase login                         # one-time (opens a browser)
#   scripts/setup_firebase.sh <project-id> # use/create this Firebase project
#   CREATE=1 scripts/setup_firebase.sh <new-project-id>   # create it first
set -euo pipefail
cd "$(dirname "$0")/.."

command -v firebase >/dev/null || { echo "Install the Firebase CLI:  npm install -g firebase-tools"; exit 1; }
command -v flutterfire >/dev/null || {
  echo "Install FlutterFire CLI:  dart pub global activate flutterfire_cli"
  echo "(and ensure ~/.pub-cache/bin is on your PATH)"; exit 1;
}

if ! firebase projects:list >/dev/null 2>&1; then
  echo "You're not logged in. Run:  firebase login   (opens a browser), then re-run."
  exit 1
fi

PROJECT="${1:-}"
[ -n "$PROJECT" ] || { echo "Provide a Firebase project id:  scripts/setup_firebase.sh <project-id>"; exit 1; }

if [ "${CREATE:-0}" = "1" ]; then
  echo "==> Creating Firebase project '$PROJECT'"
  firebase projects:create "$PROJECT" --display-name "Canyons Connect" || true
fi

echo "==> Selecting project"
firebase use "$PROJECT"

echo "==> Configuring FlutterFire (writes lib/firebase_options.dart + platform config)"
flutterfire configure --project "$PROJECT" --yes \
  --platforms=web,ios,android,macos,windows || flutterfire configure --project "$PROJECT"

echo "==> Building Cloud Functions"
( cd firebase/functions && npm install && npm run build )

echo "==> Deploying Firestore rules, Storage rules, and Functions"
firebase deploy --only firestore:rules,firestore:indexes,storage,functions

echo "==> Setting FUNCTIONS_BASE_URL in firebase/functions/.env"
REGION="us-central1"
BASE="https://${REGION}-${PROJECT}.cloudfunctions.net"
if grep -q '^FUNCTIONS_BASE_URL=' firebase/functions/.env 2>/dev/null; then
  # portable in-place edit
  tmp="$(mktemp)"; sed "s#^FUNCTIONS_BASE_URL=.*#FUNCTIONS_BASE_URL=${BASE}#" firebase/functions/.env > "$tmp" && mv "$tmp" firebase/functions/.env
  echo "    FUNCTIONS_BASE_URL=${BASE}  (re-deploy functions to apply)"
fi

echo
echo "✅ Firebase configured. Run the app live:"
echo "     flutter run -d chrome"
echo
echo "Still to do in the Firebase console:"
echo "  • Authentication → Sign-in method → enable Google (+ Email/Password)"
echo "  • Create the Firestore database and the default Storage bucket if prompted"
echo "  • Seed school content (one-time):"
echo "      curl \"${BASE}/seed?secret=\$(grep ^SEED_SECRET firebase/functions/.env | cut -d= -f2)\""
echo "  • Fill Canvas/GroupMe/etc. values in firebase/functions/.env, then:"
echo "      firebase deploy --only functions"
