#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Configure persistent user environment for Go and verify builds
#
# This script:
#   1. Verifies the Go installation at $HOME\.local\go.
#   2. Backs up the current persistent user PATH to $HOME\.local\go\environment-backups/.
#   3. Sets user environment variables GOPATH ($HOME\go) and GOROOT ($HOME\.local\go).
#   4. Prepends $HOME\.local\go\bin and $HOME\go\bin to the user PATH (deduplicating entries).
#   5. Refreshes the current PowerShell process environment.
#   6. Compiles and executes a native Go test project.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the machine-wide system PATH.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$InstallRoot = Join-Path $HOME '.local\go'
$GoBin = Join-Path $InstallRoot 'bin'
$GoExe = Join-Path $GoBin 'go.exe'

$UserGoPath = Join-Path $HOME 'go'
$UserGoBin = Join-Path $UserGoPath 'bin'

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

Write-Step 'Checking Go installation'

if (-not (Test-Path -LiteralPath $GoExe -PathType Leaf)) {
    throw "Go executable not found at: $GoExe. Run 02-install-go.ps1 first."
}

Write-Host "Go binary: $GoExe"

# Ensure user GOPATH directories exist
if (-not (Test-Path -LiteralPath $UserGoBin -PathType Container)) {
    New-Item -ItemType Directory -Path $UserGoBin -Force | Out-Null
}

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
# Configure User GOPATH & GOROOT
# -----------------------------------------------------------------------------

Write-Step 'Configuring User environment variables'

[Environment]::SetEnvironmentVariable('GOROOT', $InstallRoot, 'User')
[Environment]::SetEnvironmentVariable('GOPATH', $UserGoPath, 'User')

$env:GOROOT = $InstallRoot
$env:GOPATH = $UserGoPath

Write-Host "GOROOT set to: $InstallRoot"
Write-Host "GOPATH set to: $UserGoPath"

# -----------------------------------------------------------------------------
# Update persistent user PATH
# -----------------------------------------------------------------------------

Write-Step 'Updating persistent user PATH'

$ExistingEntries = Get-UniquePathEntries -PathValue $CurrentRawUserPath
$FilteredEntries = [Collections.Generic.List[string]]::new()

$TargetGoBin = Get-NormalizedPathEntry -Path $GoBin
$TargetUserGoBin = Get-NormalizedPathEntry -Path $UserGoBin

foreach ($Entry in $ExistingEntries) {
    $Norm = Get-NormalizedPathEntry -Path $Entry
    if ($Norm -ne $TargetGoBin -and $Norm -ne $TargetUserGoBin) {
        $FilteredEntries.Add($Entry)
    }
}

$NewEntries = @($GoBin, $UserGoBin) + $FilteredEntries.ToArray()
$NewUserPath = ($NewEntries -join ';')

[Environment]::SetEnvironmentVariable('Path', $NewUserPath, 'User')
Write-Host 'User PATH persistently updated.' -ForegroundColor Green

# Refresh process environment
$env:PATH = "$GoBin;$UserGoBin;$env:PATH"

# -----------------------------------------------------------------------------
# Test Go build and execution
# -----------------------------------------------------------------------------

Write-Step 'Testing Go build and execution'

$TestDir = Join-Path $env:TEMP ("go-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null

try {
    $MainGo = Join-Path $TestDir 'main.go'
    $SourceCode = @'
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Printf("Go non-admin test passed. Runtime: %s %s/%s\n", runtime.Version(), runtime.GOOS, runtime.GOARCH)
}
'@
    Set-Content -LiteralPath $MainGo -Value $SourceCode -Encoding utf8NoBOM

    Write-Host "Running: go run main.go"
    $RunOutput = & $GoExe run $MainGo
    if ($LASTEXITCODE -ne 0) {
        throw "go run failed with exit code $LASTEXITCODE"
    }
    Write-Host $RunOutput -ForegroundColor Green

    Write-Host "Compiling: go build -o test-go.exe main.go"
    $TestExe = Join-Path $TestDir 'test-go.exe'
    & $GoExe build -o $TestExe $MainGo
    if ($LASTEXITCODE -ne 0) {
        throw "go build failed with exit code $LASTEXITCODE"
    }

    if (-not (Test-Path -LiteralPath $TestExe -PathType Leaf)) {
        throw "Compiled executable not found: $TestExe"
    }

    $ExeOutput = & $TestExe
    if ($LASTEXITCODE -ne 0) {
        throw "Compiled executable returned exit code $LASTEXITCODE"
    }
    Write-Host $ExeOutput -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $TestDir) {
        Remove-Item -LiteralPath $TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE: Go Environment Configured & Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Go Root:    $InstallRoot"
Write-Host "Go Path:    $UserGoPath"
Write-Host "User PATH:  Prepended $GoBin and $UserGoBin"
Write-Host
Write-Host 'Restart any open terminal sessions to inherit the new user PATH.'
