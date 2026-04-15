[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$RelativePath = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$ImagesRoot = Join-Path $ProjectRoot "images"

if ([string]::IsNullOrWhiteSpace($RelativePath)) {
    $ImageDir = $ImagesRoot
} else {
    $ImageDir = Join-Path $ImagesRoot $RelativePath
}

if (-not (Test-Path -LiteralPath $ImageDir -PathType Container)) {
    Write-Error "Directory does not exist: $ImageDir"
}

Push-Location $ProjectRoot
try {
    & uv run .\scripts\convert_images_to_jpg.py $RelativePath
} finally {
    Pop-Location
}
