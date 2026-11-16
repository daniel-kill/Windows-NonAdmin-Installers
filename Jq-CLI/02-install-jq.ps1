#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install jq under $HOME\.local\jq
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\jq'
$InstallRoot = Join-Path $HOME '.local\jq'
$BinDir = Join-Path $InstallRoot 'bin'
$JqExe = Join-Path $BinDir 'jq.exe'

Write-Step 'Locating downloaded jq binary'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-jq.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$DownloadedFile = Join-Path $DownloadDir $Metadata.FileName
if (-not (Test-Path -LiteralPath $DownloadedFile -PathType Leaf)) {
    throw "Downloaded binary missing: $DownloadedFile. Run 01-download-jq.ps1 first."
}

Write-Host "Binary found: $DownloadedFile"

Write-Step 'Re-verifying binary SHA-256 hash'
$ActualHash = (Get-FileHash -LiteralPath $DownloadedFile -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualHash -ne $Metadata.Sha256.ToLowerInvariant()) {
    throw "Binary SHA-256 mismatch! Expected $($Metadata.Sha256), got $ActualHash"
}
Write-Host "SHA-256 verification passed: $ActualHash" -ForegroundColor Green

Write-Step 'Checking target installation directory'
if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "jq is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

Write-Step 'Installing jq binary'
Copy-Item -LiteralPath $DownloadedFile -Destination $JqExe -Force

if (-not (Test-Path -LiteralPath $JqExe -PathType Leaf)) {
    throw "Failed to install jq.exe to: $JqExe"
}

$VersionOutput = & $JqExe --version
Write-Host "Execution Test: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: jq Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Binary:  $JqExe"
Write-Host "Version: $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
