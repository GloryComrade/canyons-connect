#!/usr/bin/env bash
# One-time setup after cloning on a new machine (two-computer workflow).
# Installs Flutter + Cloud Functions deps and tells you what still needs doing.
# See docs/SESSION-HANDOFF.md for the full picture.
set -euo pipefail
cd "$(dirname "$0")/.."

# Prefix network commands with this if a local proxy resets TLS (see handoff).
NOPROXY=(env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy)

echo "==> flutter pub get"
"${NOPROXY[@]}" flutter pub get

if [ -d firebase/functions ]; then
  echo "==> installing Cloud Functions deps"
  ( cd firebase/functions && "${NOPROXY[@]}" npm install --no-audit --no-fund )
fi

echo
echo "✅ Dependencies installed. Remaining per-machine steps:"
echo
echo "  1. Firebase CLI + FlutterFire (if not installed):"
echo "       npm install -g firebase-tools"
echo "       dart pub global activate flutterfire_cli   # add ~/.pub-cache/bin to PATH"
echo
echo "  2. Sign in + regenerate native Firebase config on THIS machine:"
echo "       firebase login"
echo "       flutterfire configure --project canyons-connect-dbd53c"
echo
echo "  3. Copy the gitignored secrets file from your other machine:"
echo "       firebase/functions/.env   (keep CREDENTIALS_ENC_KEY identical — see handoff)"
echo
echo "  Run the demo:"
echo "       flutter run -d chrome --dart-define=USE_MOCK_DATA=true"
