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

    Write-Host "uv was not found. Installing..."
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    Add-ToPathIfExists (Join-Path $HOME ".local\bin")

    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        throw "uv installation failed. Please restart PowerShell and try again."
    }
}

function Ensure-TeXLive {
    $existingTeXBin = Find-TeXLiveBin
    if ($existingTeXBin) {
        Add-ToPathIfExists $existingTeXBin
    }

    if (Get-Command lualatex -ErrorAction SilentlyContinue) {
        return
    }

    Write-Host "TeX Live was not found. Installing..."

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("texlive-installer-" + [System.Guid]::NewGuid().ToString("N"))
    $keepTempDir = $false
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    $installerZipPath = Join-Path $tempDir "install-tl.zip"
    $profilePath = Join-Path $tempDir "texlive.profile"

    Invoke-WebRequest -Uri "https://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip" -OutFile $installerZipPath
    Expand-Archive -LiteralPath $installerZipPath -DestinationPath $tempDir -Force

    $installerDir = Get-ChildItem -LiteralPath $tempDir -Directory |
        Where-Object { $_.Name -like "install-tl-*" } |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if (-not $installerDir) {
        $keepTempDir = $true
        throw "Failed to unpack TeX Live installer. Check $tempDir."
    }

    $installerBatPath = Join-Path $installerDir.FullName "install-tl-windows.bat"
    if (-not (Test-Path -LiteralPath $installerBatPath)) {
        $keepTempDir = $true
        throw "install-tl-windows.bat was not found after unpacking. Check $tempDir."
    }

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
instopt_letter 0
instopt_portable 0
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
"@
    Set-Content -LiteralPath $profilePath -Value $profile -Encoding ASCII

    try {
        $previousPreferOwn = $env:TEXLIVE_PREFER_OWN
        $env:TEXLIVE_PREFER_OWN = "1"
        try {
            $installProcess = Start-Process -FilePath $installerBatPath `
                -WorkingDirectory $installerDir.FullName `
                -ArgumentList @("-no-gui", "-profile", $profilePath) `
                -Wait `
                -PassThru
        } finally {
            if ($null -eq $previousPreferOwn) {
                Remove-Item Env:TEXLIVE_PREFER_OWN -ErrorAction SilentlyContinue
            } else {
                $env:TEXLIVE_PREFER_OWN = $previousPreferOwn
            }
        }

        if ($installProcess.ExitCode -ne 0) {
            $keepTempDir = $true
            throw "TeX Live installer exited with code $($installProcess.ExitCode). See $tempDir for details."
        }

        $texBin = $null
        for ($attempt = 0; $attempt -lt 24; $attempt++) {
            $texBin = Find-TeXLiveBin
            if ($texBin) {
                break
            }

            Start-Sleep -Seconds 5
        }

        if (-not $texBin) {
            $keepTempDir = $true
            throw "TeX Live installer finished, but no bin\\windows directory was found. Check $tempDir for logs."
        }
    } finally {
        if (-not $keepTempDir) {
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Add-ToPathIfExists $texBin

    if (-not (Get-Command lualatex -ErrorAction SilentlyContinue)) {
        throw "TeX Live was installed, but lualatex is still not on PATH. Please restart PowerShell and try again."
    }
}

function Install-TeXLivePackages {
    $texBin = Find-TeXLiveBin
    if ($texBin) {
        Add-ToPathIfExists $texBin
    }

    if (-not (Get-Command tlmgr -ErrorAction SilentlyContinue)) {
        throw "tlmgr was not found. Please verify the TeX Live installation."
    }

    Write-Host "Updating TeX Live manager..."
    & tlmgr update --self | Out-Null

    Write-Host "Installing required TeX Live packages..."
    & tlmgr install collection-langjapanese collection-latexrecommended collection-latexextra collection-pictures collection-fontsrecommended latexmk | Out-Null
}

function Run-PythonSetup {
    Write-Host "Setting up the Python environment..."
    & uv python install 3.12

    $venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        & uv venv --python 3.12 --seed (Join-Path $ProjectRoot ".venv")
    }

    & uv pip sync --python $venvPython (Join-Path $ProjectRoot "setup\requirements.lock")
}

function Run-PythonSmokeTest {
    Write-Host "Running a Python smoke test..."
    $venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
    & $venvPython -c "import cv2, matplotlib_fontja, numpy, pandas, PIL, pillow_heif, scipy, torch, torchvision, transformers"
}

function Run-LatexSmokeTest {
    Write-Host "Running a LuaLaTeX smoke test..."

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
\section*{Smoke Test}
LuaLaTeX and common math packages are available.
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

Write-Host "=== Windows Math Study Environment Setup ==="
Write-Host "Project root: $ProjectRoot"
Write-Host ""

Ensure-Uv
Ensure-TeXLive
Install-TeXLivePackages
Run-PythonSetup
Run-PythonSmokeTest
Run-LatexSmokeTest

$texBin = Find-TeXLiveBin
if ($texBin) {
    Add-ToPathIfExists $texBin
}

Write-Host ""
Write-Host "Setup completed successfully."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open a new PowerShell session so PATH changes are applied."
Write-Host "  2. If you want to activate the project virtual environment, run:"
Write-Host "     .\.venv\Scripts\Activate.ps1"
Write-Host "  3. The Python smoke test has already been completed by this script."
Write-Host "  4. Run your Python scripts with uv."
