# 統計検定学習用ワークスペース

このリポジトリは、日本語 LaTeX PDF の作成と、Python による図や補助スクリプトの実行に使います。

## ディレクトリ構成

- `setup/`: 環境構築用スクリプトと依存定義
- `scripts/`: 実処理用の Python スクリプト
- `images/`: 元画像
- `src/`: 生成する教材

## セットアップ方法

### macOS

```bash
bash ./setup/setup_mac.sh
```

### Windows

管理者権限の PowerShell で実行してください。

```powershell
powershell -ExecutionPolicy Bypass -File .\setup\setup_windows.ps1
```

## セットアップ内容

- 必要なツールの確認と導入
- LaTeX 実行環境の準備
- プロジェクト用 `.venv` の作成
- `setup/requirements.lock` に基づく Python 依存の同期
- LuaLaTeX のスモークテスト
- Python 環境のスモークテスト

セットアップ後の基本確認は、各セットアップスクリプトの中で自動実行されます。

## セットアップ後

- Python スクリプトは `uv` を使って実行してください
- 独自の `.tex` ファイルを試す場合は `lualatex <filename>.tex` を実行してください

## 利用できるスキル

- `stats-workbook-builder`
- `stats-past-exam-explainer`
- `stats-weakness-analyzer`

## スキルの使い分け

- 画像からワークブックを作るときは `stats-workbook-builder`
- 過去問 1 問を詳しく解説するときは `stats-past-exam-explainer`
- 特定の苦手分野に絞った補強資料を作るときは `stats-weakness-analyzer`
- 軽い質問や確認だけなら、そのままチャットでやり取りしてください
