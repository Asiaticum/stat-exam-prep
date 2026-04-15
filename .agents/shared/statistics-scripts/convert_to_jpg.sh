#!/usr/bin/env bash
set -euo pipefail

RELATIVE_PATH="${1:-}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
IMAGES_ROOT="$PROJECT_ROOT/images"

if [ -n "$RELATIVE_PATH" ]; then
    IMG_DIR="$IMAGES_ROOT/$RELATIVE_PATH"
else
    IMG_DIR="$IMAGES_ROOT"
fi

if [ ! -d "$IMG_DIR" ]; then
    echo "Error: Directory $IMG_DIR does not exist."
    echo "Usage: $0 [relative_path_under_images]"
    exit 1
fi

cd "$PROJECT_ROOT"
uv run ./scripts/convert_images_to_jpg.py "$RELATIVE_PATH"
