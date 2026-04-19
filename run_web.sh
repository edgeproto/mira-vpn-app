#!/usr/bin/env bash
# Web preview: defaults tuned for faster *first load* than `flutter run` defaults.
#
# Why this helps:
# - Debug + CanvasKit (desktop "auto" renderer) pulls a large WASM payload — slow on cold load.
# - `--web-renderer html` avoids CanvasKit; smaller download, quicker time-to-interactive.
# - `MODE=release` uses an optimized build (closest to real prod; slower compile, faster runtime).
#
# Examples:
#   ./run_web.sh
#   MODE=release ./run_web.sh
#   WEB_PORT=8080 MODE=release ./run_web.sh
set -euo pipefail
cd "$(dirname "$0")"

MODE="${MODE:-debug}"
WEB_HOST="${WEB_HOST:-0.0.0.0}"
WEB_PORT="${WEB_PORT:-7357}"
# html = lighter first load; use "auto" or "canvaskit" if you need identical rendering to desktop CanvasKit.
WEB_RENDERER="${WEB_RENDERER:-html}"

args=(
  run
  -d
  web-server
  "--web-hostname=$WEB_HOST"
  "--web-port=$WEB_PORT"
  "--web-renderer=$WEB_RENDERER"
  "--dart-define=API_BASE_URL=${API_BASE_URL:-http://127.0.0.1:8080}"
)

if [[ "$MODE" == "release" ]]; then
  args+=(--release)
elif [[ "$MODE" == "profile" ]]; then
  args+=(--profile)
fi

exec flutter "${args[@]}" "$@"
