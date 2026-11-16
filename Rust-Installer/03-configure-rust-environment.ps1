#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Configure the verified standalone Rust installation for everyday use.
#
# This script:
#   1. Verifies the Rust and MSYS2/MinGW installations.
#   2. Backs up the current persistent user PATH.
#   3. Adds Rust and UCRT64 to the persistent user PATH.
#   4. Removes duplicate PATH entries.
#   5. Does not modify the machine PATH.
#   6. Refreshes the current PowerShell process PATH.
#   7. Verifies Rust, Cargo, GCC, and the GNU linker.
#   8. Builds and runs a new Cargo project from ordinary PowerShell.
#
# Persistent entries added:
#   C:\Users\danie\.local\rust\bin
#   C:\Users\danie\msys64\ucrt64\bin
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$RustRoot = Join-Path $HOME '.local\rust'
$RustBin = Join-Path $RustRoot 'bin'

$MSYS2Root = Join-Path $HOME 'msys64'
$UCRT64Bin = Join-Path $MSYS2Root 'ucrt64\bin'

$RustcPath = Join-Path $RustBin 'rustc.exe'
$CargoPath = Join-Path $RustBin 'cargo.exe'
$RustdocPath = Join-Path $RustBin 'rustdoc.exe'

$GccPath = Join-Path $UCRT64Bin 'gcc.exe'
$GppPath = Join-Path $UCRT64Bin 'g++.exe'
$LdPath = Join-Path $UCRT64Bin 'ld.exe'

$ExpectedRustHost = 'x86_64-pc-windows-gnu'
$ExpectedGccTarget = 'x86_64-w64-mingw32'

$TestRoot = Join-Path $env:TEMP (
    'rust-persistent-path-test-' + [guid]::NewGuid().ToString('N')
)

$BackupDirectory = Join-Path $RustRoot 'environment-backups'

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

function Get-NormalizedPathEntry {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $ExpandedPath = [Environment]::ExpandEnvironmentVariables(
        $Path.Trim().Trim('"')
    )

    if ([string]::IsNullOrWhiteSpace($ExpandedPath)) {
        return $null
    }

    try {
        return [IO.Path]::GetFullPath(
            $ExpandedPath
        ).TrimEnd('\')
    }
    catch {
        return $ExpandedPath.TrimEnd('\')
    }
}

function Get-UniquePathEntries {
    param(
        [AllowNull()]
        [string]$PathValue
    )

    $Results = [Collections.Generic.List[string]]::new()
    $Seen = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return @()
    }

    foreach ($Entry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($Entry)) {
            continue
        }

        $TrimmedEntry = $Entry.Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($TrimmedEntry)) {
            continue
        }

        $NormalizedEntry = Get-NormalizedPathEntry -Path $TrimmedEntry

        if (
            $NormalizedEntry -and
            $Seen.Add($NormalizedEntry)
        ) {
            $Results.Add($TrimmedEntry)
        }
    }

    return $Results.ToArray()
}

function Test-PathEntryEquals {
    param(
        [Parameter(Mandatory)]
        [string]$First,

        [Parameter(Mandatory)]
        [string]$Second
    )

    $NormalizedFirst = Get-NormalizedPathEntry -Path $First
    $NormalizedSecond = Get-NormalizedPathEntry -Path $Second

    return [string]::Equals(
        $NormalizedFirst,
        $NormalizedSecond,
        [StringComparison]::OrdinalIgnoreCase
    )
}

# -----------------------------------------------------------------------------
# Verify installation files
# -----------------------------------------------------------------------------

Write-Step 'Checking the Rust and MSYS2 installations'

$RequiredFiles = [ordered]@{
    'Rust installation root' = $RustRoot
    'Rust bin directory'     = $RustBin
    'rustc'                  = $RustcPath
    'cargo'                  = $CargoPath
    'rustdoc'                = $RustdocPath
    'MSYS2 installation'     = $MSYS2Root
    'UCRT64 bin directory'   = $UCRT64Bin
    'GCC'                    = $GccPath
    'G++'                    = $GppPath
    'GNU linker'             = $LdPath
}

foreach ($Item in $RequiredFiles.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $Item.Value)) {
        throw "Missing $($Item.Key): $($Item.Value)"
    }

    Write-Host "Found $($Item.Key): $($Item.Value)"
}

# -----------------------------------------------------------------------------
# Confirm installation paths are normal directories
# -----------------------------------------------------------------------------

Write-Step 'Checking installation path safety'

foreach ($Directory in @($RustRoot, $MSYS2Root)) {
    $Item = Get-Item -LiteralPath $Directory -Force

    if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "The installation path is a symlink or junction: $Directory"
    }

    Write-Host "Normal directory: $Directory"
}

# -----------------------------------------------------------------------------
# Verify Rust before changing PATH
# -----------------------------------------------------------------------------

Write-Step 'Verifying the installed Rust toolchain'

$RustVerboseVersion = @(& $RustcPath -vV)

if ($LASTEXITCODE -ne 0) {
    throw 'rustc -vV failed before PATH configuration.'
}

$RustVerboseVersion | ForEach-Object {
    Write-Host $_
}

$RustHostLine = $RustVerboseVersion |
    Where-Object {
        $_ -match '^host:\s+'
    } |
    Select-Object -First 1

if (-not $RustHostLine) {
    throw 'rustc did not report its host target.'
}

$RustHost = (
    $RustHostLine -replace '^host:\s+', ''
).Trim()

if ($RustHost -ne $ExpectedRustHost) {
    throw @"
Unexpected Rust host.

Expected:
$ExpectedRustHost

Actual:
$RustHost
"@
}

Write-Host 'Rust host verification PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify GCC before changing PATH
# -----------------------------------------------------------------------------

Write-Step 'Verifying the installed GNU toolchain'

$GccTarget = (& $GccPath -dumpmachine | Select-Object -First 1).Trim()

if ($LASTEXITCODE -ne 0) {
    throw 'gcc -dumpmachine failed before PATH configuration.'
}

Write-Host "GCC target: $GccTarget"

if ($GccTarget -ne $ExpectedGccTarget) {
    throw @"
Unexpected GCC target.

Expected:
$ExpectedGccTarget

Actual:
$GccTarget
"@
}

Write-Host 'GCC target verification PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Read current persistent PATH values
# -----------------------------------------------------------------------------

Write-Step 'Reading persistent Windows PATH values'

$OriginalUserPath = [Environment]::GetEnvironmentVariable(
    'Path',
    [EnvironmentVariableTarget]::User
)

$MachinePath = [Environment]::GetEnvironmentVariable(
    'Path',
    [EnvironmentVariableTarget]::Machine
)

if ($null -eq $OriginalUserPath) {
    $OriginalUserPath = ''
}

if ($null -eq $MachinePath) {
    $MachinePath = ''
}

Write-Host "Current user PATH length:    $($OriginalUserPath.Length)"
Write-Host "Current machine PATH length: $($MachinePath.Length)"

# -----------------------------------------------------------------------------
# Back up the original persistent user PATH
# -----------------------------------------------------------------------------

Write-Step 'Backing up the persistent user PATH'

New-Item `
    -ItemType Directory `
    -Path $BackupDirectory `
    -Force |
    Out-Null

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupId = [guid]::NewGuid().ToString('N')

$BackupPath = Join-Path `
    $BackupDirectory `
    "user-path-before-rust-$Timestamp-$BackupId.txt"

$BackupContent = @"
Persistent user PATH backup

Created:
$((Get-Date).ToString('o'))

Computer:
$env:COMPUTERNAME

User:
$env:USERNAME

Original user PATH:
$OriginalUserPath
"@

Set-Content `
    -LiteralPath $BackupPath `
    -Value $BackupContent `
    -Encoding utf8NoBOM

Write-Host "Backup: $BackupPath"

# -----------------------------------------------------------------------------
# Build the new user PATH
#
# Rust comes first so rustc/cargo resolve predictably.
# UCRT64 follows so rustc can locate GCC, ld, and runtime libraries.
# Existing user entries retain their original order after those entries.
# -----------------------------------------------------------------------------

Write-Step 'Building the updated persistent user PATH'

$ExistingEntries = @(
    Get-UniquePathEntries -PathValue $OriginalUserPath
)

$PreservedEntries = foreach ($Entry in $ExistingEntries) {
    $IsRustEntry = Test-PathEntryEquals `
        -First $Entry `
        -Second $RustBin

    $IsUCRT64Entry = Test-PathEntryEquals `
        -First $Entry `
        -Second $UCRT64Bin

    if (-not $IsRustEntry -and -not $IsUCRT64Entry) {
        $Entry
    }
}

$NewUserEntries = @(
    $RustBin
    $UCRT64Bin
    $PreservedEntries
)

$NewUserEntries = @(
    Get-UniquePathEntries -PathValue (
        $NewUserEntries -join ';'
    )
)

$NewUserPath = $NewUserEntries -join ';'

Write-Host
Write-Host 'Entries being placed first:'
Write-Host "  $RustBin"
Write-Host "  $UCRT64Bin"

Write-Host
Write-Host "New user PATH length: $($NewUserPath.Length)"

# -----------------------------------------------------------------------------
# Persist the user PATH
# -----------------------------------------------------------------------------

Write-Step 'Writing the persistent user PATH'

try {
    [Environment]::SetEnvironmentVariable(
        'Path',
        $NewUserPath,
        [EnvironmentVariableTarget]::User
    )
}
catch {
    throw "Failed to write the persistent user PATH: $($_.Exception.Message)"
}

$StoredUserPath = [Environment]::GetEnvironmentVariable(
    'Path',
    [EnvironmentVariableTarget]::User
)

$StoredUserEntries = @(
    Get-UniquePathEntries -PathValue $StoredUserPath
)

$UserPathMatches = $StoredUserEntries.Count -eq $NewUserEntries.Count

if ($UserPathMatches) {
    for ($Index = 0; $Index -lt $NewUserEntries.Count; $Index++) {
        if (
            -not (Test-PathEntryEquals `
                -First $StoredUserEntries[$Index] `
                -Second $NewUserEntries[$Index])
        ) {
            $UserPathMatches = $false
            break
        }
    }
}

if (-not $UserPathMatches) {
    throw 'The persistent user PATH does not match the value that was written.'
}

Write-Host 'Persistent user PATH updated successfully.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Confirm machine PATH remained unchanged
# -----------------------------------------------------------------------------

Write-Step 'Confirming the machine PATH was not changed'

$MachinePathAfter = [Environment]::GetEnvironmentVariable(
    'Path',
    [EnvironmentVariableTarget]::Machine
)

if ($MachinePathAfter -cne $MachinePath) {
    throw @'
The machine PATH changed unexpectedly.

This script did not intentionally write to the machine PATH.
'@
}

Write-Host 'Machine PATH is unchanged.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Refresh current process PATH
#
# A fresh process normally receives combined machine and user PATH values.
# Refresh this process manually so verification works immediately.
# -----------------------------------------------------------------------------

Write-Step 'Refreshing the current PowerShell process PATH'

$ProcessEntries = @(
    Get-UniquePathEntries -PathValue (
        @(
            $RustBin
            $UCRT64Bin
            $env:PATH
            $MachinePath
            $NewUserPath
        ) -join ';'
    )
)

$env:PATH = $ProcessEntries -join ';'

Write-Host 'Current PowerShell process PATH refreshed.'

# -----------------------------------------------------------------------------
# Resolve commands from ordinary PowerShell
# -----------------------------------------------------------------------------

Write-Step 'Resolving development commands from PowerShell'

$ExpectedCommands = [ordered]@{
    'rustc.exe'  = $RustcPath
    'cargo.exe'  = $CargoPath
    'rustdoc.exe' = $RustdocPath
    'gcc.exe'    = $GccPath
    'g++.exe'    = $GppPath
    'ld.exe'     = $LdPath
}

foreach ($CommandEntry in $ExpectedCommands.GetEnumerator()) {
    $ResolvedCommand = Get-Command `
        $CommandEntry.Key `
        -CommandType Application `
        -ErrorAction Stop |
        Select-Object -First 1

    $ActualSource = [IO.Path]::GetFullPath(
        $ResolvedCommand.Source
    )

    $ExpectedSource = [IO.Path]::GetFullPath(
        $CommandEntry.Value
    )

    Write-Host "$($CommandEntry.Key): $ActualSource"

    if (
        -not [string]::Equals(
            $ActualSource,
            $ExpectedSource,
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw @"
Unexpected command resolution for $($CommandEntry.Key).

Expected:
$ExpectedSource

Actual:
$ActualSource
"@
    }
}

Write-Host
Write-Host 'Command resolution verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Show versions
# -----------------------------------------------------------------------------

Write-Step 'Displaying installed versions'

& rustc.exe --version
if ($LASTEXITCODE -ne 0) {
    throw 'rustc --version failed.'
}

& cargo.exe --version
if ($LASTEXITCODE -ne 0) {
    throw 'cargo --version failed.'
}

& rustdoc.exe --version
if ($LASTEXITCODE -ne 0) {
    throw 'rustdoc --version failed.'
}

& gcc.exe --version |
    Select-Object -First 1

if ($LASTEXITCODE -ne 0) {
    throw 'gcc --version failed.'
}

& ld.exe --version |
    Select-Object -First 1

if ($LASTEXITCODE -ne 0) {
    throw 'ld --version failed.'
}

# -----------------------------------------------------------------------------
# Create a fresh standalone Cargo test
# -----------------------------------------------------------------------------

Write-Step 'Creating a fresh Cargo project from ordinary PowerShell'

New-Item `
    -ItemType Directory `
    -Path $TestRoot `
    -Force |
    Out-Null

Push-Location $TestRoot

try {
    & cargo.exe new `
        --bin `
        --vcs none `
        persistent-path-test

    if ($LASTEXITCODE -ne 0) {
        throw 'cargo new failed.'
    }

    $ProjectRoot = Join-Path $TestRoot 'persistent-path-test'
    $MainPath = Join-Path $ProjectRoot 'src\main.rs'

    $SourceCode = @'
fn main() {
    println!("Persistent Rust environment test passed.");
    println!("OS: {}", std::env::consts::OS);
    println!("Architecture: {}", std::env::consts::ARCH);
}
'@

    Set-Content `
        -LiteralPath $MainPath `
        -Value $SourceCode `
        -Encoding utf8NoBOM

    Push-Location $ProjectRoot

    try {
        # ---------------------------------------------------------------------
        # Release build
        # ---------------------------------------------------------------------

        Write-Step 'Building the release project from ordinary PowerShell'

        & cargo.exe build --release

        if ($LASTEXITCODE -ne 0) {
            throw 'cargo build --release failed.'
        }

        $ExecutablePath = Join-Path `
            $ProjectRoot `
            'target\release\persistent-path-test.exe'

        if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
            throw "Cargo did not create the expected executable: $ExecutablePath"
        }

        # ---------------------------------------------------------------------
        # Run executable
        # ---------------------------------------------------------------------

        Write-Step 'Running the release executable'

        $ProgramOutput = @(& $ExecutablePath)
        $ProgramExitCode = $LASTEXITCODE

        $ProgramOutput | ForEach-Object {
            Write-Host $_
        }

        if ($ProgramExitCode -ne 0) {
            throw "The Rust program returned exit code $ProgramExitCode."
        }

        $ProgramText = $ProgramOutput -join "`n"

        if (
            $ProgramText -notmatch
            'Persistent Rust environment test passed\.'
        ) {
            throw 'The Rust program did not return its expected output.'
        }

        if ($ProgramText -notmatch '(?m)^OS: windows$') {
            throw 'The Rust program did not report Windows.'
        }

        if ($ProgramText -notmatch '(?m)^Architecture: x86_64$') {
            throw 'The Rust program did not report x86_64.'
        }

        Write-Host
        Write-Host 'Cargo release execution test PASSED.' `
            -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}
finally {
    Pop-Location

    if (Test-Path -LiteralPath $TestRoot) {
        Remove-Item `
            -LiteralPath $TestRoot `
            -Recurse `
            -Force
    }
}

# -----------------------------------------------------------------------------
# Verify what a clean child PowerShell process sees
# -----------------------------------------------------------------------------

Write-Step 'Testing command visibility in a child PowerShell process'

$CurrentPwsh = (Get-Process -Id $PID).Path

$ChildCheck = @'
$commands = 'rustc.exe', 'cargo.exe', 'gcc.exe', 'ld.exe'

foreach ($command in $commands) {
    $resolved = Get-Command $command -CommandType Application -ErrorAction Stop |
        Select-Object -First 1

    '{0}={1}' -f $command, $resolved.Source
}

rustc.exe -vV
'@

$ChildOutput = @(
    & $CurrentPwsh `
        -NoLogo `
        -NoProfile `
        -Command $ChildCheck
)

$ChildExitCode = $LASTEXITCODE

$ChildOutput | ForEach-Object {
    Write-Host $_
}

if ($ChildExitCode -ne 0) {
    throw 'The child PowerShell environment test failed.'
}

if (
    ($ChildOutput -join "`n") -notmatch
    'host:\s+x86_64-pc-windows-gnu'
) {
    throw 'The child PowerShell did not report the expected Rust host.'
}

Write-Host
Write-Host 'Child PowerShell environment test PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Write configuration record
# -----------------------------------------------------------------------------

Write-Step 'Writing the environment configuration record'

$ConfigurationRecordPath = Join-Path `
    $RustRoot `
    'ENVIRONMENT.txt'

$ConfigurationRecord = @"
Rust environment configuration

Configured:
$((Get-Date).ToString('o'))

Rust bin:
$RustBin

UCRT64 bin:
$UCRT64Bin

Rust host:
$RustHost

GCC target:
$GccTarget

Persistent user PATH modified:
True

Persistent machine PATH modified:
False

Original user PATH backup:
$BackupPath

Cargo release build:
Passed

Cargo release execution:
Passed

Child PowerShell verification:
Passed
"@

Set-Content `
    -LiteralPath $ConfigurationRecordPath `
    -Value $ConfigurationRecord `
    -Encoding utf8NoBOM

Write-Host "Configuration record:"
Write-Host "  $ConfigurationRecordPath"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' RUST ENVIRONMENT CONFIGURATION COMPLETE' `
    -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host 'Persistent user PATH entries:'
Write-Host "  $RustBin"
Write-Host "  $UCRT64Bin"

Write-Host
Write-Host 'Rust host:'
Write-Host "  $RustHost"

Write-Host
Write-Host 'GCC target:'
Write-Host "  $GccTarget"

Write-Host
Write-Host 'User PATH:                UPDATED' `
    -ForegroundColor Green
Write-Host 'Machine PATH:             UNCHANGED' `
    -ForegroundColor Green
Write-Host 'Command resolution:       VERIFIED' `
    -ForegroundColor Green
Write-Host 'Cargo release build:      PASSED' `
    -ForegroundColor Green
Write-Host 'Cargo executable:         PASSED' `
    -ForegroundColor Green
Write-Host 'Child PowerShell session: PASSED' `
    -ForegroundColor Green

Write-Host
Write-Host 'Original user PATH backup:'
Write-Host "  $BackupPath"

Write-Host
Write-Host 'Close and reopen PowerShell, CMD, Windows Terminal, and VS Code'
Write-Host 'so each application receives the updated user PATH.'