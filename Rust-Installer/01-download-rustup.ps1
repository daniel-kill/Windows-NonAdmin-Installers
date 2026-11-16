#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 7: Download and authenticate the Rust stable standalone distribution
#
# This script:
#   1. Locates GnuPG.
#   2. Imports the Rust release key from the documented Keybase identity.
#   3. requires the exact pinned Rust release-key fingerprint.
#   4. Downloads the Rust stable channel manifest and detached signature.
#   5. Verifies the manifest signature.
#   6. Reads the GNU Windows artifact URL and SHA-256 from the authenticated
#      manifest.
#   7. Downloads the standalone archive and detached signature.
#   8. Verifies the archive's SHA-256.
#   9. Verifies the archive's detached OpenPGP signature.
#
# This script DOES NOT:
#   - Extract the archive.
#   - Execute anything from the archive.
#   - Install Rust.
#   - Modify PATH.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Rust\standalone'

$DistBaseUrl = 'https://static.rust-lang.org/dist'

$ManifestName = 'channel-rust-stable.toml'
$ManifestSignatureName = "$ManifestName.asc"

$ManifestUrl = "$DistBaseUrl/$ManifestName"
$ManifestSignatureUrl = "$ManifestUrl.asc"

$Target = 'x86_64-pc-windows-gnu'

# Rust Language (Tag and Release Signing Key) <rust-key@rust-lang.org>
$ExpectedPrimaryFingerprint = '108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE'

# Rust Forge says the Rust signing key is available on Keybase.
$RustKeyUrl = 'https://keybase.io/rust/pgp_keys.asc'

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

function Invoke-SafeDownload {
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
        throw "The expected file was not created: $Destination"
    }

    $File = Get-Item -LiteralPath $Destination

    if ($File.Length -le 0) {
        throw "The downloaded file is empty: $Destination"
    }

    Write-Host "Size: $($File.Length) bytes"

    return $File
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

function Get-PrimaryFingerprint {
    param(
        [Parameter(Mandatory)]
        [string[]]$GpgOutput
    )

    $WaitingForPrimaryFingerprint = $false

    foreach ($Line in $GpgOutput) {
        $Fields = $Line -split ':'

        if ($Fields.Count -lt 10) {
            continue
        }

        if ($Fields[0] -eq 'pub') {
            $WaitingForPrimaryFingerprint = $true
            continue
        }

        if (
            $WaitingForPrimaryFingerprint -and
            $Fields[0] -eq 'fpr'
        ) {
            return $Fields[9].ToUpperInvariant()
        }
    }

    return $null
}

function Invoke-GpgVerification {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ApplicationInfo]$Gpg,

        [Parameter(Mandatory)]
        [string]$SignaturePath,

        [Parameter(Mandatory)]
        [string]$SignedFilePath,

        [Parameter(Mandatory)]
        [string]$ExpectedFingerprint,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $StatusPath = Join-Path $env:TEMP (
        "rust-gpg-status-$([guid]::NewGuid().ToString('N')).txt"
    )

    try {
        & $Gpg.Source `
            --batch `
            --status-file $StatusPath `
            --verify $SignaturePath $SignedFilePath

        $GpgExitCode = $LASTEXITCODE

        if (Test-Path -LiteralPath $StatusPath -PathType Leaf) {
            $GpgStatus = @(
                Get-Content -LiteralPath $StatusPath
            )
        }
        else {
            $GpgStatus = @()
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
$Description signature verification FAILED.

GPG exit code:
$GpgExitCode
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
        throw "$Description verification produced no GOODSIG record."
    }

    if (-not $ValidSigRecord) {
        throw "$Description verification produced no VALIDSIG record."
    }

    $ValidSigFields = (
        $ValidSigRecord -replace '^\[GNUPG:\]\s+', ''
    ) -split '\s+'

    if ($ValidSigFields.Count -lt 2) {
        throw "$Description produced a malformed VALIDSIG record."
    }

    $SigningFingerprint = $ValidSigFields[1].ToUpperInvariant()

    # Current GnuPG outputs the primary-key fingerprint as the final VALIDSIG
    # field when a signing subkey created the signature.
    $ReportedPrimaryFingerprint = (
        $ValidSigFields[-1]
    ).ToUpperInvariant()

    Write-Host
    Write-Host "Signing fingerprint:          $SigningFingerprint"
    Write-Host "Reported primary fingerprint: $ReportedPrimaryFingerprint"
    Write-Host "Expected primary fingerprint: $ExpectedFingerprint"

    if ($ReportedPrimaryFingerprint -ne $ExpectedFingerprint) {
        throw @"
$Description has a cryptographically valid signature, but its primary key
does not match the pinned Rust release-key fingerprint.

Expected:
$ExpectedFingerprint

Reported:
$ReportedPrimaryFingerprint
"@
    }

    Write-Host
    Write-Host "$Description signature verification PASSED." `
        -ForegroundColor Green

    return [pscustomobject]@{
        SigningFingerprint = $SigningFingerprint
        PrimaryFingerprint = $ReportedPrimaryFingerprint
    }
}

# -----------------------------------------------------------------------------
# Verify platform
# -----------------------------------------------------------------------------

Write-Step 'Checking Windows architecture'

$Architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture

Write-Host "Architecture: $Architecture"

if ($Architecture -ne [Runtime.InteropServices.Architecture]::X64) {
    throw @"
This script is intended for x86-64 Windows.

Detected architecture:
$Architecture
"@
}

# -----------------------------------------------------------------------------
# Prepare directory
# -----------------------------------------------------------------------------

Write-Step 'Preparing the download directory'

New-Item `
    -ItemType Directory `
    -Path $DownloadDir `
    -Force |
Out-Null

Write-Host "Download directory: $DownloadDir"

$ManifestPath = Join-Path $DownloadDir $ManifestName
$ManifestSignaturePath = Join-Path $DownloadDir $ManifestSignatureName
$RustKeyPath = Join-Path $DownloadDir 'rust-release-key.asc'
$AuditPath = Join-Path $DownloadDir 'rust-standalone-verification.txt'

# -----------------------------------------------------------------------------
# Locate GnuPG
# -----------------------------------------------------------------------------

Write-Step 'Locating GnuPG'

$Gpg = Get-GpgCommand

Write-Host "Using GPG: $($Gpg.Source)"

# -----------------------------------------------------------------------------
# Download the Rust release key from the documented Keybase identity
# -----------------------------------------------------------------------------

Write-Step 'Downloading the Rust release signing key'

$null = Invoke-SafeDownload `
    -Uri $RustKeyUrl `
    -Destination $RustKeyPath

# -----------------------------------------------------------------------------
# Inspect the downloaded key before importing it
# -----------------------------------------------------------------------------

Write-Step 'Inspecting the downloaded Rust signing key'

$KeyInspectionOutput = @(
    & $Gpg.Source `
        --batch `
        --with-colons `
        --import-options show-only `
        --import $RustKeyPath
)

if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect the downloaded Rust signing key.'
}

$DownloadedFingerprint = Get-PrimaryFingerprint `
    -GpgOutput $KeyInspectionOutput

if (-not $DownloadedFingerprint) {
    throw 'Could not determine the downloaded key primary fingerprint.'
}

Write-Host "Expected: $ExpectedPrimaryFingerprint"
Write-Host "Actual:   $DownloadedFingerprint"

if ($DownloadedFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw @"
DOWNLOADED RUST KEY FINGERPRINT MISMATCH.

Expected:
$ExpectedPrimaryFingerprint

Downloaded:
$DownloadedFingerprint

The key will not be imported.
"@
}

Write-Host
Write-Host 'Downloaded key fingerprint verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Import the validated key
# -----------------------------------------------------------------------------

Write-Step 'Importing the validated Rust signing key'

& $Gpg.Source `
    --batch `
    --import $RustKeyPath

if ($LASTEXITCODE -ne 0) {
    throw 'GPG failed to import the validated Rust signing key.'
}

# -----------------------------------------------------------------------------
# Re-read the key from the local GPG keyring
# -----------------------------------------------------------------------------

Write-Step 'Validating the imported Rust signing key'

$ImportedKeyOutput = @(
    & $Gpg.Source `
        --batch `
        --with-colons `
        --fingerprint `
        $ExpectedPrimaryFingerprint
)

if ($LASTEXITCODE -ne 0) {
    throw 'GPG could not inspect the imported Rust signing key.'
}

$ImportedFingerprint = Get-PrimaryFingerprint `
    -GpgOutput $ImportedKeyOutput

if (-not $ImportedFingerprint) {
    throw 'Could not determine the imported key primary fingerprint.'
}

Write-Host "Expected: $ExpectedPrimaryFingerprint"
Write-Host "Actual:   $ImportedFingerprint"

if ($ImportedFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw 'The imported Rust signing-key fingerprint does not match.'
}

Write-Host
Write-Host 'Imported key fingerprint verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Download the stable manifest and signature
# -----------------------------------------------------------------------------

Write-Step 'Downloading the Rust stable channel manifest'

$null = Invoke-SafeDownload `
    -Uri $ManifestUrl `
    -Destination $ManifestPath

Write-Step 'Downloading the manifest detached signature'

$null = Invoke-SafeDownload `
    -Uri $ManifestSignatureUrl `
    -Destination $ManifestSignaturePath

# -----------------------------------------------------------------------------
# Authenticate the manifest before parsing any metadata from it
# -----------------------------------------------------------------------------

Write-Step 'Authenticating the Rust stable channel manifest'

$ManifestVerification = Invoke-GpgVerification `
    -Gpg $Gpg `
    -SignaturePath $ManifestSignaturePath `
    -SignedFilePath $ManifestPath `
    -ExpectedFingerprint $ExpectedPrimaryFingerprint `
    -Description 'Rust stable manifest'

# -----------------------------------------------------------------------------
# Parse the now-authenticated manifest
# -----------------------------------------------------------------------------

Write-Step 'Reading the authenticated stable manifest'

$ManifestContent = Get-Content `
    -LiteralPath $ManifestPath `
    -Raw

if ([string]::IsNullOrWhiteSpace($ManifestContent)) {
    throw 'The authenticated Rust stable manifest is empty.'
}

$VersionMatch = [regex]::Match(
    $ManifestContent,
    '(?ms)^\[pkg\.rust\].*?^version\s*=\s*"([^"]+)"'
)

if (-not $VersionMatch.Success) {
    throw 'Could not determine the stable Rust version from the manifest.'
}

$VersionString = $VersionMatch.Groups[1].Value

$SemanticVersionMatch = [regex]::Match(
    $VersionString,
    '^\d+\.\d+\.\d+'
)

if (-not $SemanticVersionMatch.Success) {
    throw "Could not parse a semantic version from: $VersionString"
}

$RustVersion = $SemanticVersionMatch.Value

Write-Host "Manifest version: $VersionString"
Write-Host "Stable version:   $RustVersion"

# -----------------------------------------------------------------------------
# Locate target metadata
# -----------------------------------------------------------------------------

Write-Step "Locating authenticated metadata for $Target"

$EscapedTarget = [regex]::Escape($Target)

$TargetTablePattern = (
    '(?ms)^\[pkg\.rust\.target\.' +
    $EscapedTarget +
    '\]\s*(.*?)(?=^\[|\z)'
)

$TargetTableMatch = [regex]::Match(
    $ManifestContent,
    $TargetTablePattern
)

if (-not $TargetTableMatch.Success) {
    throw "No target metadata was found for $Target."
}

$TargetTable = $TargetTableMatch.Groups[1].Value

$UrlMatch = [regex]::Match(
    $TargetTable,
    '(?m)^url\s*=\s*"([^"]+)"'
)

if (-not $UrlMatch.Success) {
    throw "No archive URL was found for $Target."
}

$HashMatch = [regex]::Match(
    $TargetTable,
    '(?m)^hash\s*=\s*"([0-9A-Fa-f]{64})"'
)

if (-not $HashMatch.Success) {
    throw "No SHA-256 value was found for $Target."
}

$ArchiveUrl = $UrlMatch.Groups[1].Value
$ExpectedArchiveHash = $HashMatch.Groups[1].Value.ToLowerInvariant()

# -----------------------------------------------------------------------------
# Constrain the authenticated URL
# -----------------------------------------------------------------------------

$ArchiveUri = [uri]$ArchiveUrl

if ($ArchiveUri.Scheme -ne 'https') {
    throw "The archive URL does not use HTTPS: $ArchiveUrl"
}

if ($ArchiveUri.Host -ne 'static.rust-lang.org') {
    throw "Unexpected Rust distribution host: $($ArchiveUri.Host)"
}

$ArchiveName = [IO.Path]::GetFileName($ArchiveUri.AbsolutePath)

$ExpectedArchiveNamePrefix = "rust-{0}-{1}" -f $RustVersion, $Target
$ValidArchiveFormats = @(".tar.xz", ".tar.gz")
$ArchiveExtension = ""

foreach ($format in $ValidArchiveFormats) {
    if ($ArchiveName -like "$ExpectedArchiveNamePrefix$format") {
        $ArchiveExtension = $format
        break
    }
}

if (-not $ArchiveExtension) {
    throw @"
Unexpected standalone archive name.

Expected formats:
$(foreach ($format in $ValidArchiveFormats) { "$ExpectedArchiveNamePrefix$format" })

Manifest provided:
$ArchiveName
"@
}

$ArchivePath = Join-Path $DownloadDir $ArchiveName
$ArchiveSignatureUrl = "$ArchiveUrl.asc"
$ArchiveSignaturePath = "$ArchivePath.asc"

Write-Host "Target:           $Target"
Write-Host "Archive:          $ArchiveName"
Write-Host "Archive URL:      $ArchiveUrl"
Write-Host "Expected SHA-256: $ExpectedArchiveHash"

# -----------------------------------------------------------------------------
# Download archive and signature
# -----------------------------------------------------------------------------

Write-Step 'Downloading the Rust GNU Windows standalone archive'

$null = Invoke-SafeDownload `
    -Uri $ArchiveUrl `
    -Destination $ArchivePath

Write-Step 'Downloading the archive detached signature'

$null = Invoke-SafeDownload `
    -Uri $ArchiveSignatureUrl `
    -Destination $ArchiveSignaturePath

# -----------------------------------------------------------------------------
# Verify SHA-256 against the authenticated manifest
# -----------------------------------------------------------------------------

Write-Step 'Verifying archive SHA-256'

$ActualArchiveHash = (
    Get-FileHash `
        -LiteralPath $ArchivePath `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

Write-Host "Expected: $ExpectedArchiveHash"
Write-Host "Actual:   $ActualArchiveHash"

if ($ActualArchiveHash -cne $ExpectedArchiveHash) {
    throw @"
RUST ARCHIVE SHA-256 VERIFICATION FAILED.

Expected:
$ExpectedArchiveHash

Actual:
$ActualArchiveHash

Do not extract or execute this archive.
"@
}

Write-Host
Write-Host 'Archive SHA-256 verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify archive detached signature
# -----------------------------------------------------------------------------

Write-Step 'Authenticating the Rust standalone archive'

$ArchiveVerification = Invoke-GpgVerification `
    -Gpg $Gpg `
    -SignaturePath $ArchiveSignaturePath `
    -SignedFilePath $ArchivePath `
    -ExpectedFingerprint $ExpectedPrimaryFingerprint `
    -Description 'Rust standalone archive'

# -----------------------------------------------------------------------------
# Audit record
# -----------------------------------------------------------------------------

Write-Step 'Writing the verification audit record'

$AuditRecord = @"
Rust standalone verification record

Target:
$Target

Stable version:
$RustVersion

Rust release-key fingerprint:
$ExpectedPrimaryFingerprint

Manifest:
$ManifestPath

Manifest signature:
$ManifestSignaturePath

Manifest signing fingerprint:
$($ManifestVerification.SigningFingerprint)

Manifest primary fingerprint:
$($ManifestVerification.PrimaryFingerprint)

Archive:
$ArchivePath

Archive signature:
$ArchiveSignaturePath

Archive signing fingerprint:
$($ArchiveVerification.SigningFingerprint)

Archive primary fingerprint:
$($ArchiveVerification.PrimaryFingerprint)

Expected SHA256:
$ExpectedArchiveHash

Actual SHA256:
$ActualArchiveHash

Manifest signature verified:
True

Archive signature verified:
True

Archive SHA256 verified against authenticated manifest:
True

Nothing was extracted or executed.
"@

Set-Content `
    -LiteralPath $AuditPath `
    -Value $AuditRecord `
    -Encoding utf8NoBOM

Write-Host "Audit record:"
Write-Host "  $AuditPath"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' STEP 7 COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host 'Stable version:'
Write-Host "  $RustVersion"

Write-Host
Write-Host 'Target:'
Write-Host "  $Target"

Write-Host
Write-Host 'Archive:'
Write-Host "  $ArchivePath"

Write-Host
Write-Host 'Rust signing-key fingerprint: VERIFIED' `
    -ForegroundColor Green

Write-Host 'Stable manifest signature:    VERIFIED' `
    -ForegroundColor Green

Write-Host 'Archive SHA-256:              VERIFIED' `
    -ForegroundColor Green

Write-Host 'Archive OpenPGP signature:    VERIFIED' `
    -ForegroundColor Green

Write-Host
Write-Host 'Nothing has been extracted or executed.'
Write-Host 'Rust has NOT been installed.'
Write-Host 'PATH has NOT been modified.'