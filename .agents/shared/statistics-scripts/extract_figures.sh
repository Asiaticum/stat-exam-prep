#!/usr/bin/env bash
# Extract figures (charts, graphs, images) from textbook photos.
#
# Usage:
#   .agents/shared/statistics-scripts/extract_figures.sh <relative_path_under_images> <dest_dir>
#
# Example:
#   .agents/shared/statistics-scripts/extract_figures.sh textbook/15 src/textbook/15-stochastic-processes
#
# This will:
#   1. Run extract_figures.py on images/<relative_path_under_images>/
#   2. Save cropped figures to <dest_dir>/figures/
#   3. Print a JSON manifest to stdout listing extracted files

set -euo pipefail

RELATIVE_PATH="${1:?Usage: $0 <relative_path_under_images> <dest_dir>}"
DEST_DIR="${2:?Usage: $0 <relative_path_under_images> <dest_dir>}"

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
IMG_DIR="$PROJECT_ROOT/images/$RELATIVE_PATH"
OUT_DIR="$PROJECT_ROOT/$DEST_DIR/figures"

if [ ! -d "$IMG_DIR" ]; then
    echo "Error: $IMG_DIR does not exist" >&2
    exit 1
fi

if [ ! -d "$PROJECT_ROOT/.venv" ]; then
    echo "First run: setting up Python environment..." >&2
    bash "$PROJECT_ROOT/setup/setup_mac.sh" >&2
fi

mkdir -p "$OUT_DIR"

uv run "$PROJECT_ROOT/scripts/extract_figures.py" "$IMG_DIR" -o "$OUT_DIR" --json 2>&1
