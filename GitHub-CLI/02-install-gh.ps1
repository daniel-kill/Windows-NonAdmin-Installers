#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\gh'
$InstallRoot = Join-Path $HOME '.local\gh'
$BinDir = Join-Path $InstallRoot 'bin'
$GhExe = Join-Path $BinDir 'gh.exe'

Write-Step 'Locating downloaded GitHub CLI archive'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'
if (-not (Test-Path -LiteralPath $MetadataFile -PathType Leaf)) {
    throw "Release metadata missing: $MetadataFile. Run 01-download-gh.ps1 first."
}

$Metadata = Get-Content -LiteralPath $MetadataFile -Raw | ConvertFrom-Json
$ArchivePath = Join-Path $DownloadDir $Metadata.FileName
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Archive missing: $ArchivePath. Run 01-download-gh.ps1 first."
}

Write-Host "Archive found: $ArchivePath"

Write-Step 'Re-verifying archive SHA-256 hash'
$ActualHash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualHash -ne $Metadata.Sha256.ToLowerInvariant()) {
    throw "Archive SHA-256 mismatch! Expected $($Metadata.Sha256), got $ActualHash"
}
Write-Host "SHA-256 verification passed: $ActualHash" -ForegroundColor Green

Write-Step 'Checking target installation directory'
if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation at: $InstallRoot"
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }
    else {
        throw "GitHub CLI is already installed at $InstallRoot. Use -Force to reinstall."
    }
}

New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

Write-Step 'Extracting GitHub CLI archive'
$TempExtract = Join-Path $env:TEMP ("gh-extract-" + [guid]::NewGuid().ToString('N'))
try {
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $TempExtract -Force
    $ExtractedGh = Get-ChildItem -LiteralPath $TempExtract -Recurse -Filter 'gh.exe' | Select-Object -First 1
    if (-not $ExtractedGh) {
        throw "Could not find gh.exe in extracted archive."
    }

    Copy-Item -LiteralPath $ExtractedGh.FullName -Destination $GhExe -Force
}
finally {
    if (Test-Path -LiteralPath $TempExtract) {
        Remove-Item -LiteralPath $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $GhExe -PathType Leaf)) {
    throw "Failed to install gh.exe to: $GhExe"
}

# Authenticode signature check
$Sig = Get-AuthenticodeSignature -LiteralPath $GhExe
Write-Host "Authenticode Status: $($Sig.Status)"
if ($Sig.SignerCertificate) {
    Write-Host "Signer Subject: $($Sig.SignerCertificate.Subject)"
}

$VersionOutput = & $GhExe --version | Select-Object -First 1
Write-Host "Execution Test: $VersionOutput" -ForegroundColor Green

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE: GitHub CLI Installed' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Binary:  $GhExe"
Write-Host "Version: $VersionOutput"
Write-Host
Write-Host 'The Windows PATH has not been modified yet. Run Step 3 to configure environment.'
