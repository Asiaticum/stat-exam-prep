[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Source
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Usage:
  .\scripts\sync_skills.ps1 .claude
  .\scripts\sync_skills.ps1 .agent
  .\scripts\sync_skills.ps1 .agents

Behavior:
  - Copies <source>/skills to the other two folders' skills directories.
  - Copies <source>/shared to the other two folders' shared directories when present.
  - Normalizes text inside each synced skills/shared directory so references use that folder name:
      .claude/  .agent/  .agents/  -> <current-folder>/
"@
}

function Copy-Subtree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SrcRoot,
        [Parameter(Mandatory = $true)]
        [string]$DstRoot,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $srcPath = Join-Path $SrcRoot $Name
    if (-not (Test-Path -LiteralPath $srcPath -PathType Container)) {
        return
    }

    if (-not (Test-Path -LiteralPath $DstRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $DstRoot | Out-Null
    }

    $dstPath = Join-Path $DstRoot $Name
    if (Test-Path -LiteralPath $dstPath) {
        Remove-Item -LiteralPath $dstPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $dstPath | Out-Null
    Copy-Item -LiteralPath (Join-Path $srcPath '*') -Destination $dstPath -Recurse -Force
}

function Normalize-FolderRefs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder
    )

    foreach ($name in @('skills', 'shared')) {
        $syncDir = Join-Path $Folder $name
        if (-not (Test-Path -LiteralPath $syncDir -PathType Container)) {
            continue
        }

        Get-ChildItem -LiteralPath $syncDir -Recurse -File | ForEach-Object {
            $path = $_.FullName
            $content = [System.IO.File]::ReadAllText($path)
            $updated = [regex]::Replace($content, '\.(?:claude|agent|agents)/', "$Folder/")
            if ($updated -ne $content) {
                [System.IO.File]::WriteAllText($path, $updated)
            }
        }
    }
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$Source = $Source.TrimEnd('/', '\')
$allowed = @('.claude', '.agent', '.agents')
if ($allowed -notcontains $Source) {
    Write-Error "Source must be one of .claude, .agent, .agents.`n$(Show-Usage)"
}

$skillsDir = Join-Path $Source 'skills'
if (-not (Test-Path -LiteralPath $skillsDir -PathType Container)) {
    Write-Error "'$skillsDir' does not exist."
}

$allDirs = @('.claude', '.agent', '.agents')
foreach ($dir in $allDirs) {
    if ($dir -ne $Source) {
        Copy-Subtree -SrcRoot $Source -DstRoot $dir -Name 'skills'
        Copy-Subtree -SrcRoot $Source -DstRoot $dir -Name 'shared'
    }
}

foreach ($dir in $allDirs) {
    Normalize-FolderRefs -Folder $dir
}

Write-Host 'Done.'
Write-Host "Source: $Source/skills"
if (Test-Path -LiteralPath (Join-Path $Source 'shared') -PathType Container) {
    Write-Host "Source: $Source/shared"
}
Write-Host 'Synced: .claude/{skills,shared}, .agent/{skills,shared}, .agents/{skills,shared}'
