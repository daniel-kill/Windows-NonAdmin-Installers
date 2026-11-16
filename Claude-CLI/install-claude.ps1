#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# =============================================================================
# Primary Claude Code CLI Installation Orchestrator
#
# Installs Anthropic's official Claude Code CLI (@anthropic-ai/claude-code)
# into user space ($HOME\.npm-global) without administrator privileges.
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
Write-Host "CLAUDE CODE CLI NON-ADMIN INSTALLATION" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# Step 1: Verify Node.js Prerequisite
# -----------------------------------------------------------------------------
Write-Step 'Checking Node.js & NPM prerequisites'

$LocalNodeDir = Join-Path $HOME '.local\node'
$LocalNpmCmd  = Join-Path $LocalNodeDir 'npm.cmd'
$NpmCmd = $null

if (Test-Path -LiteralPath $LocalNpmCmd -PathType Leaf) {
    Write-Host "Found local non-admin Node.js at: $LocalNodeDir" -ForegroundColor Green
    $NpmCmd = $LocalNpmCmd
}
else {
    $SysNpm = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $SysNpm) {
        $SysNpm = Get-Command npm -ErrorAction SilentlyContinue
    }
    if ($SysNpm) {
        Write-Host "Found system NPM at: $($SysNpm.Source)" -ForegroundColor Green
        $NpmCmd = $SysNpm.Source
    }
}

if (-not $NpmCmd) {
    throw @"
Node.js and npm were not found on this system.
Claude Code CLI requires Node.js (v20+ recommended).

Please install the non-admin Node.js toolchain first:
  cd ..\Node-Installer
  .\install-node.ps1

Then rerun this script.
"@
}

$NpmVersion = & $NpmCmd --version
Write-Host "NPM Version: $NpmVersion" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 2: Install @anthropic-ai/claude-code via User-Global NPM
# -----------------------------------------------------------------------------
Write-Step 'Configuring User-Global NPM prefix and installing Claude Code'

$UserNpmGlobal = Join-Path $HOME '.npm-global'
if (-not (Test-Path -LiteralPath $UserNpmGlobal -PathType Container)) {
    New-Item -ItemType Directory -Path $UserNpmGlobal -Force | Out-Null
}

Write-Host "Setting user-level npm prefix to: $UserNpmGlobal"
& $NpmCmd config set prefix $UserNpmGlobal --location=user

Write-Host "Installing @anthropic-ai/claude-code globally in user space..."
$InstallArgs = @('install', '-g', '@anthropic-ai/claude-code')
if ($Force) { $InstallArgs += '--force' }

& $NpmCmd @InstallArgs
if ($LASTEXITCODE -ne 0) {
    throw "npm install @anthropic-ai/claude-code failed with exit code $LASTEXITCODE"
}

# -----------------------------------------------------------------------------
# Step 3: Configure User PATH & Verify Execution
# -----------------------------------------------------------------------------
Write-Step 'Configuring persistent User PATH and testing execution'

$BackupDir = Join-Path $UserNpmGlobal 'environment-backups'
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
$TargetBin = Get-NormalizedPathEntry -Path $UserNpmGlobal

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($UserNpmGlobal) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')
[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

$env:PATH = "$UserNpmGlobal;$env:PATH"

$ClaudeCmd = Join-Path $UserNpmGlobal 'claude.cmd'
if (-not (Test-Path -LiteralPath $ClaudeCmd -PathType Leaf)) {
    $ClaudeCmd = Join-Path $UserNpmGlobal 'claude'
}

if (Test-Path -LiteralPath $ClaudeCmd) {
    Write-Host "Found Claude launcher at: $ClaudeCmd"
    $VersionOutput = & $ClaudeCmd --version
    Write-Host "Claude Code Version: $VersionOutput" -ForegroundColor Green
}
else {
    Write-Host "Claude package installed into $UserNpmGlobal." -ForegroundColor Green
}

Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "✓ CLAUDE CODE CLI INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $UserNpmGlobal"
Write-Host "Run 'claude' in a new terminal window to begin."
exit 0
