"""教科書画像から図・グラフ領域を検出して切り出す.

PP-DocLayoutV3 (HuggingFace transformers) を直接使用。glmocr SDK 不要。

Usage:
    python scripts/extract_figures.py <image_or_dir> [-o output_dir] [--threshold 0.3] [--visualize] [--json]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import List, Dict

import cv2
import numpy as np
import torch
from PIL import Image, ImageOps
from transformers import (
    PPDocLayoutV3ForObjectDetection,
    PPDocLayoutV3ImageProcessorFast,
)

MODEL_ID = "PaddlePaddle/PP-DocLayoutV3_safetensors"

EXTRACT_LABELS = {"chart", "image"}

ID2LABEL = {
    0: "abstract", 1: "algorithm", 2: "aside_text", 3: "chart",
    4: "content", 5: "display_formula", 6: "doc_title", 7: "figure_title",
    8: "footer", 9: "footer_image", 10: "footnote", 11: "formula_number",
    12: "header", 13: "header_image", 14: "image", 15: "inline_formula",
    16: "number", 17: "paragraph_title", 18: "reference",
    19: "reference_content", 20: "seal", 21: "table", 22: "text",
    23: "vertical_text", 24: "vision_footnote",
}

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}


# --- Layout detection ---


def load_model(device: str | None = None):
    processor = PPDocLayoutV3ImageProcessorFast.from_pretrained(MODEL_ID)
    model = PPDocLayoutV3ForObjectDetection.from_pretrained(MODEL_ID)
    model.eval()

    if device is None:
        device = "cuda" if torch.cuda.is_available() else "cpu"
    model = model.to(device)
    return model, processor, device


def detect_layout(
    image: Image.Image,
    model,
    processor,
    device: str,
    threshold: float = 0.3,
) -> List[Dict]:
    """画像のレイアウトを検出し、領域リストを返す."""
    w, h = image.size
    inputs = processor(images=[image], return_tensors="pt")
    inputs = {k: v.to(device) for k, v in inputs.items()}

    with torch.no_grad():
        outputs = model(**inputs)

    target_sizes = torch.tensor([[h, w]], device=device)
    raw = processor.post_process_object_detection(
        outputs, threshold=threshold, target_sizes=target_sizes,
    )[0]

    scores = raw["scores"].cpu().numpy()
    labels = raw["labels"].cpu().numpy()
    boxes = raw["boxes"].cpu().numpy()
    polys = raw.get("polygon_points", [])

    # NMS
    if len(scores) > 1:
        keep = _nms(labels, scores, boxes)
        scores, labels, boxes = scores[keep], labels[keep], boxes[keep]
        if len(polys) > 0:
            polys = [polys[i] for i in keep]

    # Filter out image regions that cover almost the entire page
    if len(scores) > 1:
        img_area = w * h
        area_thresh = 0.82 if w > h else 0.93
        image_cls = 14  # "image"
        keep = []
        for i in range(len(scores)):
            if int(labels[i]) == image_cls:
                x1, y1, x2, y2 = boxes[i]
                box_area = max(0, x2 - x1) * max(0, y2 - y1)
                if box_area > area_thresh * img_area:
                    continue
            keep.append(i)
        if keep:
            scores, labels, boxes = scores[keep], labels[keep], boxes[keep]
            if len(polys) > 0:
                polys = [polys[i] for i in keep]

    regions = []
    for i in range(len(scores)):
        cls_id = int(labels[i])
        x1, y1, x2, y2 = boxes[i]
        x1, y1 = max(0, float(x1)), max(0, float(y1))
        x2, y2 = min(w, float(x2)), min(h, float(y2))
        if x1 >= x2 or y1 >= y2:
            continue

        poly = None
        if i < len(polys):
            p = polys[i]
            if hasattr(p, "numpy"):
                p = p.numpy()
            poly = np.array(p, dtype=np.float32)
            poly[:, 0] = np.clip(poly[:, 0], 0, w)
            poly[:, 1] = np.clip(poly[:, 1], 0, h)

        regions.append({
            "label": ID2LABEL.get(cls_id, f"class_{cls_id}"),
            "score": float(scores[i]),
            "bbox": [int(x1), int(y1), int(x2), int(y2)],
            "polygon": poly,
        })

    return regions


def _nms(
    labels: np.ndarray,
    scores: np.ndarray,
    boxes: np.ndarray,
    iou_same: float = 0.6,
    iou_diff: float = 0.95,
) -> List[int]:
    order = scores.argsort()[::-1].tolist()
    keep: List[int] = []
    while order:
        i = order.pop(0)
        keep.append(i)
        remaining = []
        for j in order:
            iou_val = _iou(boxes[i], boxes[j])
            thresh = iou_same if labels[i] == labels[j] else iou_diff
            if iou_val < thresh:
                remaining.append(j)
        order = remaining
    return keep


def _iou(a, b) -> float:
    x1 = max(a[0], b[0])
    y1 = max(a[1], b[1])
    x2 = min(a[2], b[2])
    y2 = min(a[3], b[3])
    inter = max(0, x2 - x1) * max(0, y2 - y1)
    area_a = max(0, a[2] - a[0]) * max(0, a[3] - a[1])
    area_b = max(0, b[2] - b[0]) * max(0, b[3] - b[1])
    union = area_a + area_b - inter
    return inter / union if union > 0 else 0.0


# --- Crop ---


def crop_region(
    image: Image.Image,
    bbox: List[int],
    polygon: np.ndarray | None = None,
) -> Image.Image:
    """bbox で切り出し、polygon があればマスク適用."""
    x1, y1, x2, y2 = bbox

    if polygon is None or len(polygon) < 3:
        return image.crop((x1, y1, x2, y2))

    img_arr = np.asarray(image)
    crop = img_arr[y1:y2, x1:x2].copy()
    ch, cw = crop.shape[:2]

    poly_px = np.array(
        [[int(p[0]) - x1, int(p[1]) - y1] for p in polygon], dtype=np.int32
    )
    mask = np.zeros((ch, cw), dtype=np.uint8)
    cv2.fillPoly(mask, [poly_px], 1)

    output = np.full_like(crop, 255, dtype=np.uint8)
    cv2.copyTo(crop, mask, output)
    return Image.fromarray(output)


# --- Visualization ---


_COLORS = [
    (255, 0, 0), (0, 200, 0), (0, 0, 255), (255, 165, 0),
    (128, 0, 128), (0, 200, 200), (200, 200, 0), (200, 0, 200),
]


def draw_visualization(image: Image.Image, regions: List[Dict]) -> Image.Image:
    img = np.array(image).copy()
    for i, r in enumerate(regions):
        color = _COLORS[i % len(_COLORS)]
        x1, y1, x2, y2 = r["bbox"]
        cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
        text = f"{r['label']} {r['score']:.2f}"
        cv2.putText(img, text, (x1, y1 - 6), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)
    return Image.fromarray(img)


# --- Main ---


def load_image(path: Path) -> Image.Image:
    return ImageOps.exif_transpose(Image.open(path)).convert("RGB")


def collect_images(src: Path) -> List[Path]:
    if src.is_file():
        return [src]
    return sorted(p for p in src.rglob("*") if p.suffix.lower() in IMAGE_EXTENSIONS)


def _log(msg: str, *, json_mode: bool):
    """json_mode では stdout を汚さないよう stderr に出力."""
    print(msg, file=sys.stderr if json_mode else sys.stdout)


def process(args):
    src = Path(args.input)
    json_mode = getattr(args, "json", False)

    if not src.exists():
        print(f"Error: {src} が見つかりません", file=sys.stderr)
        sys.exit(1)

    image_paths = collect_images(src)
    if not image_paths:
        print(f"Error: 画像が見つかりません: {src}", file=sys.stderr)
        sys.exit(1)

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)

    _log(f"Model: {MODEL_ID}", json_mode=json_mode)
    _log("Device: loading...", json_mode=json_mode)
    model, processor, device = load_model()
    _log(f"Device: {device}", json_mode=json_mode)
    _log(f"Threshold: {args.threshold}", json_mode=json_mode)
    _log(f"Images: {len(image_paths)}", json_mode=json_mode)
    _log("", json_mode=json_mode)

    total_extracted = 0
    manifest: List[Dict] = []

    for img_path in image_paths:
        image = load_image(img_path)
        regions = detect_layout(image, model, processor, device, args.threshold)

        figures = [r for r in regions if r["label"] in EXTRACT_LABELS]
        stem = img_path.stem

        _log(f"{img_path.name}: {len(regions)} regions, {len(figures)} figures", json_mode=json_mode)
        for r in regions:
            marker = " *" if r["label"] in EXTRACT_LABELS else ""
            _log(f"  {r['label']:20s} {r['score']:.3f}  bbox={r['bbox']}{marker}", json_mode=json_mode)

        for i, fig in enumerate(figures):
            # マージンの計算 (各辺に margin_ratio 分追加)
            x1, y1, x2, y2 = fig["bbox"]
            bw, bh = x2 - x1, y2 - y1
            margin_ratio = getattr(args, "margin", 0.05)
            mw, mh = int(bw * margin_ratio), int(bh * margin_ratio)

            # マージン適用後の座標 (画像範囲内にクリップ)
            img_w, img_h = image.size
            nx1 = max(0, x1 - mw)
            ny1 = max(0, y1 - mh)
            nx2 = min(img_w, x2 + mw)
            ny2 = min(img_h, y2 + mh)
            margin_bbox = [int(nx1), int(ny1), int(nx2), int(ny2)]

            cropped = crop_region(image, margin_bbox, fig.get("polygon"))
            suffix = f"_{i}" if len(figures) > 1 else ""
            out_path = out_dir / f"{stem}{suffix}.jpg"
            cropped.save(str(out_path), quality=95)
            _log(f"  -> {out_path}", json_mode=json_mode)
            total_extracted += 1
            manifest.append({
                "source": str(img_path.name),
                "file": str(out_path.name),
                "label": fig["label"],
                "score": round(fig["score"], 3),
                "bbox": margin_bbox,
            })

        if args.visualize:
            vis = draw_visualization(image, regions)
            vis_path = out_dir / f"{stem}_layout.jpg"
            vis.save(str(vis_path), quality=90)

    _log(f"\nDone: {total_extracted} figures extracted to {out_dir}/", json_mode=json_mode)

    if json_mode:
        print(json.dumps(manifest, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(
        description="教科書画像から図・グラフ領域を検出して切り出す",
    )
    parser.add_argument("input", help="画像ファイルまたはディレクトリ")
    parser.add_argument("-o", "--output", default="./output", help="出力ディレクトリ (default: ./output)")
    parser.add_argument("--threshold", type=float, default=0.3, help="検出閾値 (default: 0.3)")
    parser.add_argument("--margin", type=float, default=0.05, help="切り出しマージン率 (default: 0.05)")
    parser.add_argument("--visualize", action="store_true", help="レイアウト可視化画像も出力")
    parser.add_argument("--json", action="store_true", help="抽出結果のJSONマニフェストをstdoutに出力")
    args = parser.parse_args()
    process(args)


if __name__ == "__main__":
    main()
