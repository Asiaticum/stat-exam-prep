#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "Pillow>=10.0.0",
#   "pillow-heif>=0.16.0",
# ]
# ///

from __future__ import annotations

import argparse
import os
from pathlib import Path

from PIL import Image, UnidentifiedImageError
from pillow_heif import register_heif_opener

register_heif_opener()

IMAGE_EXTENSIONS = {
    ".png",
    ".bmp",
    ".tif",
    ".tiff",
    ".webp",
    ".gif",
    ".heic",
    ".heif",
    ".avif",
    ".jfif",
}

EXCLUDED_DIR_NAMES = {
    ".git",
    ".venv",
    "__pycache__",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
}


def convert_to_jpg(src: Path, dst: Path, quality: int) -> None:
    with Image.open(src) as img:
        # JPEG does not support alpha channel; flatten to white background.
        if img.mode in ("RGBA", "LA", "P"):
            rgba = img.convert("RGBA")
            background = Image.new("RGB", rgba.size, (255, 255, 255))
            background.paste(rgba, mask=rgba.split()[-1])
            rgb = background
        else:
            rgb = img.convert("RGB")

        rgb.save(dst, format="JPEG", quality=quality, optimize=True)


def find_targets(root: Path) -> list[Path]:
    targets: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [
            d for d in dirnames if d not in EXCLUDED_DIR_NAMES and not d.startswith(".")
        ]
        for filename in filenames:
            path = Path(dirpath) / filename
            ext = path.suffix.lower()
            if ext in IMAGE_EXTENSIONS:
                targets.append(path)
    return targets


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert all non-JPG images under ./images or ./images/<subdir> to JPG."
    )
    parser.add_argument(
        "subdir",
        nargs="?",
        default="",
        help="Optional subdirectory under ./images to process.",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=92,
        help="JPEG quality (1-95, default: 92).",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing JPG files if they already exist.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print conversion plan without writing files.",
    )
    args = parser.parse_args()

    if not (1 <= args.quality <= 95):
        raise SystemExit("--quality must be in range 1..95")

    root = (Path.cwd() / "images" / args.subdir).resolve()
    if not root.exists():
        raise SystemExit(f"Directory does not exist: {root}")
    if not root.is_dir():
        raise SystemExit(f"Not a directory: {root}")

    targets = find_targets(root)
    if not targets:
        print("No non-JPG image files found.")
        return 0

    converted = 0
    skipped = 0
    removed_existing = 0
    failed = 0

    for src in targets:
        dst = src.with_suffix(".jpg")
        rel_src = src.relative_to(root)
        rel_dst = dst.relative_to(root)

        if dst.exists() and not args.overwrite:
            if args.dry_run:
                print(f"PLAN-REMOVE (jpg exists): {rel_src}")
                skipped += 1
            else:
                src.unlink()
                print(f"REMOVED (jpg exists): {rel_src}")
                removed_existing += 1
            continue

        if args.dry_run:
            print(f"PLAN: {rel_src} -> {rel_dst}")
            continue

        try:
            convert_to_jpg(src, dst, args.quality)
            src.unlink()
            print(f"OK: {rel_src} -> {rel_dst}")
            converted += 1
        except (UnidentifiedImageError, OSError) as e:
            print(f"FAIL: {rel_src} ({e})")
            failed += 1

    if args.dry_run:
        print(f"Dry-run done. Planned conversions: {len(targets)}")
    else:
        print(
            "Done. "
            f"converted={converted}, removed_existing={removed_existing}, "
            f"skipped={skipped}, failed={failed}, total={len(targets)}"
        )

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
