#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
exec "$PROJECT_ROOT/.agents/skills/stats-workbook-builder/scripts/extract_figures.sh" "$@"
