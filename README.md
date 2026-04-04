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

## Skills

このリポジトリには、統計検定準一級向けの教材作成用 skill があります。

### `stats-workbook-builder`

教科書や問題集の画像から、まとまったワークブック PDF を作るときに使います。

- 向いている場面:
  - 画像をもとに章単位・トピック単位で学習資料を作りたい
  - 問題文、詳しい解答、復習ポイントをまとめて整備したい
- 依頼例:
  - `この画像フォルダからワークブックを作って`
  - `PCA の範囲を教材化して`

### `stats-past-exam-explainer`

過去問 1 問をしっかり解説した資料を作るときに使います。

- 向いている場面:
  - `2021年6月 問1` のように特定の過去問を詳しく解説したい
  - 正答だけでなく、解法の流れや類題まで含めて整理したい
- 依頼例:
  - `2021年6月の問1を解説して`
  - `この過去問の解説資料を作って`

### `stats-weakness-analyzer`

特定の苦手論点に絞った「苦手対策資料」を別途作りたいときに使います。

- 向いている場面:
  - ワークブックや過去問解説を読んだあとで、なお苦手な論点だけを補強したい
  - 問題全体ではなく、特定の概念や解法パターンに絞って整理したい
- 向いていない場面:
  - その場で一言だけ確認したい
  - 1ステップだけ軽く質問したい
- 依頼例:
  - `尤度比検定の苦手対策資料を作成して`
  - `この問1で詰まった標本分散の扱いについて苦手対策資料を作って`

## Skill Selection Guide

どの skill を使うか迷ったら、次の基準で分けます。

- 画像からまとまった教材を作るなら `stats-workbook-builder`
- 特定の過去問を1問ずつ丁寧に解説するなら `stats-past-exam-explainer`
- 特定の弱点だけを切り出して補強資料を作るなら `stats-weakness-analyzer`
- 軽い質問や確認だけなら、skill を起動せずチャットでそのまま答える

`stats-workbook-builder` と `stats-past-exam-explainer` は、資料を作ったあとに必要であれば `stats-weakness-analyzer` を自然に案内してよいですが、ユーザーが単にチャットで聞きたいだけのときはそちらを起動しません。
