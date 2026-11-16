#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$ExpectedFingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'
$KeyServer = 'keyserver.ubuntu.com'

# -----------------------------------------------------------------------------
# Helper
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
# Find GPG
# -----------------------------------------------------------------------------

Write-Step 'Locating GnuPG'

$Gpg = Get-Command gpg.exe -ErrorAction SilentlyContinue

if (-not $Gpg) {
    $Gpg = Get-Command gpg -ErrorAction SilentlyContinue
}

if (-not $Gpg) {
    throw 'GnuPG was not found in PATH.'
}

Write-Host "Using GPG: $($Gpg.Source)"

# -----------------------------------------------------------------------------
# Check whether the key already exists
# -----------------------------------------------------------------------------

Write-Step 'Checking for the MSYS2 signing key'

$ExistingOutput = & $Gpg.Source `
    --batch `
    --with-colons `
    --fingerprint `
    $ExpectedFingerprint `
    2>$null

$ExistingFingerprint = $ExistingOutput |
    Where-Object { $_ -like 'fpr:*' } |
    ForEach-Object {
        ($_ -split ':')[9]
    } |
    Where-Object {
        $_ -eq $ExpectedFingerprint
    } |
    Select-Object -First 1

if ($ExistingFingerprint) {
    Write-Host 'The expected MSYS2 signing key is already present.' `
        -ForegroundColor Green
}
else {
    # -------------------------------------------------------------------------
    # Import key from the keyserver documented by MSYS2
    # -------------------------------------------------------------------------

    Write-Step "Retrieving the MSYS2 signing key from $KeyServer"

    & $Gpg.Source `
        --batch `
        --keyserver $KeyServer `
        --recv-keys $ExpectedFingerprint

    if ($LASTEXITCODE -ne 0) {
        throw "GPG failed to retrieve the MSYS2 signing key."
    }
}

# -----------------------------------------------------------------------------
# Independently inspect the imported fingerprint
# -----------------------------------------------------------------------------

Write-Step 'Validating the imported key fingerprint'

$KeyOutput = @(
    & $Gpg.Source `
        --batch `
        --with-colons `
        --fingerprint `
        $ExpectedFingerprint
)

if ($LASTEXITCODE -ne 0) {
    throw 'GPG could not inspect the imported signing key.'
}

$PrimaryKeySeen = $false
$ActualPrimaryFingerprint = $null

foreach ($Line in $KeyOutput) {
    $Fields = $Line -split ':'

    if ($Fields[0] -eq 'pub') {
        $PrimaryKeySeen = $true
        continue
    }

    if (
        $PrimaryKeySeen -and
        $Fields[0] -eq 'fpr'
    ) {
        $ActualPrimaryFingerprint = $Fields[9].ToUpperInvariant()
        break
    }
}

if (-not $ActualPrimaryFingerprint) {
    throw 'Could not determine the primary key fingerprint.'
}

Write-Host
Write-Host "Expected: $ExpectedFingerprint"
Write-Host "Actual:   $ActualPrimaryFingerprint"

if ($ActualPrimaryFingerprint -ne $ExpectedFingerprint) {
    throw @"
MSYS2 SIGNING KEY FINGERPRINT MISMATCH.

Expected:
$ExpectedFingerprint

Actual:
$ActualPrimaryFingerprint

Do not trust this key.
"@
}

Write-Host
Write-Host 'Primary fingerprint verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Show human-readable key information
# -----------------------------------------------------------------------------

Write-Step 'MSYS2 signing key information'

& $Gpg.Source `
    --fingerprint `
    $ExpectedFingerprint

if ($LASTEXITCODE -ne 0) {
    throw 'GPG failed while displaying the signing key.'
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' STEP 2 COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host 'MSYS2 primary signing key fingerprint:'
Write-Host "  $ActualPrimaryFingerprint"

Write-Host
Write-Host 'Fingerprint: VERIFIED' -ForegroundColor Green

Write-Host
Write-Host 'Nothing has been installed or extracted.'