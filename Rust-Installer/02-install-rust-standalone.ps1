#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 8: Install the authenticated Rust standalone GNU toolchain
#
# This script:
#   1. Locates the Rust standalone archive downloaded by Step 7.
#   2. Revalidates the pinned Rust signing key.
#   3. Revalidates the stable manifest signature.
#   4. Reads the expected archive hash from the authenticated manifest.
#   5. Revalidates the archive SHA-256 and detached signature.
#   6. Extracts the archive with MSYS2 tar.
#   7. Inspects the included installer.
#   8. Installs Rust into a user-owned directory.
#   9. Verifies rustc, Cargo, Rustdoc, and the GNU host.
#  10. Builds and runs debug and release Cargo projects.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Install Rustup.
#   - Modify the machine PATH.
#   - Modify the persistent user PATH.
#   - Modify Git for Windows.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$DownloadDir = Join-Path $HOME 'Downloads\Rust\standalone'
$InstallRoot = Join-Path $HOME '.local\rust'
$RunId = [guid]::NewGuid().ToString('N')
$TestRoot = Join-Path $env:TEMP "rust-standalone-test-$RunId"

$MSYS2Root = Join-Path $HOME 'msys64'
$BashPath = Join-Path $MSYS2Root 'usr\bin\bash.exe'
$TarPath = Join-Path $MSYS2Root 'usr\bin\tar.exe'
$UCRT64Bin = Join-Path $MSYS2Root 'ucrt64\bin'

$ManifestPath = Join-Path $DownloadDir 'channel-rust-stable.toml'
$ManifestSignaturePath = "$ManifestPath.asc"

$Target = 'x86_64-pc-windows-gnu'

$ExpectedPrimaryFingerprint =
'108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE'

# Extraction occurs under a unique MSYS2 temporary directory.
$ExtractRootWindows = Join-Path `
    (Join-Path $MSYS2Root 'tmp') `
    "rust-standalone-install-$RunId"
$ExtractRootMSYS = "/tmp/rust-standalone-install-$RunId"

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

$ArchivePath = $null
$ArchiveSignaturePath = $null
$RustVersion = $null
$ExpectedArchiveHash = $null
$ActualArchiveHash = $null
$ExtractedInstallerRootWindows = $null
$OriginalProcessPath = $env:PATH

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

function Get-PrimaryFingerprint {
    param(
        [Parameter(Mandatory)]
        [string[]]$GpgOutput
    )

    $AwaitingFingerprint = $false

    foreach ($Line in $GpgOutput) {
        $Fields = $Line -split ':'

        if ($Fields.Count -lt 10) {
            continue
        }

        if ($Fields[0] -eq 'pub') {
            $AwaitingFingerprint = $true
            continue
        }

        if (
            $AwaitingFingerprint -and
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
        [string]$Description
    )

    $StatusPath = Join-Path $env:TEMP (
        "rust-gpg-$([guid]::NewGuid().ToString('N')).txt"
    )

    try {
        & $Gpg.Source `
            --batch `
            --status-file $StatusPath `
            --verify $SignaturePath $SignedFilePath

        $ExitCode = $LASTEXITCODE

        if (Test-Path -LiteralPath $StatusPath -PathType Leaf) {
            $Status = @(Get-Content -LiteralPath $StatusPath)
        }
        else {
            $Status = @()
        }
    }
    finally {
        Remove-Item `
            -LiteralPath $StatusPath `
            -Force `
            -ErrorAction SilentlyContinue
    }

    if ($ExitCode -ne 0) {
        throw "$Description signature verification failed."
    }

    $GoodSig = $Status |
    Where-Object {
        $_ -match '^\[GNUPG:\]\s+GOODSIG\s+'
    } |
    Select-Object -First 1

    $ValidSig = $Status |
    Where-Object {
        $_ -match '^\[GNUPG:\]\s+VALIDSIG\s+'
    } |
    Select-Object -First 1

    if (-not $GoodSig) {
        throw "$Description produced no GOODSIG record."
    }

    if (-not $ValidSig) {
        throw "$Description produced no VALIDSIG record."
    }

    $Fields = (
        $ValidSig -replace '^\[GNUPG:\]\s+', ''
    ) -split '\s+'

    if ($Fields.Count -lt 2) {
        throw "$Description produced a malformed VALIDSIG record."
    }

    $SigningFingerprint = $Fields[1].ToUpperInvariant()
    $ReportedPrimaryFingerprint = $Fields[-1].ToUpperInvariant()

    Write-Host "Signing fingerprint:          $SigningFingerprint"
    Write-Host "Reported primary fingerprint: $ReportedPrimaryFingerprint"
    Write-Host "Expected primary fingerprint: $ExpectedPrimaryFingerprint"

    if (
        $ReportedPrimaryFingerprint -ne
        $ExpectedPrimaryFingerprint
    ) {
        throw @"
$Description was signed by an unexpected primary key.

Expected:
$ExpectedPrimaryFingerprint

Reported:
$ReportedPrimaryFingerprint
"@
    }

    Write-Host "$Description verification PASSED." `
        -ForegroundColor Green
}

function Convert-WindowsPathToMSYS {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Resolved = [IO.Path]::GetFullPath($Path)

    if ($Resolved -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Cannot convert this Windows path to MSYS syntax: $Resolved"
    }

    $DriveLetter = $Matches[1].ToLowerInvariant()
    $Remainder = $Matches[2] -replace '\\', '/'

    return "/$DriveLetter/$Remainder"
}

function ConvertTo-BashSingleQuotedLiteral {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return "'" + $Value.Replace("'", "'\''") + "'"
}

function Invoke-UCRT64 {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [switch]$AllowNonZeroExit
    )

    $PreviousMSYSTEM = $env:MSYSTEM
    $PreviousCHERE = $env:CHERE_INVOKING
    $PreviousPathType = $env:MSYS2_PATH_TYPE

    try {
        $env:MSYSTEM = 'UCRT64'
        $env:CHERE_INVOKING = '1'
        $env:MSYS2_PATH_TYPE = 'inherit'

        & $BashPath --login -c $Command
        $ExitCode = $LASTEXITCODE
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

        if ($null -eq $PreviousPathType) {
            Remove-Item Env:\MSYS2_PATH_TYPE -ErrorAction SilentlyContinue
        }
        else {
            $env:MSYS2_PATH_TYPE = $PreviousPathType
        }
    }

    if (($ExitCode -ne 0) -and (-not $AllowNonZeroExit)) {
        throw "MSYS2 command failed with exit code ${ExitCode}: $Command"
    }

    return $ExitCode
}

# -----------------------------------------------------------------------------
# Check prerequisites
# -----------------------------------------------------------------------------

Write-Step 'Checking prerequisites'

$RequiredPaths = @(
    $DownloadDir
    $ManifestPath
    $ManifestSignaturePath
    $MSYS2Root
    $BashPath
    $TarPath
    $UCRT64Bin
)

foreach ($Path in $RequiredPaths) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required path is missing: $Path"
    }

    Write-Host "Found: $Path"
}

$Gpg = Get-GpgCommand

Write-Host "Using GPG: $($Gpg.Source)"

# -----------------------------------------------------------------------------
# Validate the installed Rust release key
# -----------------------------------------------------------------------------

Write-Step 'Validating the Rust release signing key'

$KeyOutput = @(
    & $Gpg.Source `
        --batch `
        --with-colons `
        --fingerprint `
        $ExpectedPrimaryFingerprint
)

if ($LASTEXITCODE -ne 0) {
    throw 'The expected Rust release signing key is unavailable.'
}

$ImportedFingerprint = Get-PrimaryFingerprint -GpgOutput $KeyOutput

if (-not $ImportedFingerprint) {
    throw 'Could not determine the Rust release-key fingerprint.'
}

Write-Host "Expected: $ExpectedPrimaryFingerprint"
Write-Host "Actual:   $ImportedFingerprint"

if ($ImportedFingerprint -ne $ExpectedPrimaryFingerprint) {
    throw 'The imported Rust signing-key fingerprint does not match.'
}

Write-Host 'Rust signing-key fingerprint verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Authenticate the stable manifest
# -----------------------------------------------------------------------------

Write-Step 'Re-authenticating the Rust stable manifest'

Invoke-GpgVerification `
    -Gpg $Gpg `
    -SignaturePath $ManifestSignaturePath `
    -SignedFilePath $ManifestPath `
    -Description 'Rust stable manifest'

# -----------------------------------------------------------------------------
# Read authenticated manifest metadata
# -----------------------------------------------------------------------------

Write-Step 'Reading authenticated release metadata'

$ManifestContent = Get-Content `
    -LiteralPath $ManifestPath `
    -Raw

if ([string]::IsNullOrWhiteSpace($ManifestContent)) {
    throw 'The authenticated stable manifest is empty.'
}

$VersionMatch = [regex]::Match(
    $ManifestContent,
    '(?ms)^\[pkg\.rust\].*?^version\s*=\s*"([^"]+)"'
)

if (-not $VersionMatch.Success) {
    throw 'Could not determine the stable Rust version.'
}

$VersionString = $VersionMatch.Groups[1].Value

$SemanticVersionMatch = [regex]::Match(
    $VersionString,
    '^\d+\.\d+\.\d+'
)

if (-not $SemanticVersionMatch.Success) {
    throw "Could not parse the Rust version from: $VersionString"
}

$RustVersion = $SemanticVersionMatch.Value

$EscapedTarget = [regex]::Escape($Target)

$TargetTableMatch = [regex]::Match(
    $ManifestContent,
    (
        '(?ms)^\[pkg\.rust\.target\.' +
        $EscapedTarget +
        '\]\s*(.*?)(?=^\[|\z)'
    )
)

if (-not $TargetTableMatch.Success) {
    throw "No authenticated target metadata was found for $Target."
}

$TargetTable = $TargetTableMatch.Groups[1].Value

$UrlMatch = [regex]::Match(
    $TargetTable,
    '(?m)^url\s*=\s*"([^"]+)"'
)

$HashMatch = [regex]::Match(
    $TargetTable,
    '(?m)^hash\s*=\s*"([0-9A-Fa-f]{64})"'
)

if (-not $UrlMatch.Success) {
    throw "No authenticated archive URL was found for $Target."
}

if (-not $HashMatch.Success) {
    throw "No authenticated SHA-256 was found for $Target."
}

$ArchiveUrl = $UrlMatch.Groups[1].Value
$ExpectedArchiveHash = $HashMatch.Groups[1].Value.ToLowerInvariant()
$ArchiveName = [IO.Path]::GetFileName(([uri]$ArchiveUrl).AbsolutePath)

$ArchivePath = Join-Path $DownloadDir $ArchiveName
$ArchiveSignaturePath = "$ArchivePath.asc"

Write-Host "Stable version:   $RustVersion"
Write-Host "Target:           $Target"
Write-Host "Archive:          $ArchivePath"
Write-Host "Expected SHA-256: $ExpectedArchiveHash"

foreach ($Path in @($ArchivePath, $ArchiveSignaturePath)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required Step 7 file is missing: $Path"
    }
}

# -----------------------------------------------------------------------------
# Reverify SHA-256
# -----------------------------------------------------------------------------

Write-Step 'Re-verifying the Rust archive SHA-256'

$ActualArchiveHash = (
    Get-FileHash `
        -LiteralPath $ArchivePath `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

Write-Host "Expected: $ExpectedArchiveHash"
Write-Host "Actual:   $ActualArchiveHash"

if ($ActualArchiveHash -cne $ExpectedArchiveHash) {
    throw 'The Rust archive SHA-256 does not match the authenticated manifest.'
}

Write-Host 'Rust archive SHA-256 verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Reverify archive signature
# -----------------------------------------------------------------------------

Write-Step 'Re-authenticating the Rust standalone archive'

Invoke-GpgVerification `
    -Gpg $Gpg `
    -SignaturePath $ArchiveSignaturePath `
    -SignedFilePath $ArchivePath `
    -Description 'Rust standalone archive'

# -----------------------------------------------------------------------------
# Refuse to overwrite an existing installation
# -----------------------------------------------------------------------------

Write-Step 'Checking the installation destination'

if (Test-Path -LiteralPath $InstallRoot) {
    throw @"
The Rust installation directory already exists. This script refuses to
overwrite or merge with an existing installation.
Move or remove it before rerunning Step 8.
"@
}

$InstallParent = Split-Path -Parent $InstallRoot

New-Item `
    -ItemType Directory `
    -Path $InstallParent `
    -Force |
Out-Null

$InstallParentItem = Get-Item -LiteralPath $InstallParent -Force

if (
    $InstallParentItem.Attributes -band
    [IO.FileAttributes]::ReparsePoint
) {
    throw "The install parent is a symlink or junction: $InstallParent"
}

if ($InstallRoot -match '\s') {
    throw "The Rust installation path contains spaces: $InstallRoot"
}

if ($InstallRoot -match '[^\x00-\x7F]') {
    throw "The Rust installation path contains non-ASCII characters."
}

Write-Host "Install destination: $InstallRoot"

# -----------------------------------------------------------------------------
# Extract the archive
# -----------------------------------------------------------------------------

Write-Step 'Extracting the authenticated Rust archive'

New-Item `
    -ItemType Directory `
    -Path $ExtractRootWindows `
    -ErrorAction Stop |
Out-Null

$ArchivePathMSYS = Convert-WindowsPathToMSYS -Path $ArchivePath
$ArchivePathBash = ConvertTo-BashSingleQuotedLiteral -Value $ArchivePathMSYS
$ExtractRootBash = ConvertTo-BashSingleQuotedLiteral -Value $ExtractRootMSYS

Invoke-UCRT64 -Command @"
set -e
tar -xzf $ArchivePathBash -C $ExtractRootBash
"@ | Out-Null

# Locate the one top-level extracted directory.
$ExtractedDirectories = @(
    Get-ChildItem `
        -LiteralPath $ExtractRootWindows `
        -Directory
)

if ($ExtractedDirectories.Count -ne 1) {
    throw @"
Expected exactly one extracted top-level directory, but found:

$($ExtractedDirectories.Count)
"@
}

$ExtractedInstallerRootWindows =
$ExtractedDirectories[0].FullName

$ExtractedInstallerRootMSYS =
Convert-WindowsPathToMSYS -Path $ExtractedInstallerRootWindows

$InstallScriptWindows = Join-Path `
    $ExtractedInstallerRootWindows `
    'install.sh'

$ExtractedInstallerRootBash = ConvertTo-BashSingleQuotedLiteral `
    -Value $ExtractedInstallerRootMSYS

$ComponentsFileWindows = Join-Path `
    $ExtractedInstallerRootWindows `
    'components'

if (-not (Test-Path -LiteralPath $InstallScriptWindows -PathType Leaf)) {
    throw "The extracted install.sh is missing: $InstallScriptWindows"
}

if (-not (Test-Path -LiteralPath $ComponentsFileWindows -PathType Leaf)) {
    throw "The extracted components list is missing."
}

Write-Host "Extracted root:   $ExtractedInstallerRootWindows"
Write-Host "Installer script: $InstallScriptWindows"

# -----------------------------------------------------------------------------
# Inspect extracted installer
# -----------------------------------------------------------------------------

Write-Step 'Inspecting the extracted Rust installer'

Write-Host
Write-Host 'Components:'

Get-Content -LiteralPath $ComponentsFileWindows |
ForEach-Object {
    Write-Host "  $_"
}

Write-Host
Write-Host 'Installer help:'

$HelpOutput = & {
    $PreviousMSYSTEM = $env:MSYSTEM
    $PreviousCHERE = $env:CHERE_INVOKING

    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'

    try {
        & $BashPath `
            --login `
            -c "cd $ExtractedInstallerRootBash && ./install.sh --help"
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
}

$HelpExitCode = $LASTEXITCODE

$HelpOutput | ForEach-Object {
    Write-Host $_
}

if ($HelpExitCode -ne 0) {
    throw "install.sh --help returned exit code $HelpExitCode."
}

$HelpText = $HelpOutput -join "`n"

if ($HelpText -notmatch '(?m)--prefix') {
    throw 'The extracted installer does not advertise a --prefix option.'
}

if ($HelpText -notmatch '(?m)--disable-ldconfig') {
    Write-Warning (
        'The installer does not advertise --disable-ldconfig. ' +
        'The script will omit that option.'
    )

    $SupportsDisableLdconfig = $false
}
else {
    $SupportsDisableLdconfig = $true
}

# -----------------------------------------------------------------------------
# Install into the user-owned prefix
# -----------------------------------------------------------------------------

Write-Step 'Installing Rust into the user-owned prefix'

$InstallRootMSYS = Convert-WindowsPathToMSYS -Path $InstallRoot
$InstallRootBash = ConvertTo-BashSingleQuotedLiteral -Value $InstallRootMSYS

$InstallArguments = @(
    './install.sh'
    "--prefix=$InstallRootBash"
)

if ($SupportsDisableLdconfig) {
    $InstallArguments += '--disable-ldconfig'
}

$InstallCommand = (
    "set -e; cd $ExtractedInstallerRootBash; " +
    ($InstallArguments -join ' ')
)

try {
    Invoke-UCRT64 -Command $InstallCommand | Out-Null
}
catch {
    if (Test-Path -LiteralPath $InstallRoot) {
        Write-Warning "Removing partial Rust installation: $InstallRoot"

        Remove-Item `
            -LiteralPath $InstallRoot `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    throw
}

# -----------------------------------------------------------------------------
# Verify installed files
# -----------------------------------------------------------------------------

Write-Step 'Checking installed Rust files'

$RustBin = Join-Path $InstallRoot 'bin'
$RustcPath = Join-Path $RustBin 'rustc.exe'
$CargoPath = Join-Path $RustBin 'cargo.exe'
$RustdocPath = Join-Path $RustBin 'rustdoc.exe'

foreach ($Path in @(
        $RustBin
        $RustcPath
        $CargoPath
        $RustdocPath
    )) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Expected installed Rust path is missing: $Path"
    }

    Write-Host "Found: $Path"
}

# -----------------------------------------------------------------------------
# Set process-local PATH only
# -----------------------------------------------------------------------------

Write-Step 'Preparing the process-local Rust environment'

$env:PATH = "$RustBin;$UCRT64Bin;$OriginalProcessPath"

Write-Host "Rust bin:   $RustBin"
Write-Host "UCRT64 bin: $UCRT64Bin"
Write-Host
Write-Host 'Only this PowerShell process PATH has been changed.'

# -----------------------------------------------------------------------------
# Verify tool versions and host
# -----------------------------------------------------------------------------

Write-Step 'Verifying Rust tools'

& $RustcPath --version
if ($LASTEXITCODE -ne 0) {
    throw 'rustc --version failed.'
}

& $CargoPath --version
if ($LASTEXITCODE -ne 0) {
    throw 'cargo --version failed.'
}

& $RustdocPath --version
if ($LASTEXITCODE -ne 0) {
    throw 'rustdoc --version failed.'
}

$VerboseVersion = @(& $RustcPath -vV)

if ($LASTEXITCODE -ne 0) {
    throw 'rustc -vV failed.'
}

$VerboseVersion | ForEach-Object {
    Write-Host $_
}

$HostLine = $VerboseVersion |
Where-Object {
    $_ -match '^host:\s+'
} |
Select-Object -First 1

if (-not $HostLine) {
    throw 'rustc did not report a host target.'
}

$DetectedHost = (
    $HostLine -replace '^host:\s+', ''
).Trim()

if ($DetectedHost -ne $Target) {
    throw @"
Unexpected Rust host.

Expected:
$Target

Actual:
$DetectedHost
"@
}

Write-Host 'Rust host verification PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify GCC linker availability
# -----------------------------------------------------------------------------

Write-Step 'Verifying the GNU linker environment'

$GccPath = Get-Command gcc.exe -ErrorAction SilentlyContinue
$LdPath = Get-Command ld.exe -ErrorAction SilentlyContinue

if (-not $GccPath) {
    throw 'gcc.exe is unavailable in the process-local PATH.'
}

if (-not $LdPath) {
    throw 'ld.exe is unavailable in the process-local PATH.'
}

Write-Host "GCC: $($GccPath.Source)"
Write-Host "LD:  $($LdPath.Source)"

& $GccPath.Source -dumpmachine

if ($LASTEXITCODE -ne 0) {
    throw 'gcc -dumpmachine failed.'
}

# -----------------------------------------------------------------------------
# Create Cargo test project
# -----------------------------------------------------------------------------

Write-Step 'Creating the Cargo test project'

New-Item `
    -ItemType Directory `
    -Path $TestRoot `
    -ErrorAction Stop |
Out-Null

Push-Location $TestRoot

try {
    & $CargoPath new `
        --bin `
        --vcs none `
        rust-standalone-test

    if ($LASTEXITCODE -ne 0) {
        throw 'cargo new failed.'
    }

    $ProjectRoot = Join-Path $TestRoot 'rust-standalone-test'
    $MainPath = Join-Path $ProjectRoot 'src\main.rs'

    $MainSource = @'
fn main() {
    println!("Rust standalone compiler test passed.");
    println!("Target OS: {}", std::env::consts::OS);
    println!("Target architecture: {}", std::env::consts::ARCH);
}
'@

    Set-Content `
        -LiteralPath $MainPath `
        -Value $MainSource `
        -Encoding utf8NoBOM

    Push-Location $ProjectRoot

    try {
        # ---------------------------------------------------------------------
        # Debug build
        # ---------------------------------------------------------------------

        Write-Step 'Building the Cargo debug project'

        & $CargoPath build

        if ($LASTEXITCODE -ne 0) {
            throw 'cargo build failed.'
        }

        $DebugExecutable = Join-Path `
            $ProjectRoot `
            'target\debug\rust-standalone-test.exe'

        if (-not (Test-Path -LiteralPath $DebugExecutable)) {
            throw "Debug executable is missing: $DebugExecutable"
        }

        Write-Step 'Running the Cargo debug executable'

        $DebugOutput = @(& $DebugExecutable)
        $DebugExitCode = $LASTEXITCODE

        $DebugOutput | ForEach-Object {
            Write-Host $_
        }

        if ($DebugExitCode -ne 0) {
            throw "Debug executable returned exit code $DebugExitCode."
        }

        if (
            ($DebugOutput -join "`n") -notmatch
            'Rust standalone compiler test passed\.'
        ) {
            throw 'Debug executable returned unexpected output.'
        }

        # ---------------------------------------------------------------------
        # Release build
        # ---------------------------------------------------------------------

        Write-Step 'Building the Cargo release project'

        & $CargoPath build --release

        if ($LASTEXITCODE -ne 0) {
            throw 'cargo build --release failed.'
        }

        $ReleaseExecutable = Join-Path `
            $ProjectRoot `
            'target\release\rust-standalone-test.exe'

        if (-not (Test-Path -LiteralPath $ReleaseExecutable)) {
            throw "Release executable is missing: $ReleaseExecutable"
        }

        Write-Step 'Running the Cargo release executable'

        $ReleaseOutput = @(& $ReleaseExecutable)
        $ReleaseExitCode = $LASTEXITCODE

        $ReleaseOutput | ForEach-Object {
            Write-Host $_
        }

        if ($ReleaseExitCode -ne 0) {
            throw "Release executable returned exit code $ReleaseExitCode."
        }

        # ---------------------------------------------------------------------
        # Inspect native executable format
        # ---------------------------------------------------------------------

        Write-Step 'Inspecting the native executable format'

        $ReleaseExecutableMSYS = Convert-WindowsPathToMSYS `
            -Path $ReleaseExecutable

        $FileOutput = & {
            $PreviousMSYSTEM = $env:MSYSTEM
            $PreviousCHERE = $env:CHERE_INVOKING

            $env:MSYSTEM = 'UCRT64'
            $env:CHERE_INVOKING = '1'

            try {
                & $BashPath `
                    --login `
                    -c "file $(ConvertTo-BashSingleQuotedLiteral -Value $ReleaseExecutableMSYS)"
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
        }

        if ($LASTEXITCODE -ne 0) {
            throw 'Executable format inspection failed.'
        }

        $FileOutput | ForEach-Object {
            Write-Host $_
        }

        $FileText = $FileOutput -join "`n"

        if ($FileText -notmatch 'PE32\+') {
            throw 'The Rust executable was not reported as PE32+.'
        }

        if ($FileText -notmatch 'x86-64') {
            throw 'The Rust executable was not reported as x86-64.'
        }

        Write-Host 'Native executable verification PASSED.' `
            -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}
finally {
    Pop-Location
}

# -----------------------------------------------------------------------------
# Confirm persistent PATH was not modified
# -----------------------------------------------------------------------------

Write-Step 'Checking persistent Windows PATH values'

$PersistentUserPath = [Environment]::GetEnvironmentVariable(
    'Path',
    [EnvironmentVariableTarget]::User
)

$PersistentMachinePath = [Environment]::GetEnvironmentVariable(
    'Path',
    [EnvironmentVariableTarget]::Machine
)

$EscapedRustBin = [regex]::Escape($RustBin)

if (
    $PersistentUserPath -and
    $PersistentUserPath -match $EscapedRustBin
) {
    Write-Warning 'Rust bin was already present in the persistent user PATH.'
}
else {
    Write-Host 'Rust bin is not in the persistent user PATH.'
}

if (
    $PersistentMachinePath -and
    $PersistentMachinePath -match $EscapedRustBin
) {
    Write-Warning 'Rust bin was already present in the machine PATH.'
}
else {
    Write-Host 'Rust bin is not in the persistent machine PATH.'
}

# -----------------------------------------------------------------------------
# Write installation record
# -----------------------------------------------------------------------------

Write-Step 'Writing the Rust installation record'

$InstallRecordPath = Join-Path `
    $InstallRoot `
    'INSTALLATION.txt'

$InstallRecord = @"
Rust standalone installation record

Version:
$RustVersion

Host:
$DetectedHost

Install root:
$InstallRoot

Authenticated archive:
$ArchivePath

Archive SHA256:
$ActualArchiveHash

Rust release-key fingerprint:
$ExpectedPrimaryFingerprint

Manifest signature verified:
True

Archive signature verified:
True

Archive SHA256 verified:
True

Cargo debug build:
Passed

Cargo release build:
Passed

Native executable:
PE32+ x86-64

Persistent PATH modified:
False

Rustup installed:
False
"@

Set-Content `
    -LiteralPath $InstallRecordPath `
    -Value $InstallRecord `
    -Encoding utf8NoBOM

Write-Host "Installation record:"
Write-Host "  $InstallRecordPath"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' STEP 8 COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host 'Rust installation:'
Write-Host "  $InstallRoot"

Write-Host
Write-Host "Rust version:             $RustVersion"
Write-Host "Rust host:                $DetectedHost"

Write-Host
Write-Host 'Signing key fingerprint: VERIFIED' `
    -ForegroundColor Green

Write-Host 'Manifest signature:      VERIFIED' `
    -ForegroundColor Green

Write-Host 'Archive SHA-256:         VERIFIED' `
    -ForegroundColor Green

Write-Host 'Archive signature:       VERIFIED' `
    -ForegroundColor Green

Write-Host 'Rust installation:       COMPLETE' `
    -ForegroundColor Green

Write-Host 'Cargo debug build:       PASSED' `
    -ForegroundColor Green

Write-Host 'Cargo release build:     PASSED' `
    -ForegroundColor Green

Write-Host 'PE32+ x86-64 executable: VERIFIED' `
    -ForegroundColor Green

Write-Host
Write-Host 'Rustup was not installed.'
Write-Host 'Persistent Windows PATH was not modified.'
Write-Host
Write-Host 'Rust is available in this PowerShell session via:'
Write-Host "  $RustBin"