[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TeXLiveYear = (Get-Date).Year

function Add-ToPathIfExists {
    param([string]$PathEntry)

    if ((Test-Path $PathEntry) -and ($env:Path -notlike "*$PathEntry*")) {
        $env:Path = "$PathEntry;$env:Path"
    }
}

function Find-TeXLiveBin {
    $candidateRoots = @("C:\texlive", (Join-Path $env:SystemDrive "texlive"))

    foreach ($root in $candidateRoots | Select-Object -Unique) {
        if (-not (Test-Path $root)) {
            continue
        }

        $bin = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName "bin\windows" } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1

        if ($bin) {
            return $bin
        }
    }

    return $null
}

function Ensure-Uv {
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        return
    }

    Write-Host "uv が見つからないため、インストールします..."
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    Add-ToPathIfExists (Join-Path $HOME ".local\bin")

    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        throw "uv のインストールに失敗しました。新しい PowerShell を開いて再実行してください。"
    }
}

function Ensure-TeXLive {
    if (Get-Command lualatex -ErrorAction SilentlyContinue) {
        return
    }

    Write-Host "TeX Live をインストールします..."

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("texlive-installer-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    $installerPath = Join-Path $tempDir "install-tl-windows.exe"
    $profilePath = Join-Path $tempDir "texlive.profile"

    Invoke-WebRequest -Uri "https://mirror.ctan.org/systems/texlive/tlnet/install-tl-windows.exe" -OutFile $installerPath

    $profile = @"
selected_scheme scheme-full
TEXDIR C:\texlive\$TeXLiveYear
TEXMFCONFIG ~/.texlive$TeXLiveYear/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL C:\texlive\texmf-local
TEXMFSYSCONFIG C:\texlive\$TeXLiveYear\texmf-config
TEXMFSYSVAR C:\texlive\$TeXLiveYear\texmf-var
TEXMFVAR ~/.texlive$TeXLiveYear/texmf-var
binary_x64_windows 1
instopt_adjustpath 0
instopt_desktop_integration 0
instopt_file_assocs 0
instopt_letter 0
instopt_menu_integration 0
instopt_portable 0
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
"@
    Set-Content -LiteralPath $profilePath -Value $profile -Encoding ASCII

    try {
        & $installerPath --no-gui --profile $profilePath
    } finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $texBin = Find-TeXLiveBin
    if (-not $texBin) {
        throw "TeX Live のインストール後に bin\windows を検出できませんでした。"
    }

    Add-ToPathIfExists $texBin

    if (-not (Get-Command lualatex -ErrorAction SilentlyContinue)) {
        throw "TeX Live の PATH 設定に失敗しました。新しい PowerShell を開いて再実行してください。"
    }
}

function Install-TeXLivePackages {
    $texBin = Find-TeXLiveBin
    if ($texBin) {
        Add-ToPathIfExists $texBin
    }

    if (-not (Get-Command tlmgr -ErrorAction SilentlyContinue)) {
        throw "tlmgr が見つかりません。TeX Live のインストール状態を確認してください。"
    }

    Write-Host "TeX Live マネージャを更新します..."
    & tlmgr update --self | Out-Null

    Write-Host "この環境で必要な TeX Live パッケージをインストールします..."
    & tlmgr install collection-langjapanese collection-latexrecommended collection-latexextra collection-pictures collection-fontsrecommended latexmk | Out-Null
}

function Run-PythonSetup {
    Write-Host "Python 環境をセットアップします..."
    & uv python install 3.12

    $venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        & uv venv --python 3.12 --seed (Join-Path $ProjectRoot ".venv")
    }

    & uv pip sync --python $venvPython (Join-Path $ProjectRoot "python_env\requirements.lock")
}

function Run-LatexSmokeTest {
    Write-Host "LuaLaTeX の動作確認を実行します..."

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("math-study-smoke-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    $smokeTex = @'
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
'@

    $texPath = Join-Path $tmpDir "smoke.tex"
    Set-Content -LiteralPath $texPath -Value $smokeTex -Encoding UTF8

    Push-Location $tmpDir
    try {
        & lualatex -interaction=nonstopmode -halt-on-error smoke.tex | Out-Null
    } finally {
        Pop-Location
        Remove-Item -LiteralPath $tmpDir -Recurse -Force
    }
}

Write-Host "=== Windows 数学学習環境セットアップ ==="
Write-Host "プロジェクトルート: $ProjectRoot"
Write-Host ""

Ensure-Uv
Ensure-TeXLive
Install-TeXLivePackages
Run-PythonSetup
Run-LatexSmokeTest

$texBin = Find-TeXLiveBin
if ($texBin) {
    Add-ToPathIfExists $texBin
}

Write-Host ""
Write-Host "セットアップが完了しました。"
Write-Host ""
Write-Host "次に行うこと:"
Write-Host "  1. 新しい PowerShell を開いて PATH の変更を反映してください。"
Write-Host "  2. 仮想環境を手動で確認したい場合は、次を実行してください:"
Write-Host "     .\.venv\Scripts\Activate.ps1"
Write-Host "  3. Python 側の確認は、次で行えます:"
Write-Host '     uv run python -c "import matplotlib_fontja, numpy, scipy, pandas"'
Write-Host "  4. Python で図や補助スクリプトを実行するときは、引き続き uv を使ってください。"
