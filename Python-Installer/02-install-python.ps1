#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install Python embeddable package and bootstrap pip
#
# Parameters:
#   -Force: Remove any existing Python installation at $HOME\.local\python and reinstall.
#
# This script:
#   1. Locates the downloaded Python archive and get-pip.py script.
#   2. Re-verifies the archive SHA-256 hash against metadata.
#   3. Extracts the archive into $HOME\.local\python.
#   4. Modifies the ._pth file to enable standard site-packages support.
#   5. Bootstraps pip and setuptools via get-pip.py without administrator privileges.
#   6. Verifies python.exe and pip.exe binaries.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify persistent PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Python'
$InstallParent = Join-Path $HOME '.local'
$InstallRoot = Join-Path $InstallParent 'python'
$ScriptsDir = Join-Path $InstallRoot 'Scripts'

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

# -----------------------------------------------------------------------------
# Locate and verify downloaded archive
# -----------------------------------------------------------------------------

Write-Step 'Locating downloaded Python archive'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    throw "Python download directory does not exist: $DownloadDir. Run 01-download-python.ps1 first."
}

$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-python.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName
$GetPipPath = Join-Path $DownloadDir 'get-pip.py'

if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive file missing: $ArchivePath. Run 01-download-python.ps1 first."
}

if (-not (Test-Path -LiteralPath $GetPipPath -PathType Leaf)) {
    throw "get-pip.py script missing: $GetPipPath. Run 01-download-python.ps1 first."
}

Write-Host "Archive found: $ArchivePath"
Write-Host "Version:       $($Metadata.Version)"

# Re-verify SHA-256
Write-Step 'Re-verifying archive SHA-256 hash'

$ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$ExpectedHash = $Metadata.Sha256.ToLowerInvariant()

if ($ActualHash -ne $ExpectedHash) {
    throw "Archive SHA-256 verification failed! Expected $ExpectedHash, got $ActualHash"
}

Write-Host "SHA-256 verification passed: $ActualHash" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Validate destination directory
# -----------------------------------------------------------------------------

Write-Step 'Checking target installation directory'

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing Python installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "Python is already installed at $InstallRoot. Use -Force to remove and reinstall."
    }
}

if (-not (Test-Path -LiteralPath $InstallParent -PathType Container)) {
    New-Item -ItemType Directory -Path $InstallParent -Force | Out-Null
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

# -----------------------------------------------------------------------------
# Extract archive
# -----------------------------------------------------------------------------

Write-Step 'Extracting Python embed distribution'

Write-Host "Extracting to: $InstallRoot"
Expand-Archive -LiteralPath $ArchivePath -DestinationPath $InstallRoot -Force

# -----------------------------------------------------------------------------
# Enable site-packages in ._pth file
# -----------------------------------------------------------------------------

Write-Step 'Enabling site-packages in Python path configuration'

$PthFiles = Get-ChildItem -LiteralPath $InstallRoot -Filter '*._pth'
if (-not $PthFiles or $PthFiles.Count -eq 0) {
    throw "Could not locate ._pth configuration file in: $InstallRoot"
}

$PthFile = $PthFiles[0].FullName
Write-Host "Configuring: $PthFile"

$PthLines = Get-Content -LiteralPath $PthFile
$ModifiedLines = foreach ($Line in $PthLines) {
    if ($Line -match '^\s*#\s*import\s+site\s*$') {
        'import site'
    }
    else {
        $Line
    }
}

# If 'import site' was not already in the file, append it
if ($ModifiedLines -notcontains 'import site') {
    $ModifiedLines += 'import site'
}

Set-Content -LiteralPath $PthFile -Value $ModifiedLines -Encoding utf8NoBOM
Write-Host 'site-packages enabled successfully.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Bootstrap pip
# -----------------------------------------------------------------------------

Write-Step 'Bootstrapping pip via get-pip.py'

$PythonExe = Join-Path $InstallRoot 'python.exe'

if (-not (Test-Path -LiteralPath $PythonExe -PathType Leaf)) {
    throw "Python binary not found: $PythonExe"
}

Write-Host "Running get-pip.py..."
& $PythonExe $GetPipPath --no-warn-script-location

if ($LASTEXITCODE -ne 0) {
    throw "get-pip.py execution failed with exit code $LASTEXITCODE"
}

Write-Host 'pip bootstrapped successfully.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify installed binaries
# -----------------------------------------------------------------------------

Write-Step 'Verifying installed binaries'

$PipExe = Join-Path $ScriptsDir 'pip.exe'

if (-not (Test-Path -LiteralPath $PythonExe -PathType Leaf)) {
    throw "Missing binary: $PythonExe"
}

if (-not (Test-Path -LiteralPath $PipExe -PathType Leaf)) {
    throw "Missing binary: $PipExe"
}

Write-Host "Found python.exe: $PythonExe"
Write-Host "Found pip.exe:    $PipExe"

$PyVer = & $PythonExe --version
$PipVer = & $PipExe --version

Write-Host "Python: $PyVer" -ForegroundColor Green
Write-Host "Pip:    $PipVer" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: Python Standalone & Pip Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation path: $InstallRoot"
Write-Host "Scripts path:      $ScriptsDir"
Write-Host "Python Version:    $PyVer"
Write-Host "Pip Version:       $PipVer"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
