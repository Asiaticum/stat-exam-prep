[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Subdir = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

if ([string]::IsNullOrWhiteSpace($Subdir)) {
    $ImageDir = Join-Path $ProjectRoot "images"
} else {
    $ImageDir = Join-Path (Join-Path $ProjectRoot "images") $Subdir
}

if (-not (Test-Path -LiteralPath $ImageDir -PathType Container)) {
    Write-Error "Directory does not exist: $ImageDir"
}

Push-Location $ProjectRoot
try {
    & uv run .\convert_images_to_jpg.py $Subdir
} finally {
    Pop-Location
}
