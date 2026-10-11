#!/usr/bin/env bash
# Run Canyons Connect against the live Supabase backend using env.json.
# Falls back to mock mode (no backend) if env.json is missing.
#
# Examples:
#   scripts/run.sh                 # chrome
#   scripts/run.sh -d macos
#   scripts/run.sh -d ios
set -euo pipefail
cd "$(dirname "$0")/.."

ARGS=("$@")
# Default to chrome if no device flag was passed.
case " ${ARGS[*]} " in *" -d "*) ;; *) ARGS+=(-d chrome);; esac

if [ -f env.json ]; then
  echo "Running with live backend (env.json)"
  exec flutter run --dart-define-from-file=env.json "${ARGS[@]}"
else
  echo "No env.json found — running in mock/demo mode."
  exec flutter run "${ARGS[@]}"
fi
