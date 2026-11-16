#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 4: Extract and initialize MSYS2 without administrator privileges
#
# Parameters:
#   -Force: Remove the existing installation directory if it exists and proceed
#           with installation. Use with caution as this will delete all existing
#           MSYS2 data in the default location.
#
# This script:
#   1. Locates the newest downloaded MSYS2 SFX archive.
#   2. Re-verifies its official SHA-256 checksum.
#   3. Re-verifies its OpenPGP signature and primary fingerprint.
#   4. Verifies its Windows Authenticode signature.
#   5. Extracts MSYS2 into the current user's profile.
#   6. Runs an initial MSYS2 login shell.
#   7. Verifies bash, pacman, and the expected directory structure.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the system PATH.
#   - Install GCC or Rust.
#   - Modify Git for Windows.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\MSYS2'

$InstallRoot = Join-Path $HOME 'msys64'
$InstallParent = Split-Path -Parent $InstallRoot

$ExpectedPrimaryFingerprint = '0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC'

$ArchivePattern = '^msys2-base-x86_64-(?<Date>\d{8})\.sfx\.exe$'

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

$ArchivePath = $null
$SignaturePath = $null
$ChecksumPath = $null
$CreatedInstallRoot = $false
$InstallationComplete = $false

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

function Test-IsAdministrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = [Security.Principal.WindowsPrincipal]::new($Identity)

    return $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Remove-PartialInstallation {
    if (
        $CreatedInstallRoot -and
        -not $InstallationComplete -and
        (Test-Path -LiteralPath $InstallRoot)
    ) {
        Write-Warning "Removing partial installation: $InstallRoot"

        Remove-Item `
            -LiteralPath $InstallRoot `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# Safety checks
# -----------------------------------------------------------------------------

Write-Step 'Checking installation conditions'

if (Test-IsAdministrator) {
    Write-Warning @'
PowerShell is running with administrator privileges. Administrator rights
are not required for this installation.
'@
}

if (-not (Test-Path -LiteralPath $InstallParent -PathType Container)) {
    throw "The installation parent directory does not exist: $InstallParent"
}

if ($InstallRoot -match '[^\x00-\x7F]') {
    throw "The installation path contains non-ASCII characters: $InstallRoot"
}

if ($InstallRoot -match '\s') {
    throw "The installation path contains spaces: $InstallRoot"
}

if (Test-Path -LiteralPath $InstallRoot) {
    if ($Force) {
        Write-Warning "Removing existing installation directory: $InstallRoot"
        
        # Retry logic to handle potential file locks
        $MaxRetries = 3
        $RetryCount = 0
        $Removed = $false
        
        while ($RetryCount -lt $MaxRetries -and -not $Removed) {
            try {
                Remove-Item `
                    -LiteralPath $InstallRoot `
                    -Recurse `
                    -Force `
                    -ErrorAction Stop
                $Removed = $true
            }
            catch {
                $RetryCount++
                if ($RetryCount -lt $MaxRetries) {
                    Write-Host "Retry $RetryCount of $MaxRetries - Waiting before retrying..." -ForegroundColor Yellow
                    Start-Sleep -Milliseconds 500
                }
                else {
                    throw $_.Exception
                }
            }
        }
        
        Write-Host "Existing installation removed." -ForegroundColor Yellow
    }
    else {
        throw @"
The target installation directory already exists:

$InstallRoot

This script will not overwrite or merge with an existing directory.
Use -Force to remove the existing directory and reinstall, or inspect or 
remove that directory before rerunning Step 4.
"@
    }
}

$ParentItem = Get-Item -LiteralPath $InstallParent -Force

if ($ParentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw @"
The installation parent is a reparse point, symlink, or junction:

$InstallParent

Choose a normal local NTFS directory.
"@
}

$DriveName = Split-Path -Qualifier $InstallRoot

if (-not $DriveName) {
    throw "Could not determine the drive containing: $InstallRoot"
}

$DriveLetter = $DriveName.TrimEnd('\').TrimEnd(':')

$Volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction Stop

if ($Volume.FileSystem -ne 'NTFS') {
    throw @"
The installation drive is not NTFS.

Drive:       $DriveName
File system: $($Volume.FileSystem)
"@
}

Write-Host "Download directory: $DownloadDir"
Write-Host "Installation path:  $InstallRoot"
Write-Host "File system:        $($Volume.FileSystem)"

# -----------------------------------------------------------------------------
# Locate the newest downloaded archive
# -----------------------------------------------------------------------------

Write-Step 'Locating the downloaded MSYS2 archive'

if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
    throw "The MSYS2 download directory does not exist: $DownloadDir"
}

$Candidates = foreach (
    $File in Get-ChildItem `
        -LiteralPath $DownloadDir `
        -File `
        -Filter 'msys2-base-x86_64-*.sfx.exe'
) {
    if ($File.Name -notmatch $ArchivePattern) {
        continue
    }

    $ParsedDate = [datetime]::MinValue

    $Parsed = [datetime]::TryParseExact(
        $Matches.Date,
        'yyyyMMdd',
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref]$ParsedDate
    )

    if ($Parsed) {
        [pscustomobject]@{
            File        = $File
            ReleaseDate = $ParsedDate
        }
    }
}

$Selected = $Candidates |
Sort-Object ReleaseDate -Descending |
Select-Object -First 1

if (-not $Selected) {
    throw @"
No versioned MSYS2 SFX archive was found in:

$DownloadDir
"@
}

$ArchivePath = $Selected.File.FullName
$SignaturePath = "$ArchivePath.sig"
$ChecksumPath = "$ArchivePath.sha256"

Write-Host "Archive:      $ArchivePath"
Write-Host "Release date: $($Selected.ReleaseDate.ToString('yyyy-MM-dd'))"
Write-Host "Size:         $($Selected.File.Length) bytes"

# -----------------------------------------------------------------------------
# Require existing verification files
# -----------------------------------------------------------------------------

Write-Step 'Checking verification files'

foreach ($RequiredFile in @($SignaturePath, $ChecksumPath)) {
    if (-not (Test-Path -LiteralPath $RequiredFile -PathType Leaf)) {
        throw @"
A required verification file is missing:

$RequiredFile

Run Step 3 successfully before running Step 4.
"@
    }

    if ((Get-Item -LiteralPath $RequiredFile).Length -le 0) {
        throw "A verification file is empty: $RequiredFile"
    }
}

Write-Host "Checksum:  $ChecksumPath"
Write-Host "Signature: $SignaturePath"

# -----------------------------------------------------------------------------
# Re-verify SHA-256
# -----------------------------------------------------------------------------

Write-Step 'Re-verifying SHA-256'

$ChecksumText = Get-Content `
    -LiteralPath $ChecksumPath `
    -Raw

$ChecksumMatch = [regex]::Match(
    $ChecksumText,
    '(?i)\b[0-9a-f]{64}\b'
)

if (-not $ChecksumMatch.Success) {
    throw "No valid SHA-256 value was found in: $ChecksumPath"
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
    throw 'SHA-256 verification failed. The archive will not be executed.'
}

Write-Host 'SHA-256 verification PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Re-verify the signing key
# -----------------------------------------------------------------------------

Write-Step 'Re-verifying the MSYS2 signing key'

$Gpg = Get-GpgCommand

Write-Host "Using GPG: $($Gpg.Source)"

$KeyOutput = @(
    & $Gpg.Source `
        --batch `
        --with-colons `
        --fingerprint `
        $ExpectedPrimaryFingerprint
)

if ($LASTEXITCODE -ne 0) {
    throw 'The expected MSYS2 signing key was not found. Run Step 2 again.'
}

$PrimaryFingerprint = $null
$AwaitingPrimaryFingerprint = $false

foreach ($Line in $KeyOutput) {
    $Fields = $Line -split ':'

    if ($Fields[0] -eq 'pub') {
        $AwaitingPrimaryFingerprint = $true
        continue
    }

    if (
        $AwaitingPrimaryFingerprint -and
        $Fields[0] -eq 'fpr'
    ) {
        $PrimaryFingerprint = $Fields[9].ToUpperInvariant()
        break
    }
}

if (-not $PrimaryFingerprint) {
    throw 'The primary fingerprint could not be determined.'
}

Write-Host "Expected: $ExpectedPrimaryFingerprint"
Write-Host "Actual:   $PrimaryFingerprint"

if ($PrimaryFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw 'The MSYS2 primary-key fingerprint does not match.'
}

Write-Host 'Primary-key fingerprint verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Re-verify OpenPGP signature
# -----------------------------------------------------------------------------

Write-Step 'Re-verifying the OpenPGP signature'

$StatusPath = Join-Path $env:TEMP (
    "msys2-install-gpg-$([guid]::NewGuid().ToString('N')).txt"
)

try {
    & $Gpg.Source `
        --batch `
        --status-file $StatusPath `
        --verify $SignaturePath $ArchivePath

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
    throw 'OpenPGP signature verification failed.'
}

$GoodSigRecord = $GpgStatus |
    Where-Object { $_ -match '^\[GNUPG:\]\s+GOODSIG\s+' } |
    Select-Object -First 1

$ValidSigRecord = $GpgStatus |
    Where-Object { $_ -match '^\[GNUPG:\]\s+VALIDSIG\s+' } |
    Select-Object -First 1

if (-not $GoodSigRecord) {
    throw 'GPG did not produce the required GOODSIG record.'
}

if (-not $ValidSigRecord) {
    throw 'GPG did not produce the required VALIDSIG record.'
}

$ValidSigFields = (
    $ValidSigRecord -replace '^\[GNUPG:\]\s+', ''
) -split '\s+'

$SigningFingerprint = $ValidSigFields[1].ToUpperInvariant()
$ReportedPrimaryFingerprint = $ValidSigFields[-1].ToUpperInvariant()

Write-Host "Signing fingerprint:          $SigningFingerprint"
Write-Host "Reported primary fingerprint: $ReportedPrimaryFingerprint"

if ($ReportedPrimaryFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw 'The signature was not made by the expected MSYS2 primary key.'
}

Write-Host 'OpenPGP signature verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Re-verify Authenticode
# -----------------------------------------------------------------------------

Write-Step 'Re-verifying the Authenticode signature'

$Authenticode = Get-AuthenticodeSignature `
    -LiteralPath $ArchivePath

Write-Host "Status:  $($Authenticode.Status)"

if ($Authenticode.SignerCertificate) {
    Write-Host "Subject: $($Authenticode.SignerCertificate.Subject)"
    Write-Host "Issuer:  $($Authenticode.SignerCertificate.Issuer)"
}

if ($Authenticode.Status -ne 'Valid') {
    throw @"
The Authenticode signature is not valid.

Status: $($Authenticode.Status)
"@
}

Write-Host 'Authenticode verification PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Extract the SFX archive
# -----------------------------------------------------------------------------

Write-Step 'Extracting MSYS2'

Write-Host "Archive:     $ArchivePath"
Write-Host "Destination: $InstallRoot"

try {
    # The SFX archive contains an msys64 top-level directory.
    # Supplying the user's profile as the output parent therefore creates:
    #
    # C:\Users\danie\msys64

    & $ArchivePath `
        -y `
        "-o$InstallParent"

    $ExtractionExitCode = $LASTEXITCODE

    if ($ExtractionExitCode -ne 0) {
        throw "The SFX extractor returned exit code $ExtractionExitCode."
    }

    if (-not (Test-Path -LiteralPath $InstallRoot -PathType Container)) {
        throw @"
Extraction completed without reporting an error, but the expected directory
was not created:

$InstallRoot
"@
    }

    $CreatedInstallRoot = $true

    # -------------------------------------------------------------------------
    # Check expected files before executing the first login shell
    # -------------------------------------------------------------------------

    Write-Step 'Checking the extracted MSYS2 layout'

    $BashPath = Join-Path $InstallRoot 'usr\bin\bash.exe'
    $PacmanPath = Join-Path $InstallRoot 'usr\bin\pacman.exe'
    $ShellScriptPath = Join-Path $InstallRoot 'msys2_shell.cmd'
    $Ucrt64Path = Join-Path $InstallRoot 'ucrt64'

    $RequiredPaths = @(
        $BashPath
        $PacmanPath
        $ShellScriptPath
        $Ucrt64Path
    )

    foreach ($RequiredPath in $RequiredPaths) {
        if (-not (Test-Path -LiteralPath $RequiredPath)) {
            throw "An expected MSYS2 path is missing: $RequiredPath"
        }

        Write-Host "Found: $RequiredPath"
    }

    # -------------------------------------------------------------------------
    # Run the initial login shell
    # -------------------------------------------------------------------------

    Write-Step 'Running the initial MSYS2 login shell'

    $PreviousMSYSTEM = $env:MSYSTEM
    $PreviousCHERE = $env:CHERE_INVOKING

    try {
        $env:CHERE_INVOKING = '1'
        $env:MSYSTEM = 'UCRT64'

        & $BashPath `
            --login `
            -c 'printf "MSYS2 initial login completed.\n"'
    }
    finally {
        if ($null -eq $PreviousMSYSTEM) {
            Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
        }
        else {
            $env:MSYSTEM = $PreviousMSYSTEM
        }

        if ($null -eq $PreviousCHERE) {
            Remove-Item Env:\CHERE_INVOKING -ErrorAction SilentlyContinue
        }
        else {
            $env:CHERE_INVOKING = $PreviousCHERE
        }
    }

    $LoginExitCode = $LASTEXITCODE

    if ($LoginExitCode -ne 0) {
        throw "The initial MSYS2 login shell returned exit code $LoginExitCode."
    }

    # -------------------------------------------------------------------------
    # Verify bash
    # -------------------------------------------------------------------------

    Write-Step 'Verifying Bash'

    $BashVersion = & $BashPath --version

    if ($LASTEXITCODE -ne 0) {
        throw 'bash.exe did not run successfully.'
    }

    $BashVersion |
    Select-Object -First 1 |
    ForEach-Object {
        Write-Host $_
    }

    # -------------------------------------------------------------------------
    # Verify pacman
    # -------------------------------------------------------------------------

    Write-Step 'Verifying pacman'

    $PacmanVersion = & $PacmanPath --version

    if ($LASTEXITCODE -ne 0) {
        throw 'pacman.exe did not run successfully.'
    }

    $PacmanVersion |
    Where-Object { $_ -match 'Pacman v' } |
    Select-Object -First 1 |
    ForEach-Object {
        Write-Host $_
    }

    # -------------------------------------------------------------------------
    # Verify the UCRT64 shell environment
    # -------------------------------------------------------------------------

    Write-Step 'Verifying the UCRT64 environment'

    $PreviousMSYSTEM = $env:MSYSTEM
    $PreviousCHERE = $env:CHERE_INVOKING

    try {
        $env:CHERE_INVOKING = '1'
        $env:MSYSTEM = 'UCRT64'

        $EnvironmentOutput = & $BashPath `
            --login `
            -c 'printf "MSYSTEM=%s\nMINGW_PREFIX=%s\nPATH_HEAD=%s\n" "$MSYSTEM" "$MINGW_PREFIX" "${PATH%%:*}"'

        if ($LASTEXITCODE -ne 0) {
            throw 'The UCRT64 environment verification command failed.'
        }

        $EnvironmentOutput | ForEach-Object {
            Write-Host $_
        }

        $EnvironmentText = $EnvironmentOutput -join "`n"

        if ($EnvironmentText -notmatch '(?m)^MSYSTEM=UCRT64$') {
            throw 'The initialized shell did not report MSYSTEM=UCRT64.'
        }

        if ($EnvironmentText -notmatch '(?m)^MINGW_PREFIX=/ucrt64$') {
            throw 'The initialized shell did not report MINGW_PREFIX=/ucrt64.'
        }
    }
    finally {
        if ($null -eq $PreviousMSYSTEM) {
            Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
        }
        else {
            $env:MSYSTEM = $PreviousMSYSTEM
        }

        if ($null -eq $PreviousCHERE) {
            Remove-Item Env:\CHERE_INVOKING -ErrorAction SilentlyContinue
        }
        else {
            $env:CHERE_INVOKING = $PreviousCHERE
        }
    }

    $InstallationComplete = $true
}
catch {
    Remove-PartialInstallation
    throw
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' STEP 4 COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host 'MSYS2 installation:'
Write-Host "  $InstallRoot"

Write-Host
Write-Host 'Archive SHA-256:      VERIFIED' -ForegroundColor Green
Write-Host 'OpenPGP signature:    VERIFIED' -ForegroundColor Green
Write-Host 'Authenticode:         VALID' -ForegroundColor Green
Write-Host 'Extraction:           COMPLETE' -ForegroundColor Green
Write-Host 'Initial login shell:  COMPLETE' -ForegroundColor Green
Write-Host 'Bash:                 VERIFIED' -ForegroundColor Green
Write-Host 'Pacman:               VERIFIED' -ForegroundColor Green
Write-Host 'UCRT64 environment:   VERIFIED' -ForegroundColor Green

Write-Host
Write-Host 'No GCC or Rust packages have been installed.'
Write-Host 'The Windows system PATH has not been modified.'