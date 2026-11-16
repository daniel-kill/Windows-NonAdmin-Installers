#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 1: Download and verify the latest stable MSYS2 x86-64 SFX archive
#
# This script:
#   1. Finds the newest versioned MSYS2 SFX archive.
#   2. Downloads the archive.
#   3. Downloads its OpenPGP signature.
#   4. Verifies the signature if the signing key is already available to GPG.
#
# This script does not extract or install MSYS2.
# 
# Note: MSYS2 repository does not provide SHA-256 checksum files, only OpenPGP
# signatures. Signature verification will be performed if GPG is available.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\MSYS2'

$DistributionUrl = 'https://repo.msys2.org/distrib/x86_64/'

$ExpectedPrimaryFingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-VerifiedDownload {
    param(
        [Parameter(Mandatory)]
        [uri]$Uri,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    Write-Host "URL:  $Uri"
    Write-Host "File: $Destination"

    Invoke-WebRequest `
        -Uri $Uri `
        -OutFile $Destination

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "The download did not create the expected file: $Destination"
    }

    $DownloadedFile = Get-Item -LiteralPath $Destination

    if ($DownloadedFile.Length -le 0) {
        throw "The downloaded file is empty: $Destination"
    }

    Write-Host "Size: $($DownloadedFile.Length) bytes"
}

# -----------------------------------------------------------------------------
# Prepare download directory
# -----------------------------------------------------------------------------

Write-Step 'Creating the download directory'

New-Item `
    -ItemType Directory `
    -Path $DownloadDir `
    -Force |
    Out-Null

Write-Host "Download directory: $DownloadDir"

# -----------------------------------------------------------------------------
# Read the official distribution index
# -----------------------------------------------------------------------------

Write-Step 'Reading the official MSYS2 distribution index'

$IndexResponse = Invoke-WebRequest -Uri $DistributionUrl

if ([string]::IsNullOrWhiteSpace($IndexResponse.Content)) {
    throw "The MSYS2 distribution index returned no content: $DistributionUrl"
}

# Only accept stable, versioned filenames such as:
#
# msys2-base-x86_64-20261028.sfx.exe
#
# This intentionally excludes unversioned aliases and unrelated files.

$FilePattern = 'msys2-base-x86_64-(?<Date>\d{8})\.sfx\.exe'

$CandidateNames = [regex]::Matches(
    $IndexResponse.Content,
    $FilePattern,
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
) |
    ForEach-Object {
        $_.Value
    } |
    Sort-Object -Unique

if (-not $CandidateNames) {
    throw @"
No versioned MSYS2 SFX archives were found at:

$DistributionUrl

Expected a filename matching:

msys2-base-x86_64-YYYYMMDD.sfx.exe
"@
}

# -----------------------------------------------------------------------------
# Validate dates and select the newest archive
# -----------------------------------------------------------------------------

Write-Step 'Selecting the newest versioned archive'

$Candidates = foreach ($CandidateName in $CandidateNames) {
    if ($CandidateName -notmatch $FilePattern) {
        continue
    }

    $ReleaseDate = [datetime]::MinValue

    $DateWasParsed = [datetime]::TryParseExact(
        $Matches.Date,
        'yyyyMMdd',
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref]$ReleaseDate
    )

    if ($DateWasParsed) {
        [pscustomobject]@{
            FileName   = $CandidateName
            ReleaseDate = $ReleaseDate
        }
    }
}

$Selected = $Candidates |
    Sort-Object ReleaseDate -Descending |
    Select-Object -First 1

if (-not $Selected) {
    throw 'Archive names were found, but none contained a valid release date.'
}

$FileName = $Selected.FileName

Write-Host "Selected archive: $FileName"
Write-Host "Release date:     $($Selected.ReleaseDate.ToString('yyyy-MM-dd'))"

# -----------------------------------------------------------------------------
# Construct download locations
# Note: MSYS2 provides .sig files but not individual .sha256 files
# Only construct the signature URL; checksum verification will be skipped
# -----------------------------------------------------------------------------

$DownloadUrl = [uri]::new(
    [uri]$DistributionUrl,
    $FileName
)

$SigUrl    = [uri]("$($DownloadUrl.AbsoluteUri).sig")

$InstallerPath = Join-Path $DownloadDir $FileName
$SigPath       = "$InstallerPath.sig"

# -----------------------------------------------------------------------------
# Download the archive
# -----------------------------------------------------------------------------

Write-Step 'Downloading the MSYS2 self-extracting archive'

Invoke-VerifiedDownload `
    -Uri $DownloadUrl `
    -Destination $InstallerPath

# Download its detached signature
# (Note: SHA-256 checksums are not provided by MSYS2 repository; 
#  verification relies on OpenPGP signatures instead)
# -----------------------------------------------------------------------------
# Download its detached signature
# -----------------------------------------------------------------------------

Write-Step 'Downloading the OpenPGP signature'

try {
    Invoke-VerifiedDownload `
        -Uri $SigUrl `
        -Destination $SigPath

    $SignatureAvailable = $true
}
catch {
    $SignatureAvailable = $false

    Remove-Item `
        -LiteralPath $SigPath `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Warning "The OpenPGP signature could not be downloaded."
    Write-Warning "Signature URL: $SigUrl"
    Write-Warning $_.Exception.Message
}

# -----------------------------------------------------------------------------
# SHA-256 checksum verification
# Note: MSYS2 repository does not provide SHA-256 checksum files.
# Verification relies on OpenPGP signature verification instead.

# -----------------------------------------------------------------------------
# Verify the detached OpenPGP signature
# -----------------------------------------------------------------------------

$SignatureVerified = $false
$SignatureKeyMissing = $false

if ($SignatureAvailable) {
    Write-Step 'Locating GnuPG'

    $GpgCommand = Get-Command gpg.exe -ErrorAction SilentlyContinue

    if (-not $GpgCommand) {
        $GpgCommand = Get-Command gpg -ErrorAction SilentlyContinue
    }

    if (-not $GpgCommand) {
        throw @'
GnuPG was not found in PATH.

The archive has not been executed or extracted.

Add the Gpg4win bin directory to PATH, open a new PowerShell session, and
rerun this script.
'@
    }

    Write-Host "Using GPG: $($GpgCommand.Source)"

    Write-Step 'Verifying the OpenPGP signature'

    $StatusFile = Join-Path $env:TEMP (
        "msys2-gpg-status-$([guid]::NewGuid().ToString('N')).txt"
    )

    try {
        & $GpgCommand.Source `
            --batch `
            --status-file $StatusFile `
            --verify $SigPath $InstallerPath

        $GpgExitCode = $LASTEXITCODE

        if (Test-Path -LiteralPath $StatusFile) {
            $GpgStatus = @(
                Get-Content -LiteralPath $StatusFile
            )
        }
        else {
            $GpgStatus = @()
        }
    }
    finally {
        Remove-Item `
            -LiteralPath $StatusFile `
            -Force `
            -ErrorAction SilentlyContinue
    }

    $NoPublicKeyRecord = $GpgStatus |
        Where-Object {
            $_ -match '^\[GNUPG:\]\s+NO_PUBKEY\s+'
        } |
        Select-Object -First 1

    if ($NoPublicKeyRecord) {
        $SignatureKeyMissing = $true

        Write-Warning 'The MSYS2 signing key is not present in your GPG keyring.'
        Write-Warning 'OpenPGP verification is not complete.'
    }
    elseif ($GpgExitCode -ne 0) {
        throw @"
OpenPGP signature verification FAILED.

GPG exit code: $GpgExitCode

Do not execute or extract the archive.
"@
    }
    else {
        $ValidSigRecord = $GpgStatus |
            Where-Object {
                $_ -match '^\[GNUPG:\]\s+VALIDSIG\s+'
            } |
            Select-Object -First 1

        if (-not $ValidSigRecord) {
            throw @'
GPG returned a successful exit code, but it did not produce a VALIDSIG
status record. The signature will not be accepted.
'@
        }

        $ValidSigFields = (
            $ValidSigRecord -replace '^\[GNUPG:\]\s+', ''
        ) -split '\s+'

        if ($ValidSigFields.Count -lt 2) {
            throw 'The GPG VALIDSIG record was malformed.'
        }

        $SigningFingerprint = $ValidSigFields[1].ToUpperInvariant()

        # For signatures made by a signing subkey, current GnuPG VALIDSIG
        # output includes the primary-key fingerprint as its final field.

        $ReportedPrimaryFingerprint = (
            $ValidSigFields[-1]
        ).ToUpperInvariant()

        Write-Host
        Write-Host "Signing fingerprint:          $SigningFingerprint"
        Write-Host "Reported primary fingerprint: $ReportedPrimaryFingerprint"
        Write-Host "Expected primary fingerprint: $ExpectedPrimaryFingerprint"

        if (
            $ReportedPrimaryFingerprint -ne
            $ExpectedPrimaryFingerprint
        ) {
            throw @"
The signature is cryptographically valid, but its primary signing key does
not match the official MSYS2 primary-key fingerprint.

Expected:
$ExpectedPrimaryFingerprint

Reported:
$ReportedPrimaryFingerprint

Do not execute or extract the archive.
"@
        }

        $SignatureVerified = $true

        Write-Host
        Write-Host 'OpenPGP signature verification PASSED.' `
            -ForegroundColor Green
    }
}

# -----------------------------------------------------------------------------
# Final summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Cyan
Write-Host ' STEP 1 SUMMARY' -ForegroundColor Cyan
Write-Host '============================================================' `
    -ForegroundColor Cyan

Write-Host
Write-Host "Archive:"
Write-Host "  $InstallerPath"

Write-Host
Write-Host 'SHA-256: NOT AVAILABLE (MSYS2 provides only signatures)' -ForegroundColor Yellow

if ($SignatureVerified) {
    Write-Host 'OpenPGP: VERIFIED' -ForegroundColor Green
}
elseif ($SignatureKeyMissing) {
    Write-Host 'OpenPGP: PENDING - signing key is missing' `
        -ForegroundColor Yellow
}
elseif (-not $SignatureAvailable) {
    Write-Host 'OpenPGP: NOT VERIFIED - signature was unavailable' `
        -ForegroundColor Yellow
}
else {
    Write-Host 'OpenPGP: NOT VERIFIED' -ForegroundColor Yellow
}

Write-Host
Write-Host 'Nothing has been installed or extracted.'

if ($SignatureKeyMissing) {
    Write-Host
    Write-Host 'The next step is to import and independently validate the' `
        -ForegroundColor Yellow
    Write-Host 'official MSYS2 signing key, then rerun signature verification.' `
        -ForegroundColor Yellow
}