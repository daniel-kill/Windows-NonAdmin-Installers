#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user environment for Python and pip
#
# This script:
#   1. Verifies the Python and pip installations under $HOME\.local\python.
#   2. Backs up the current persistent user PATH to $HOME\.local\python\environment-backups/.
#   3. Prepends $HOME\.local\python and $HOME\.local\python\Scripts to the user PATH (deduplicating entries).
#   4. Refreshes the current PowerShell process environment.
#   5. Runs Python and pip verification tests.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$InstallRoot = Join-Path $HOME '.local\python'
$ScriptsDir = Join-Path $InstallRoot 'Scripts'
$PythonExe = Join-Path $InstallRoot 'python.exe'
$PipExe = Join-Path $ScriptsDir 'pip.exe'

$BackupDir = Join-Path $InstallRoot 'environment-backups'

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

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

Write-Step 'Checking Python installation'

if (-not (Test-Path -LiteralPath $PythonExe -PathType Leaf)) {
    throw "Python executable not found at: $PythonExe. Run 02-install-python.ps1 first."
}

if (-not (Test-Path -LiteralPath $PipExe -PathType Leaf)) {
    throw "Pip executable not found at: $PipExe. Run 02-install-python.ps1 first."
}

Write-Host "Python binary: $PythonExe"
Write-Host "Pip binary:    $PipExe"

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

$TargetPython = Get-NormalizedPathEntry -Path $InstallRoot
$TargetScripts = Get-NormalizedPathEntry -Path $ScriptsDir

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetPython -and $Norm -ne $TargetScripts) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($InstallRoot, $ScriptsDir) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')

[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

# Refresh process environment
$env:PATH = "$InstallRoot;$ScriptsDir;$env:PATH"

# -----------------------------------------------------------------------------
# Verify Python and Pip execution
# -----------------------------------------------------------------------------

Write-Step 'Verifying Python and Pip execution'

$PyVer = & $PythonExe --version
$PipVer = & $PipExe --version

Write-Host "Python: $PyVer" -ForegroundColor Green
Write-Host "Pip:    $PipVer" -ForegroundColor Green

$EvalOutput = & $PythonExe -c 'import sys, math; print(f"Python non-admin test passed: {sys.version.split()[0]} on {sys.platform} (pi={math.pi:.4f})")'
if ($LASTEXITCODE -ne 0) {
    throw "Python evaluation test failed with exit code $LASTEXITCODE"
}
Write-Host $EvalOutput -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: Python Environment Configured & Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Python Root:  $InstallRoot"
Write-Host "Scripts Root: $ScriptsDir"
Write-Host "User PATH:    Prepended $InstallRoot and $ScriptsDir"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
