#!/usr/bin/env bash
# Run Canyons Connect. Firebase config is compiled in via lib/firebase_options.dart
# (run `flutterfire configure` to connect a real project). Until then it runs in
# mock/demo mode automatically.
#
# Examples:
#   scripts/run.sh                 # chrome
#   scripts/run.sh -d macos
#   scripts/run.sh -d ios
set -euo pipefail
cd "$(dirname "$0")/.."

ARGS=("$@")
case " ${ARGS[*]} " in *" -d "*) ;; *) ARGS+=(-d chrome);; esac

exec flutter run "${ARGS[@]}"
