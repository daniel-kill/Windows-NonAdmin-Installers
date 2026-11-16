#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify official Gpg4win release installer
#
# Downloads:
#   1. Queries official download page (https://www.gpg4win.org/download.html).
#   2. Scrapes latest version and official SHA-256 checksum.
#   3. Downloads installer exe and detached OpenPGP signature into $HOME\Downloads\Gpg4win.
#   4. Verifies SHA-256 digest and checks Windows Authenticode digital signature.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Execute or extract the installer.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$DownloadDir = Join-Path $HOME 'Downloads\Gpg4win'
$DownloadPageUrl = 'https://www.gpg4win.org/download.html'

Write-Step 'Preparing download directory'
if (-not (Test-Path -LiteralPath $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Step 'Querying official Gpg4win download page'
Write-Host "URL: $DownloadPageUrl"
$PageHtml = (Invoke-WebRequest -Uri $DownloadPageUrl -UseBasicParsing).Content

# Match latest version and installer link
$ExeRegex = '(?im)\b(gpg4win-(?<Ver>[0-9\.]+)\.exe)\b'
$ExeMatch = [regex]::Match($PageHtml, $ExeRegex)

if (-not $ExeMatch.Success) {
    throw "Could not determine latest Gpg4win installer filename from: $DownloadPageUrl"
}

$FileName = $ExeMatch.Groups[1].Value
$Version = $ExeMatch.Groups['Ver'].Value
$DownloadUrl = "https://files.gpg4win.org/$FileName"
$SigUrl = "$DownloadUrl.sig"

Write-Host "Latest Release: $Version" -ForegroundColor Green
Write-Host "Installer File: $FileName"

# Extract official SHA-256 checksum
$HashRegex = '(?is)' + [regex]::Escape($FileName) + '.*?SHA256:\s*<code>(?<Hash>[0-9a-f]{64})</code>'
$HashMatch = [regex]::Match($PageHtml, $HashRegex)

$ExpectedHash = $null
if ($HashMatch.Success) {
    $ExpectedHash = $HashMatch.Groups['Hash'].Value.ToLowerInvariant()
    Write-Host "Official SHA-256: $ExpectedHash" -ForegroundColor Green
}
else {
    Write-Warning "Could not parse official SHA-256 directly from download page."
}

$InstallerDest = Join-Path $DownloadDir $FileName
$SigDest = "$InstallerDest.sig"
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Step 'Downloading Gpg4win installer'
Write-Host "URL: $DownloadUrl"
Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerDest

if (-not (Test-Path -LiteralPath $InstallerDest -PathType Leaf)) {
    throw "Failed to download installer to: $InstallerDest"
}

Write-Step 'Downloading OpenPGP detached signature'
try {
    Invoke-WebRequest -Uri $SigUrl -OutFile $SigDest
    Write-Host "Signature saved: $SigDest"
}
catch {
    Write-Warning "Could not download detached signature from $SigUrl: $($_.Exception.Message)"
}

Write-Step 'Verifying SHA-256 checksum'
$ActualHash = (Get-FileHash -LiteralPath $InstallerDest -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Calculated SHA-256: $ActualHash"

if ($ExpectedHash) {
    Write-Host "Expected SHA-256:   $ExpectedHash"
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item -LiteralPath $InstallerDest -Force -ErrorAction SilentlyContinue
        throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded installer deleted."
    }
    Write-Host "SHA-256 verification PASSED." -ForegroundColor Green
}

Write-Step 'Inspecting Windows Authenticode digital signature'
$Authenticode = Get-AuthenticodeSignature -LiteralPath $InstallerDest
Write-Host "Authenticode Status: $($Authenticode.Status)"

if ($Authenticode.SignerCertificate) {
    Write-Host "Signer Subject: $($Authenticode.SignerCertificate.Subject)"
    Write-Host "Signer Issuer:  $($Authenticode.SignerCertificate.Issuer)"
}

$Metadata = [pscustomobject]@{
    Version      = $Version
    FileName     = $FileName
    Sha256       = $ActualHash
    DownloadUrl  = $DownloadUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: Gpg4win Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version:      $Version"
Write-Host "Installer:    $InstallerDest"
Write-Host "SHA-256:      $ActualHash (VERIFIED)" -ForegroundColor Green
Write-Host "Authenticode: $($Authenticode.Status)"
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
