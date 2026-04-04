[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Subdir = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
& (Join-Path $ProjectRoot ".agents\skills\stats-workbook-builder\scripts\convert_to_jpg.ps1") $Subdir
