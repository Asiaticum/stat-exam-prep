#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/Library/TeX/texbin:$HOME/.local/bin:$PATH"

ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi

    echo "Homebrew が見つからないため、インストールします..."
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

    echo "uv が見つからないため、インストールします..."
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
    sudo tlmgr update --self

    echo "この環境で必要な TeX Live パッケージをインストールします..."
    sudo tlmgr install "${packages[@]}"
}

run_python_setup() {
    echo "Python 環境をセットアップします..."
    bash "$PROJECT_ROOT/python_env/setup.sh"
}

run_latex_smoke_test() {
    echo "LuaLaTeX の動作確認を実行します..."

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
\section*{動作確認}
LuaLaTeX と日本語・数式パッケージの確認。
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
    echo "=== macOS 数学学習環境セットアップ ==="
    echo "プロジェクトルート: $PROJECT_ROOT"
    echo ""

    ensure_homebrew
    ensure_uv
    ensure_mactex
    install_texlive_packages
    run_python_setup
    run_latex_smoke_test

    echo ""
    echo "セットアップが完了しました。"
    echo ""
    echo "次に行うこと:"
    echo "  1. シェルを再起動するか、次を実行して PATH を反映してください:"
    echo "     export PATH=\"/Library/TeX/texbin:\$HOME/.local/bin:\$PATH\""
    echo "  2. 仮想環境を手動で確認したい場合は、次を実行してください:"
    echo "     source \"$PROJECT_ROOT/.venv/bin/activate\""
    echo "  3. Python 側の確認は、次で行えます:"
    echo "     uv run python -c \"import matplotlib_fontja, numpy, scipy, pandas\""
    echo "  4. Python で図や補助スクリプトを実行するときは、引き続き uv を使ってください。"
}

main "$@"
