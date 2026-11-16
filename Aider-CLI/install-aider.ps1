#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Aider CLI Installation Orchestrator
#
# Installs Aider pair programmer CLI (aider-chat) into an isolated user
# virtualenv ($HOME\.local\aider) without administrator privileges.
# =============================================================================

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-NormalizedPathEntry {
    param([Parameter(Mandatory)][string]$Path)
    $Expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if ([string]::IsNullOrWhiteSpace($Expanded)) { return $null }
    try { return [IO.Path]::GetFullPath($Expanded).TrimEnd('\') } catch { return $Expanded.TrimEnd('\') }
}

function Get-UniquePathEntries {
    param([AllowNull()][string]$PathValue)
    $Results = [Collections.Generic.List[string]]::new()
    $Seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return @() }
    foreach ($Entry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($Entry)) { continue }
        $Trimmed = $Entry.Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($Trimmed)) { continue }
        $Normalized = Get-NormalizedPathEntry -Path $Trimmed
        if ($Normalized -and $Seen.Add($Normalized)) { $Results.Add($Trimmed) }
    }
    return $Results.ToArray()
}

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "AIDER CLI NON-ADMIN INSTALLATION" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# Step 1: Verify Python Prerequisite
# -----------------------------------------------------------------------------
Write-Step 'Checking Python prerequisites'

$LocalPythonExe = Join-Path $HOME '.local\python\python.exe'
$PythonExe = if (Test-Path -LiteralPath $LocalPythonExe) {
    Write-Host "Found local non-admin Python at: $LocalPythonExe" -ForegroundColor Green
    $LocalPythonExe
} else {
    $cmd = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command python -ErrorAction SilentlyContinue }
    if ($cmd) {
        Write-Host "Found system Python at: $($cmd.Source)" -ForegroundColor Green
        $cmd.Source
    } else {
        throw @"
Python was not found on this system.
Aider CLI requires Python 3.9+.

Please install the non-admin Python toolchain first:
  cd ..\Python-Installer
  .\install-python.ps1

Then rerun this script.
"@
    }
}

$PyVersion = & $PythonExe --version
Write-Host "Python Version: $PyVersion" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 2: Set up Virtual Environment & Install aider-chat
# -----------------------------------------------------------------------------
$InstallRoot = Join-Path $HOME '.local\aider'
$VenvDir = Join-Path $InstallRoot 'venv'
$BinDir  = Join-Path $InstallRoot 'bin'

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing Aider installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
}

if (-not (Test-Path -LiteralPath $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

Write-Step "Setting up isolated virtual environment under $VenvDir"

if (-not (Test-Path -LiteralPath $VenvDir)) {
    & $PythonExe -m venv $VenvDir
}

$VenvPip = Join-Path $VenvDir 'Scripts\pip.exe'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'
$AiderShim = Join-Path $BinDir 'aider.cmd'

if (Test-Path -LiteralPath $VenvPip) {
    Write-Step 'Installing aider-chat into virtual environment'
    $InstallArgs = @('install', 'aider-chat')
    if ($Force) { $InstallArgs += @('--force-reinstall', '--upgrade') }
    & $VenvPip @InstallArgs

    $AiderExe = Join-Path $VenvDir 'Scripts\aider.exe'
    if (Test-Path -LiteralPath $AiderExe) {
        $ShimContent = @"
@echo off
"$AiderExe" %*
"@
    }
    else {
        $ShimContent = @"
@echo off
"$VenvPython" -m aider.main %*
"@
    }
    Set-Content -LiteralPath $AiderShim -Value $ShimContent -Encoding ascii
}
else {
    Write-Step 'Fallback: Installing aider-chat via base python pip'
    $BasePip = Join-Path (Split-Path -Parent $PythonExe) 'Scripts\pip.exe'
    if (-not (Test-Path -LiteralPath $BasePip)) { $BasePip = 'pip' }
    
    $InstallArgs = @('install', 'aider-chat')
    if ($Force) { $InstallArgs += @('--force-reinstall', '--upgrade') }
    & $BasePip @InstallArgs

    $ShimContent = @"
@echo off
"$PythonExe" -m aider.main %*
"@
    Set-Content -LiteralPath $AiderShim -Value $ShimContent -Encoding ascii
}

Write-Host "Created launcher shim: $AiderShim" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 3: Configure User PATH & Verify Execution
# -----------------------------------------------------------------------------
Write-Step 'Configuring persistent User PATH and testing execution'

$BackupDir = Join-Path $InstallRoot 'environment-backups'
if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentRawUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $CurrentRawUserPath) { $CurrentRawUserPath = '' }
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupFile = Join-Path $BackupDir "path-backup-$Timestamp.txt"
Set-Content -LiteralPath $BackupFile -Value $CurrentRawUserPath -Encoding utf8NoBOM

$ExistingEntries = Get-UniquePathEntries -PathValue $CurrentRawUserPath
$FilteredEntries = [Collections.Generic.List[string]]::new()
$TargetBin = Get-NormalizedPathEntry -Path $BinDir

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($BinDir) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

$env:PATH = "$BinDir;$env:PATH"

$VersionOutput = & $AiderShim --version
Write-Host "Aider Version: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "✓ AIDER CLI INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $InstallRoot"
Write-Host "Launcher: $AiderShim"
Write-Host "Run 'aider' in a new terminal window to begin."
exit 0
