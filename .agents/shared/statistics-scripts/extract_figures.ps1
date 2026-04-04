[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Subfolder,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$DestDir
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$PythonEnv = Join-Path $ProjectRoot "python_env"
$ImageDir = Join-Path (Join-Path $ProjectRoot "images") $Subfolder
$OutDir = Join-Path (Join-Path $ProjectRoot $DestDir) "figures"
$VenvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path -LiteralPath $ImageDir -PathType Container)) {
    Write-Error "Directory does not exist: $ImageDir"
}

if (-not (Test-Path -LiteralPath $VenvPython -PathType Leaf)) {
    Write-Host "First run: setting up Python environment..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File (Join-Path $ProjectRoot "scripts\setup_windows.ps1")
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

Push-Location $ProjectRoot
try {
    & uv run (Join-Path $PythonEnv "extract_figures.py") $ImageDir -o $OutDir --json
} finally {
    Pop-Location
}
