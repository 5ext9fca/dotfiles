[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$WslDistribution = "archlinux"
$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

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

if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw "WinGet is required to install Windows Terminal. Install Microsoft App Installer first."
}

if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    Invoke-Step -Description "Install Windows Terminal with WinGet" -Action {
        & winget.exe install --id Microsoft.WindowsTerminal --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "WinGet failed to install Windows Terminal."
        }
    }
}

$WindowsApply = Join-Path $RepoRoot "apply\windows.ps1"
if ($DryRun) {
    & $WindowsApply -DryRun
} else {
    & $WindowsApply
}

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

$WslUncPrefix = "\\wsl.localhost\$WslDistribution\"
if ($RepoRoot.StartsWith($WslUncPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    $WslRepoRoot = "/" + $RepoRoot.Substring($WslUncPrefix.Length).Replace("\", "/")
} else {
    $WslRepoRoot = (& wsl.exe -d $WslDistribution -- wslpath -a $RepoRoot).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $WslRepoRoot) {
        throw "Could not translate the repository path for WSL distribution '$WslDistribution'."
    }
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
