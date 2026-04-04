#!/usr/bin/env bash
set -euo pipefail

SUBDIR="${1:-}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

if [ -n "$SUBDIR" ]; then
    IMG_DIR="$PROJECT_ROOT/images/$SUBDIR"
else
    IMG_DIR="$PROJECT_ROOT/images"
fi

if [ ! -d "$IMG_DIR" ]; then
    echo "Error: Directory $IMG_DIR does not exist."
    echo "Usage: $0 [subfolder_under_images]"
    exit 1
fi

cd "$PROJECT_ROOT"
uv run ./convert_images_to_jpg.py "$SUBDIR"
