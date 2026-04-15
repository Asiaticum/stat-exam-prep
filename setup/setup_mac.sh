#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/Library/TeX/texbin:$HOME/.local/bin:$PATH"

ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi

    echo "Homebrew をインストールします..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

ensure_uv() {
    if command -v uv >/dev/null 2>&1; then
        return
    fi

    echo "uv をインストールします..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
}

ensure_mactex() {
    if command -v lualatex >/dev/null 2>&1 && command -v tlmgr >/dev/null 2>&1; then
        return
    fi

    echo "MacTeX をインストールします..."
    brew install --cask mactex-no-gui
    export PATH="/Library/TeX/texbin:$PATH"
}

refresh_mactex() {
    echo "MacTeX を更新します..."

    if brew list --cask mactex-no-gui >/dev/null 2>&1; then
        brew upgrade --cask mactex-no-gui || brew reinstall --cask mactex-no-gui
    else
        brew install --cask mactex-no-gui
    fi

    export PATH="/Library/TeX/texbin:$PATH"
    hash -r
}

update_tlmgr_self() {
    local output

    if output="$(sudo tlmgr update --self 2>&1)"; then
        printf '%s\n' "$output"
        return
    fi

    printf '%s\n' "$output"

    if [[ "$output" == *"Cross release updates are only supported"* ]]; then
        echo "TeX Live が古いため、MacTeX を更新して再試行します..."
        refresh_mactex
        sudo tlmgr update --self
        return
    fi

    return 1
}

install_texlive_packages() {
    local packages=(
        collection-langjapanese
        collection-latexrecommended
        collection-latexextra
        collection-pictures
        collection-fontsrecommended
        latexmk
    )

    echo "TeX Live マネージャを更新します..."
    update_tlmgr_self

    echo "必要な TeX Live パッケージをインストールします..."
    sudo tlmgr install "${packages[@]}"
}

run_python_setup() {
    echo "Python 環境をセットアップします..."
    echo "Installing Python 3.12 with uv..."
    uv python install 3.12

    if [ ! -d "$PROJECT_ROOT/.venv" ]; then
        echo "Creating the project virtual environment..."
        uv venv --python 3.12 --seed "$PROJECT_ROOT/.venv"
    else
        echo "The project virtual environment already exists."
    fi

    echo "Syncing dependencies from requirements.lock..."
    uv pip sync --python "$PROJECT_ROOT/.venv/bin/python" "$PROJECT_ROOT/setup/requirements.lock"
}

run_python_smoke_test() {
    echo "Running a Python smoke test..."
    "$PROJECT_ROOT/.venv/bin/python" -c "import cv2, matplotlib_fontja, numpy, pandas, PIL, pillow_heif, scipy, torch, torchvision, transformers"
}

run_latex_smoke_test() {
    echo "LuaLaTeX のスモークテストを実行します..."

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    cat >"$tmp_dir/smoke.tex" <<'EOF'
\documentclass[a4paper,11pt]{jlreq}
\usepackage{luatexja}
\usepackage{amsmath,amssymb,amsthm,bm,mathtools}
\usepackage{graphicx}
\usepackage{tikz}
\usetikzlibrary{arrows.meta,positioning,shapes.geometric}
\usepackage{geometry}
\usepackage{hyperref}
\usepackage{booktabs}
\usepackage{array}
\usepackage{multirow}
\usepackage{float}
\usepackage[no-math]{fontspec}
\usepackage[shortlabels]{enumitem}
\usepackage{needspace}
\usepackage{algorithm}
\usepackage{algorithmic}
\usepackage{url}
\geometry{left=25mm,right=25mm,top=30mm,bottom=30mm}
\begin{document}
\section*{Smoke Test}
LuaLaTeX and common math packages are available.
\[
  \int_0^1 x^2 \, dx = \frac{1}{3}
\]
\[
  \sum_{k=1}^{n} k = \frac{n(n+1)}{2}
\]
\end{document}
EOF

    (cd "$tmp_dir" && lualatex -interaction=nonstopmode -halt-on-error smoke.tex >/dev/null)
    rm -rf "$tmp_dir"
    trap - EXIT
}

main() {
    echo "=== macOS Math Study Environment Setup ==="
    echo "Project root: $PROJECT_ROOT"
    echo ""

    ensure_homebrew
    ensure_uv
    ensure_mactex
    install_texlive_packages
    run_python_setup
    run_python_smoke_test
    run_latex_smoke_test

    echo ""
    echo "Setup completed successfully."
    echo ""
    echo "Next steps:"
    echo "  1. Open a new shell if PATH changes need to be applied:"
    echo "     export PATH=\"/Library/TeX/texbin:\$HOME/.local/bin:\$PATH\""
    echo "  2. If you want to activate the project virtual environment, run:"
    echo "     source \"$PROJECT_ROOT/.venv/bin/activate\""
    echo "  3. The Python smoke test has already been completed by this script."
    echo "  4. Run your Python scripts with uv."
}

main "$@"
