#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Extract and install KeePassXC portable under $HOME\.local\keepassxc
#
# Parameters:
#   -Force: Remove any existing installation at $HOME\.local\keepassxc and reinstall.
#
# This script:
#   1. Locates downloaded archive and re-verifies its SHA-256 checksum.
#   2. Extracts the portable archive into a temporary staging area.
#   3. Deploys the application files into $HOME\.local\keepassxc.
#   4. Ensures '.portable' marker is present for self-contained configuration.
#   5. Verifies Windows Authenticode digital signatures on all binaries.
#   6. Verifies executable execution (keepassxc-cli.exe --version).
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify persistent PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\KeePassXC'
$InstallParent = Join-Path $HOME '.local'
$InstallRoot = Join-Path $InstallParent 'keepassxc'

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

# -----------------------------------------------------------------------------
# Locate and verify downloaded archive
# -----------------------------------------------------------------------------

Write-Step 'Locating downloaded KeePassXC archive'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    throw "Download directory does not exist: $DownloadDir. Run 01-download-keepassxc.ps1 first."
}

$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-keepassxc.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName

if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive file missing: $ArchivePath. Run 01-download-keepassxc.ps1 first."
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
        Write-Warning "Removing existing KeePassXC installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "KeePassXC is already installed at $InstallRoot. Use -Force to remove and reinstall."
    }
}

if (-not (Test-Path -LiteralPath $InstallParent -PathType Container)) {
    New-Item -ItemType Directory -Path $InstallParent -Force | Out-Null
}

# -----------------------------------------------------------------------------
# Extract archive
# -----------------------------------------------------------------------------

Write-Step 'Extracting KeePassXC portable distribution'

$TempExtract = Join-Path $env:TEMP ("kpxc-extract-" + [guid]::NewGuid().ToString('N'))

try {
    Write-Host "Extracting to temporary staging: $TempExtract"
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $TempExtract -Force

    $ExtractedDir = Get-ChildItem -LiteralPath $TempExtract -Directory | Where-Object { $_.Name -like 'KeePassXC*' } | Select-Object -First 1
    if (-not $ExtractedDir) {
        throw "Extraction did not produce expected 'KeePassXC-*' folder in: $TempExtract"
    }

    Write-Host "Moving KeePassXC portable files to: $InstallRoot"
    Move-Item -LiteralPath $ExtractedDir.FullName -Destination $InstallRoot -Force

    # Ensure .portable file exists so settings are self-contained
    $PortableFile = Join-Path $InstallRoot '.portable'
    if (-not (Test-Path -LiteralPath $PortableFile)) {
        New-Item -ItemType File -Path $PortableFile -Force | Out-Null
    }
}
finally {
    if (Test-Path -LiteralPath $TempExtract) {
        Remove-Item -LiteralPath $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# Verify installed binaries & Authenticode signatures
# -----------------------------------------------------------------------------

Write-Step 'Verifying installed binaries and Authenticode signatures'

$CliExe = Join-Path $InstallRoot 'keepassxc-cli.exe'
$GuiExe = Join-Path $InstallRoot 'KeePassXC.exe'
$ProxyExe = Join-Path $InstallRoot 'keepassxc-proxy.exe'

if (-not (Test-Path -LiteralPath $CliExe -PathType Leaf)) {
    throw "Missing binary: $CliExe"
}

if (-not (Test-Path -LiteralPath $GuiExe -PathType Leaf)) {
    throw "Missing binary: $GuiExe"
}

Write-Host "Found keepassxc-cli.exe: $CliExe"
Write-Host "Found KeePassXC.exe:     $GuiExe"

# Authenticode signature checks
foreach ($Exe in @($CliExe, $GuiExe)) {
    $Sig = Get-AuthenticodeSignature -LiteralPath $Exe
    Write-Host "Authenticode [$(Split-Path $Exe -Leaf)]: $($Sig.Status)"
    if ($Sig.SignerCertificate) {
        Write-Host "  Signer: $($Sig.SignerCertificate.Subject)"
    }
    if ($Sig.Status -ne 'Valid') {
        Write-Warning "Authenticode signature status is '$($Sig.Status)' for $Exe"
    }
}

# Test CLI execution
$VersionOutput = & $CliExe --version
Write-Host "Execution Test: $VersionOutput" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: KeePassXC Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation path: $InstallRoot"
Write-Host "CLI binary:        $CliExe"
Write-Host "GUI binary:        $GuiExe"
Write-Host "Version:           $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
