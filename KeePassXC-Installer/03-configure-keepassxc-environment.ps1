#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user environment for KeePassXC and verify CLI
#
# This script:
#   1. Verifies the KeePassXC installation at $HOME\.local\keepassxc.
#   2. Backs up the current persistent user PATH to
#      $HOME\.local\keepassxc\environment-backups/path-backup-<timestamp>.txt.
#   3. Prepends $HOME\.local\keepassxc to the user PATH (deduplicating entries).
#   4. Refreshes the current PowerShell process environment.
#   5. Verifies keepassxc-cli execution and basic functionality.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$InstallRoot = Join-Path $HOME '.local\keepassxc'
$CliExe = Join-Path $InstallRoot 'keepassxc-cli.exe'
$GuiExe = Join-Path $InstallRoot 'KeePassXC.exe'
$BackupDir = Join-Path $InstallRoot 'environment-backups'

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-NormalizedPathEntry {
    param([Parameter(Mandatory)][string]$Path)

    $Expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if ([string]::IsNullOrWhiteSpace($Expanded)) { return $null }
    try {
        return [IO.Path]::GetFullPath($Expanded).TrimEnd('\')
    }
    catch {
        return $Expanded.TrimEnd('\')
    }
}

function Get-UniquePathEntries {
    param([AllowNull()][string]$PathValue)

    $Results = [Collections.Generic.List[string]]::new()
    $Seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return @()
    }

    foreach ($Entry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($Entry)) { continue }
        $Trimmed = $Entry.Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($Trimmed)) { continue }

        $Normalized = Get-NormalizedPathEntry -Path $Trimmed
        if ($Normalized -and $Seen.Add($Normalized)) {
            $Results.Add($Trimmed)
        }
    }

    return $Results.ToArray()
}

# -----------------------------------------------------------------------------
# Verify installation
# -----------------------------------------------------------------------------

Write-Step 'Checking KeePassXC installation'

if (-not (Test-Path -LiteralPath $CliExe -PathType Leaf)) {
    throw "KeePassXC CLI executable not found at: $CliExe. Run 02-install-keepassxc.ps1 first."
}

if (-not (Test-Path -LiteralPath $GuiExe -PathType Leaf)) {
    throw "KeePassXC GUI executable not found at: $GuiExe. Run 02-install-keepassxc.ps1 first."
}

Write-Host "KeePassXC CLI: $CliExe"
Write-Host "KeePassXC GUI: $GuiExe"

# -----------------------------------------------------------------------------
# Backup existing user PATH
# -----------------------------------------------------------------------------

Write-Step 'Backing up persistent user PATH'

if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$CurrentRawUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $CurrentRawUserPath) { $CurrentRawUserPath = '' }

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupFile = Join-Path $BackupDir "path-backup-$Timestamp.txt"
Set-Content -LiteralPath $BackupFile -Value $CurrentRawUserPath -Encoding utf8NoBOM

Write-Host "User PATH backup saved to: $BackupFile"

# -----------------------------------------------------------------------------
# Update persistent user PATH
# -----------------------------------------------------------------------------

Write-Step 'Updating persistent user PATH'

$ExistingEntries = Get-UniquePathEntries -PathValue $CurrentRawUserPath
$FilteredEntries = [Collections.Generic.List[string]]::new()
$TargetBin = Get-NormalizedPathEntry -Path $InstallRoot

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($InstallRoot) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')

[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

# Refresh process environment
$env:PATH = "$InstallRoot;$env:PATH"

# -----------------------------------------------------------------------------
# Test KeePassXC CLI execution & functionality
# -----------------------------------------------------------------------------

Write-Step 'Testing KeePassXC CLI from refreshed PATH'

$VersionOutput = & keepassxc-cli --version
if ($LASTEXITCODE -ne 0) {
    throw "keepassxc-cli --version failed with exit code $LASTEXITCODE"
}
Write-Host "KeePassXC CLI Version: $VersionOutput" -ForegroundColor Green

Write-Host "Testing password generation command: keepassxc-cli generate -L 24 -l -U -n"
$SamplePw = & keepassxc-cli generate -L 24 -l -U -n
if ($LASTEXITCODE -eq 0 -and $SamplePw) {
    Write-Host "Generated test secret: [REDACTED $(($SamplePw.Trim()).Length) chars]" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: KeePassXC Environment Configured' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Install Root: $InstallRoot"
Write-Host "CLI binary:   keepassxc-cli.exe"
Write-Host "GUI binary:   KeePassXC.exe"
Write-Host "User PATH:    Prepended $InstallRoot"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
