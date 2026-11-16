#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user environment for Node.js and npm
#
# This script:
#   1. Verifies the Node.js installation at $HOME\.local\node.
#   2. Configures a user-local npm global prefix at $HOME\.npm-global.
#   3. Backs up the current persistent user PATH to $HOME\.local\node\environment-backups/.
#   4. Prepends $HOME\.local\node and $HOME\.npm-global to the user PATH (deduplicating entries).
#   5. Refreshes the current PowerShell process environment.
#   6. Runs Node.js and npm verification tests.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$InstallRoot = Join-Path $HOME '.local\node'
$NodeExe = Join-Path $InstallRoot 'node.exe'
$NpmCmd = Join-Path $InstallRoot 'npm.cmd'

$NpmGlobalDir = Join-Path $HOME '.npm-global'
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

Write-Step 'Checking Node.js installation'

if (-not (Test-Path -LiteralPath $NodeExe -PathType Leaf)) {
    throw "Node.js executable not found at: $NodeExe. Run 02-install-node.ps1 first."
}

Write-Host "Node binary: $NodeExe"
Write-Host "NPM script:  $NpmCmd"

# Ensure user npm global directories exist
if (-not (Test-Path -LiteralPath $NpmGlobalDir -PathType Container)) {
    New-Item -ItemType Directory -Path $NpmGlobalDir -Force | Out-Null
}

# -----------------------------------------------------------------------------
# Configure User npm prefix
# -----------------------------------------------------------------------------

Write-Step 'Configuring non-admin npm global prefix'

# Use npm config set to configure user-level prefix
$NpmPrefixNormalized = $NpmGlobalDir -replace '\\', '/'
& $NpmCmd config set prefix $NpmPrefixNormalized --location=user

Write-Host "User npm global prefix configured: $NpmPrefixNormalized" -ForegroundColor Green

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

$TargetNode = Get-NormalizedPathEntry -Path $InstallRoot
$TargetNpmGlobal = Get-NormalizedPathEntry -Path $NpmGlobalDir

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetNode -and $Norm -ne $TargetNpmGlobal) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($InstallRoot, $NpmGlobalDir) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')

[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

# Refresh process environment
$env:PATH = "$InstallRoot;$NpmGlobalDir;$env:PATH"

# -----------------------------------------------------------------------------
# Verify Node and NPM execution
# -----------------------------------------------------------------------------

Write-Step 'Verifying Node.js and NPM execution'

$NodeVer = & $NodeExe --version
$NpmVer = & $NpmCmd --version

Write-Host "Node version: $NodeVer" -ForegroundColor Green
Write-Host "NPM version:  $NpmVer" -ForegroundColor Green

$EvalOutput = & $NodeExe -e 'console.log("Node non-admin test passed: " + process.arch + " on " + process.platform);'
if ($LASTEXITCODE -ne 0) {
    throw "Node evaluation test failed with exit code $LASTEXITCODE"
}
Write-Host $EvalOutput -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: Node.js Environment Configured & Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Node Root:   $InstallRoot"
Write-Host "NPM Global:  $NpmGlobalDir"
Write-Host "User PATH:   Prepended $InstallRoot and $NpmGlobalDir"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
