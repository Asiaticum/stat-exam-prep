[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Subfolder,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$DestDir
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
& (Join-Path $ProjectRoot ".agents\skills\stats-workbook-builder\scripts\extract_figures.ps1") $Subfolder $DestDir
