#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec flutter run --dart-define=API_BASE_URL="${API_BASE_URL:-http://95.217.206.233:18080}" "$@"
