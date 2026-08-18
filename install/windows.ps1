[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$WslDistribution = "Arch"
$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = if ($env:DOTFILES_BACKUP_DIR) {
    $env:DOTFILES_BACKUP_DIR
} else {
    Join-Path $HOME ".dotfiles-backups\$Timestamp"
}

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

function Get-LinkTarget {
    param([Parameter(Mandatory)] [string]$Path)

    $Item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $Item -or $null -eq $Item.Target) {
        return $null
    }
    return [IO.Path]::GetFullPath([string]$Item.Target)
}

function Install-DotfileLink {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Target,
        [Parameter(Mandatory)] [ValidateSet("File", "Directory")] [string]$Kind
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source for ${Name}: $Source"
    }

    $ResolvedSource = [IO.Path]::GetFullPath($Source)
    $CurrentLinkTarget = Get-LinkTarget -Path $Target
    if ($CurrentLinkTarget -and $CurrentLinkTarget -eq $ResolvedSource) {
        Write-Host "${Name}: already linked"
        return
    }

    $Existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($null -ne $Existing) {
        $BackupTarget = Join-Path $BackupRoot $Name
        Invoke-Step -Description "Back up $Target to $BackupTarget" -Action {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BackupTarget) | Out-Null
            Move-Item -LiteralPath $Target -Destination $BackupTarget
        }
    }

    Invoke-Step -Description "Link $Target to $ResolvedSource" -Action {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
        try {
            if ($Kind -eq "Directory") {
                New-Item -ItemType Junction -Path $Target -Target $ResolvedSource | Out-Null
            } else {
                New-Item -ItemType SymbolicLink -Path $Target -Target $ResolvedSource | Out-Null
            }
        } catch {
            Write-Warning "Link creation failed; copying $Name instead. Re-run after future dotfile changes."
            if ($Kind -eq "Directory") {
                Copy-Item -LiteralPath $ResolvedSource -Destination $Target -Recurse
            } else {
                Copy-Item -LiteralPath $ResolvedSource -Destination $Target
            }
        }
    }
}

if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw "WinGet is required to install WezTerm. Install Microsoft App Installer first."
}

if (-not (Get-Command wezterm.exe -ErrorAction SilentlyContinue)) {
    Invoke-Step -Description "Install WezTerm with WinGet" -Action {
        & winget.exe install --id wez.wezterm --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "WinGet failed to install WezTerm."
        }
    }
}

Install-DotfileLink -Name "wezterm" `
    -Source (Join-Path $RepoRoot "wezterm\wezterm.lua") `
    -Target (Join-Path $HOME ".wezterm.lua") `
    -Kind File

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "WSL is required. Install WSL and initialize the '$WslDistribution' distribution first."
}

$Distributions = @(& wsl.exe --list --quiet) | ForEach-Object { ($_ -replace "`0", "").Trim() }
if ($WslDistribution -notin $Distributions) {
    throw "WSL distribution '$WslDistribution' was not found. Install and initialize it before running this script."
}

$WslVersionRow = @(& wsl.exe --list --verbose) |
    ForEach-Object { ($_ -replace "`0", "").Trim() } |
    Where-Object { $_ -match "^\*?\s*$([Regex]::Escape($WslDistribution))\s+.*\s+2$" } |
    Select-Object -First 1
if (-not $WslVersionRow) {
    throw "WSL distribution '$WslDistribution' must run under WSL2."
}

& wsl.exe -d $WslDistribution -- sh -lc "test -f /etc/arch-release"
if ($LASTEXITCODE -ne 0) {
    throw "WSL distribution '$WslDistribution' must be a fresh Arch Linux installation."
}

$WezTermWslDomain = "WSL:$WslDistribution"
Invoke-Step -Description "Set WEZTERM_WSL_DOMAIN to $WezTermWslDomain for the current user" -Action {
    [Environment]::SetEnvironmentVariable("WEZTERM_WSL_DOMAIN", $WezTermWslDomain, "User")
}

$WslRepoRoot = (& wsl.exe -d $WslDistribution -- wslpath -a $RepoRoot).Trim()
if ($LASTEXITCODE -ne 0 -or -not $WslRepoRoot) {
    throw "Could not translate the repository path for WSL distribution '$WslDistribution'."
}

$LinuxInstaller = "$WslRepoRoot/install/linux.sh"
$WslArguments = @("-d", $WslDistribution, "--", "bash", $LinuxInstaller, "--wsl-arch", "--yes")
if ($DryRun) {
    $WslArguments += "--dry-run"
}
& wsl.exe @WslArguments
if ($LASTEXITCODE -ne 0) {
    throw "WSL dependency installation and configuration failed in '$WslDistribution'."
}

Write-Host "Windows installation complete. Re-enter WSL to use Fish as its login shell."
