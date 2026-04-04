#!/usr/bin/env bash
set -euo pipefail

# Move to project root (one level up from python_env/)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

ensure_uv() {
    if command -v uv >/dev/null 2>&1; then
        return
    fi

    echo "uv が見つからないため、インストールします..."

    case "$(uname -s)" in
        Darwin|Linux)
            curl -LsSf https://astral.sh/uv/install.sh | sh
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        *)
            echo "エラー: ここでの自動 uv インストールは macOS/Linux のみ対応です。" >&2
            echo "Windows では scripts/setup_windows.ps1 を使ってください。" >&2
            exit 1
            ;;
    esac

    if ! command -v uv >/dev/null 2>&1; then
        echo "エラー: uv のインストールに失敗しました。" >&2
        exit 1
    fi
}

echo "=== Python 環境セットアップ ==="
echo "次の用途向けに環境を整えます:"
echo "  - 図の抽出 (extract_figures.py)"
echo "  - 数学・統計の図示 (matplotlib, seaborn, scipy)"
echo "  - 学習用の補助スクリプト"
echo ""

ensure_uv

echo "uv で Python 3.12 を利用可能にします..."
uv python install 3.12

# Create venv at project root if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "プロジェクトルートに仮想環境を作成します..."
    uv venv --python 3.12 --seed
else
    echo "プロジェクトルートの仮想環境は既に存在します。"
fi

echo "requirements.lock に基づいて依存関係を同期します..."
source .venv/bin/activate
uv pip sync python_env/requirements.lock

echo ""
echo "✓ セットアップが完了しました。"
echo ""
echo "使い方:"
echo "  source .venv/bin/activate"
echo "  uv run python -c \"import matplotlib_fontja, numpy, scipy, pandas\""
echo ""
echo "利用例:"
echo "  - uv run python_env/extract_figures.py <image_or_dir> [-o output_dir]"
echo "  - uv run <custom_script>.py"
echo ""
echo "主なインストール対象:"
echo "  - 画像処理: torch, torchvision, transformers, opencv-python"
echo "  - 描画: matplotlib, seaborn, scipy, numpy, pandas"
echo "  - 日本語表示: matplotlib-fontja"
