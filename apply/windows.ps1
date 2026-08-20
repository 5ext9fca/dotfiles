[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$Source = Join-Path $RepoRoot "windows-terminal\settings.json"
$Target = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = if ($env:DOTFILES_BACKUP_DIR) {
    $env:DOTFILES_BACKUP_DIR
} else {
    Join-Path $HOME ".dotfiles-backups\$Timestamp"
}
$BackupTarget = Join-Path $BackupRoot "windows-terminal\settings.json"

function Invoke-Step {
    param(
        [Parameter(Mandatory)] [scriptblock]$Action,
        [Parameter(Mandatory)] [string]$Description
    )

    if ($DryRun) {
        Write-Host "DRY RUN: $Description"
    } else {
        & $Action
    }
}

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "Missing Windows Terminal configuration: $Source"
}

$Existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
if ($null -ne $Existing -and -not $Existing.PSIsContainer) {
    $SourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $TargetHash = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
    if ($SourceHash -eq $TargetHash) {
        Write-Host "${Target}: already applied"
        Write-Host "Windows configuration applied successfully."
        return
    }
}

if ($null -ne $Existing) {
    Invoke-Step -Description "Back up $Target to $BackupTarget" -Action {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BackupTarget) | Out-Null
        Move-Item -LiteralPath $Target -Destination $BackupTarget
    }
}

Invoke-Step -Description "Copy $Source to $Target" -Action {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target
}

Write-Host "Windows configuration applied successfully."
