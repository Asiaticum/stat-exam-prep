# Math Study Environment Setup

このリポジトリでは、数式入り PDF の作成と、Python による図表生成をまとめて扱えるようにしています。

- TeX: `LuaLaTeX` + 日本語対応
- Python: `uv` + `.venv`
- 描画系: `matplotlib`, `scipy`, `numpy`, `pandas`
- 日本語描画: `matplotlib_fontja`

セットアップスクリプトは、まだ自分の `.tex` ファイルやノートが何もない状態でも実行できます。スクリプト内部で一時ファイルを使って LuaLaTeX の確認まで自動で行います。

## Files

- macOS: [scripts/setup_mac.sh](./scripts/setup_mac.sh)
- Windows: [scripts/setup_windows.ps1](./scripts/setup_windows.ps1)
- Python only: [python_env/setup.sh](./python_env/setup.sh)

## What Gets Installed

### Python side

- `uv`
- Python `3.12`
- project local virtual environment: `.venv`
- locked dependencies from `python_env/requirements.lock`

主な Python パッケージ:

- `matplotlib`
- `seaborn`
- `numpy`
- `scipy`
- `pandas`
- `matplotlib-fontja`
- `opencv-python`
- `pillow`
- `torch`
- `torchvision`
- `transformers`

### TeX side

macOS:

- `MacTeX`
- 追加 TeX Live packages:
  - `collection-langjapanese`
  - `collection-latexrecommended`
  - `collection-latexextra`
  - `collection-pictures`
  - `collection-fontsrecommended`
  - `latexmk`

Windows:

- `TeX Live`
- 上と同じ追加 package collection

## Setup

### macOS

```bash
bash ./scripts/setup_mac.sh
```

このスクリプトが行うこと:

- Homebrew の確認と導入
- `uv` の確認と導入
- `MacTeX` の導入
- 必要な TeX Live package の導入
- `.venv` 作成
- Python 依存の同期
- スクリプト内部の一時ファイルによる LuaLaTeX 動作確認

### Windows

PowerShell を管理者権限で開いて実行してください。

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\setup_windows.ps1"
```

このスクリプトが行うこと:

- `uv` の確認と導入
- 公式インストーラを使った `TeX Live` の導入
- 必要な TeX Live package の導入
- `.venv` 作成
- Python 依存の同期
- スクリプト内部の一時ファイルによる LuaLaTeX 動作確認

## After Setup

### Python verification

```bash
uv run python -c "import matplotlib_fontja, numpy, scipy, pandas"
```

### LaTeX verification

LuaLaTeX の基本動作確認は、セットアップスクリプト内で自動実行されます。

追加で自分のファイルを試したい場合だけ、任意の `.tex` ファイルを用意して `lualatex <filename>.tex` を実行してください。

## Notes

- Python 実行はこのリポジトリでは `uv` を使ってください。
- `matplotlib` で日本語を含む図を作るときは `import matplotlib_fontja` を入れてください。
