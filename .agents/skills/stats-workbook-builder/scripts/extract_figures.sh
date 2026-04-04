#!/bin/bash
# Extract figures (charts, graphs, images) from textbook photos.
#
# Usage:
#   .agents/skills/stats-workbook-builder/scripts/extract_figures.sh <subfolder> <dest_dir>
#
# Example:
#   .agents/skills/stats-workbook-builder/scripts/extract_figures.sh 15 src/textbook/15-stochastic-processes
#
# This will:
#   1. Run extract_figures.py on images/<subfolder>/
#   2. Save cropped figures to <dest_dir>/figures/
#   3. Print a JSON manifest to stdout listing extracted files

set -euo pipefail

SUBFOLDER="${1:?Usage: $0 <image_subfolder> <dest_dir>}"
DEST_DIR="${2:?Usage: $0 <image_subfolder> <dest_dir>}"

PROJECT_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
PYTHON_ENV="$PROJECT_ROOT/python_env"
IMG_DIR="$PROJECT_ROOT/images/$SUBFOLDER"
OUT_DIR="$PROJECT_ROOT/$DEST_DIR/figures"

if [ ! -d "$IMG_DIR" ]; then
    echo "Error: $IMG_DIR does not exist" >&2
    exit 1
fi

# Auto-setup if venv doesn't exist
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
    echo "First run: setting up Python environment..." >&2
    bash "$PYTHON_ENV/setup.sh" >&2
fi

mkdir -p "$OUT_DIR"

# Run extraction via uv; the project venv is pinned to Python 3.12 at setup time.
uv run "$PYTHON_ENV/extract_figures.py" "$IMG_DIR" -o "$OUT_DIR" --json 2>&1
