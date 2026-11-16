#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Discover, download, and verify Python embeddable package and get-pip.py
#
# This script:
#   1. Queries the official Python Windows download index (https://www.python.org/downloads/windows/).
#   2. Identifies the latest stable 64-bit Windows embeddable package.
#   3. Downloads the archive and get-pip.py into $HOME\Downloads\Python.
#   4. Verifies the SHA-256 checksum from the official Python release page.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Extract or install Python.
#   - Modify PATH or environment variables.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Python'
$WindowsIndexUrl = 'https://www.python.org/downloads/windows/'
$GetPipUrl = 'https://bootstrap.pypa.io/get-pip.py'

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
# Prepare download directory
# -----------------------------------------------------------------------------

Write-Step 'Preparing download directory'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

Write-Host "Download directory: $DownloadDir"

# -----------------------------------------------------------------------------
# Query official Python release index
# -----------------------------------------------------------------------------

Write-Step 'Querying official Python Windows releases'

$Html = (Invoke-WebRequest -Uri $WindowsIndexUrl -UseBasicParsing).Content

# Match latest 3.13.x embed-amd64.zip or latest stable
$Pattern = 'href="(?<Url>https://www\.python\.org/ftp/python/(?<Ver>[0-9\.]+)/python-\k<Ver>-embed-amd64\.zip)"'
$MatchesList = [regex]::Matches($Html, $Pattern)

if ($MatchesList.Count -eq 0) {
    throw "No Windows embeddable packages found at: $WindowsIndexUrl"
}

# Filter for stable 3.13.x releases (or newest 3.x)
$Candidates = @()
foreach ($M in $MatchesList) {
    $Candidates += [pscustomobject]@{
        Url     = $M.Groups['Url'].Value
        Version = [version]($M.Groups['Ver'].Value)
        RawVer  = $M.Groups['Ver'].Value
    }
}

$Selected = $Candidates | Sort-Object Version -Descending | Select-Object -First 1

if (-not $Selected) {
    throw 'Could not select a stable Python version.'
}

$PythonVersion = $Selected.RawVer
$ArchiveUrl = $Selected.Url
$ArchiveFileName = [IO.Path]::GetFileName($ArchiveUrl)
$ArchiveDest = Join-Path $DownloadDir $ArchiveFileName
$GetPipDest = Join-Path $DownloadDir 'get-pip.py'
$MetadataFile = Join-Path $DownloadDir 'release-info.json'

Write-Host "Selected Python version: $PythonVersion"
Write-Host "Archive URL:             $ArchiveUrl"

# -----------------------------------------------------------------------------
# Query Release Page for Checksum
# -----------------------------------------------------------------------------

Write-Step 'Fetching official release page checksum'

$ReleaseSlug = "python-" + ($PythonVersion -replace '\.', '')
$ReleasePageUrl = "https://www.python.org/downloads/release/$ReleaseSlug/"

$ExpectedHash = $null
try {
    $ReleaseHtml = (Invoke-WebRequest -Uri $ReleasePageUrl -UseBasicParsing).Content
    # Match row containing archive filename and its SHA-256 (64 hex characters, possibly split by <wbr>)
    $RowRegex = '(?s)' + [regex]::Escape($ArchiveFileName) + '.*?<code class="checksum">(?<Hash>.*?)</code>'
    $RowMatch = [regex]::Match($ReleaseHtml, $RowRegex)
    if ($RowMatch.Success) {
        $RawHash = $RowMatch.Groups['Hash'].Value -replace '<[^>]+>', '' -replace '\s+', ''
        if ($RawHash -match '^[0-9a-fA-F]{64}$') {
            $ExpectedHash = $RawHash.ToLowerInvariant()
            Write-Host "Found official SHA-256: $ExpectedHash" -ForegroundColor Green
        }
    }
}
catch {
    Write-Warning "Could not fetch release page $ReleasePageUrl: $($_.Exception.Message)"
}

# -----------------------------------------------------------------------------
# Download archive and get-pip.py
# -----------------------------------------------------------------------------

Write-Step 'Downloading Python embed archive'

Write-Host "Downloading: $ArchiveUrl"
Invoke-WebRequest -Uri $ArchiveUrl -OutFile $ArchiveDest

if (-not (Test-Path -LiteralPath $ArchiveDest -PathType Leaf)) {
    throw "Download failed; archive missing: $ArchiveDest"
}

Write-Step 'Downloading get-pip.py'

Write-Host "Downloading: $GetPipUrl"
Invoke-WebRequest -Uri $GetPipUrl -OutFile $GetPipDest

if (-not (Test-Path -LiteralPath $GetPipDest -PathType Leaf)) {
    throw "Download failed; get-pip.py missing: $GetPipDest"
}

# -----------------------------------------------------------------------------
# Verify SHA-256 Checksum
# -----------------------------------------------------------------------------

Write-Step 'Verifying SHA-256 checksum'

$ActualHash = (Get-FileHash -LiteralPath $ArchiveDest -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Calculated SHA-256: $ActualHash"

if ($ExpectedHash) {
    Write-Host "Expected SHA-256:   $ExpectedHash"
    if ($ActualHash -ne $ExpectedHash) {
        Remove-Item -LiteralPath $ArchiveDest -Force -ErrorAction SilentlyContinue
        throw "SHA-256 CHECKSUM VERIFICATION FAILED! Downloaded archive deleted."
    }
    Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green
}
else {
    Write-Warning 'Official release page checksum could not be verified automatically; saving calculated hash.'
}

# Save metadata for subsequent steps
$Metadata = [pscustomobject]@{
    Version      = $PythonVersion
    FileName     = $ArchiveFileName
    Sha256       = $ActualHash
    DownloadUrl  = $ArchiveUrl
    DownloadedAt = (Get-Date -Format 'o')
}
$Metadata | ConvertTo-Json | Set-Content -LiteralPath $MetadataFile -Encoding utf8NoBOM

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' STEP 1 COMPLETE: Python Download Verified' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Version:    $PythonVersion"
Write-Host "Archive:    $ArchiveDest"
Write-Host "get-pip:    $GetPipDest"
Write-Host "SHA-256:    $ActualHash" -ForegroundColor Green
Write-Host
Write-Host 'Nothing has been extracted or installed to the system.'
