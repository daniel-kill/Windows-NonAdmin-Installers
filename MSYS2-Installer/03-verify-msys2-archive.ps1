#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 3: Verify the downloaded MSYS2 archive
#
# This script:
#   1. Locates the newest downloaded versioned MSYS2 SFX archive.
#   2. Derives the official GitHub release tag from its filename.
#   3. Downloads the corresponding official .sha256 release asset.
#   4. Verifies the archive's SHA-256 hash.
#   5. Verifies the existing detached OpenPGP signature.
#   6. Requires the official MSYS2 primary signing-key fingerprint.
#
# This script does not extract or execute the archive.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\MSYS2'

$ExpectedPrimaryFingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'

$GitHubRepository = 'msys2/msys2-installer'

$ArchivePattern = '^msys2-base-x86_64-(?<Date>\d{8})\.sfx\.exe$'

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

function Get-GpgCommand {
    $Command = Get-Command gpg.exe -ErrorAction SilentlyContinue

    if (-not $Command) {
        $Command = Get-Command gpg -ErrorAction SilentlyContinue
    }

    if (-not $Command) {
        throw 'GnuPG was not found in PATH.'
    }

    return $Command
}

# -----------------------------------------------------------------------------
# Locate the downloaded archive
# -----------------------------------------------------------------------------

Write-Step 'Locating the downloaded MSYS2 archive'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    throw "The MSYS2 download directory does not exist: $DownloadDir"
}

$ArchiveCandidates = foreach (
    $File in Get-ChildItem `
        -LiteralPath $DownloadDir `
        -File `
        -Filter 'msys2-base-x86_64-*.sfx.exe'
) {
    if ($File.Name -notmatch $ArchivePattern) {
        continue
    }

    $ReleaseDate = [datetime]::MinValue

    $Parsed = [datetime]::TryParseExact(
        $Matches.Date,
        'yyyyMMdd',
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref]$ReleaseDate
    )

    if ($Parsed) {
        [pscustomobject]@{
            File        = $File
            DateStamp   = $Matches.Date
            ReleaseDate = $ReleaseDate
        }
    }
}

$Selected = $ArchiveCandidates |
Sort-Object ReleaseDate -Descending |
Select-Object -First 1

if (-not $Selected) {
    throw @"
No versioned MSYS2 SFX archive was found in:

$DownloadDir

Expected a filename matching:

msys2-base-x86_64-YYYYMMDD.sfx.exe
"@
}

$ArchivePath = $Selected.File.FullName
$ArchiveName = $Selected.File.Name
$SignaturePath = "$ArchivePath.sig"
$ChecksumPath = "$ArchivePath.sha256"

$ReleaseTag = $Selected.ReleaseDate.ToString('yyyy-MM-dd')

Write-Host "Archive:     $ArchivePath"
Write-Host "Release tag: $ReleaseTag"
Write-Host "Size:        $($Selected.File.Length) bytes"

# -----------------------------------------------------------------------------
# Confirm the detached signature exists
# -----------------------------------------------------------------------------

Write-Step 'Checking the detached signature'

if (-not (Test-Path -LiteralPath $SignaturePath -PathType Leaf)) {
    throw @"
The detached OpenPGP signature is missing:

$SignaturePath

Rerun Step 1 before continuing.
"@
}

$SignatureFile = Get-Item -LiteralPath $SignaturePath

if ($SignatureFile.Length -le 0) {
    throw "The detached signature file is empty: $SignaturePath"
}

Write-Host "Signature: $SignaturePath"
Write-Host "Size:      $($SignatureFile.Length) bytes"

# -----------------------------------------------------------------------------
# Download the official SHA-256 release asset
# -----------------------------------------------------------------------------

Write-Step 'Downloading the official SHA-256 release asset'

$ChecksumUrl = (
    "https://github.com/{0}/releases/download/{1}/{2}.sha256" -f
    $GitHubRepository,
    $ReleaseTag,
    $ArchiveName
)

Write-Host "URL:  $ChecksumUrl"
Write-Host "File: $ChecksumPath"

Invoke-WebRequest `
    -Uri $ChecksumUrl `
    -OutFile $ChecksumPath

if (-not (Test-Path -LiteralPath $ChecksumPath -PathType Leaf)) {
    throw "The checksum download did not create: $ChecksumPath"
}

$ChecksumFile = Get-Item -LiteralPath $ChecksumPath

if ($ChecksumFile.Length -le 0) {
    throw "The downloaded checksum file is empty: $ChecksumPath"
}

# -----------------------------------------------------------------------------
# Verify SHA-256
# -----------------------------------------------------------------------------

Write-Step 'Verifying SHA-256'

$ChecksumText = Get-Content `
    -LiteralPath $ChecksumPath `
    -Raw

$ChecksumMatch = [regex]::Match(
    $ChecksumText,
    '(?i)\b[0-9a-f]{64}\b'
)

if (-not $ChecksumMatch.Success) {
    throw @"
The official checksum file does not contain a valid SHA-256 value:

$ChecksumPath
"@
}

$ExpectedHash = $ChecksumMatch.Value.ToLowerInvariant()

$ActualHash = (
    Get-FileHash `
        -LiteralPath $ArchivePath `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

Write-Host "Expected: $ExpectedHash"
Write-Host "Actual:   $ActualHash"

if ($ActualHash -cne $ExpectedHash) {
    throw @"
SHA-256 VERIFICATION FAILED.

Expected:
$ExpectedHash

Actual:
$ActualHash

Do not execute or extract this archive.
"@
}

Write-Host
Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green

# ----
# Verify the detached signature
# ----

Write-Step 'Locating GnuPG'

$Gpg = Get-GpgCommand

Write-Host "Using GPG: $($Gpg.Source)"

# -----------------------------------------------------------------------------
# Confirm the expected primary key exists
# -----------------------------------------------------------------------------

Write-Step 'Checking the trusted MSYS2 primary key fingerprint'

$KeyOutput = @(
    & $Gpg.Source `
        --batch `
        --with-colons `
        --fingerprint `
        $ExpectedPrimaryFingerprint
)

if ($LASTEXITCODE -ne 0) {
    throw @"
GPG could not find the expected MSYS2 primary signing key.

Run Step 2 before continuing.
"@
}

$PrimaryFingerprint = $null
$WaitingForPrimaryFingerprint = $false

foreach ($Line in $KeyOutput) {
    $Fields = $Line -split ':'

    if ($Fields[0] -eq 'pub') {
        $WaitingForPrimaryFingerprint = $true
        continue
    }

    if (
        $WaitingForPrimaryFingerprint -and
        $Fields[0] -eq 'fpr'
    ) {
        $PrimaryFingerprint = $Fields[9].ToUpperInvariant()
        break
    }
}

if (-not $PrimaryFingerprint) {
    throw 'The MSYS2 primary-key fingerprint could not be determined.'
}

Write-Host "Expected: $ExpectedPrimaryFingerprint"
Write-Host "Actual:   $PrimaryFingerprint"

if ($PrimaryFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw @"
PRIMARY KEY FINGERPRINT MISMATCH.

Expected:
$ExpectedPrimaryFingerprint

Actual:
$PrimaryFingerprint

Do not execute or extract this archive.
"@
}

Write-Host
Write-Host 'Primary-key fingerprint verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify the detached signature
# -----------------------------------------------------------------------------

Write-Step 'Verifying the detached OpenPGP signature'

$StatusPath = Join-Path $env:TEMP (
    "msys2-gpg-status-$([guid]::NewGuid().ToString('N')).txt"
)

try {
    & $Gpg.Source `
        --batch `
        --status-file $StatusPath `
        --verify $SignaturePath $ArchivePath

    $GpgExitCode = $LASTEXITCODE

    if (-not (Test-Path -LiteralPath $StatusPath -PathType Leaf)) {
        throw 'GPG did not create the status file. Signature verification may have failed.'
    }

    $GpgStatus = @(
        Get-Content -LiteralPath $StatusPath
    )

    if ($GpgStatus.Count -eq 0) {
        throw 'GPG status file is empty. Signature verification incomplete.'
    }
}
finally {
    Remove-Item `
        -LiteralPath $StatusPath `
        -Force `
        -ErrorAction SilentlyContinue
}

if ($GpgExitCode -ne 0) {
    throw @"
OPENPGP SIGNATURE VERIFICATION FAILED.

GPG exit code:
$GpgExitCode

Do not execute or extract this archive.
"@
}

$GoodSigRecord = $GpgStatus |
    Where-Object {
        $_ -match '^\[GNUPG:\]\s+GOODSIG\s+'
    } |
    Select-Object -First 1

$ValidSigRecord = $GpgStatus |
    Where-Object {
        $_ -match '^\[GNUPG:\]\s+VALIDSIG\s+'
    } |
    Select-Object -First 1

if (-not $GoodSigRecord) {
    throw 'GPG did not produce the required GOODSIG status record.'
}

if (-not $ValidSigRecord) {
    throw 'GPG did not produce the required VALIDSIG status record.'
}

$ValidSigFields = (
    $ValidSigRecord -replace '^\[GNUPG:\]\s+', ''
) -split '\s+'

if ($ValidSigFields.Count -lt 2) {
    throw 'The GPG VALIDSIG status record was malformed.'
}

$SigningFingerprint = $ValidSigFields[1].ToUpperInvariant()
$ReportedPrimaryFingerprint = $ValidSigFields[-1].ToUpperInvariant()

Write-Host
Write-Host "Signing fingerprint:          $SigningFingerprint"
Write-Host "Reported primary fingerprint: $ReportedPrimaryFingerprint"
Write-Host "Expected primary fingerprint: $ExpectedPrimaryFingerprint"

if ($ReportedPrimaryFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw @"
The signature is cryptographically valid, but the reported primary signing
key does not match the official MSYS2 primary key.

Expected:
$ExpectedPrimaryFingerprint

Reported:
$ReportedPrimaryFingerprint

Do not execute or extract this archive.
"@
}

Write-Host
Write-Host 'OpenPGP signature verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Optional Authenticode inspection
# -----------------------------------------------------------------------------

Write-Step 'Inspecting the Windows Authenticode signature'

$Authenticode = Get-AuthenticodeSignature `
    -LiteralPath $ArchivePath

Write-Host "Status:  $($Authenticode.Status)"

if ($Authenticode.SignerCertificate) {
    Write-Host "Subject: $($Authenticode.SignerCertificate.Subject)"
    Write-Host "Issuer:  $($Authenticode.SignerCertificate.Issuer)"
}

if ($Authenticode.Status -eq 'Valid') {
    Write-Host
    Write-Host 'Authenticode signature is valid.' -ForegroundColor Green
}
else {
    Write-Warning (
        "Authenticode status is '$($Authenticode.Status)'. " +
        'SHA-256 and OpenPGP remain the required Step 3 checks.'
    )
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' STEP 3 COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host "Archive:"
Write-Host "  $ArchivePath"

Write-Host
Write-Host 'SHA-256:             VERIFIED' -ForegroundColor Green
Write-Host 'Primary fingerprint: VERIFIED' -ForegroundColor Green
Write-Host 'OpenPGP signature:   VERIFIED' -ForegroundColor Green

if ($Authenticode.Status -eq 'Valid') {
    Write-Host 'Authenticode:        VALID' -ForegroundColor Green
}
else {
    Write-Host "Authenticode:        $($Authenticode.Status)" `
        -ForegroundColor Yellow
}

Write-Host
Write-Host 'Nothing has been installed or extracted.'