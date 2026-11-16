#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 5: Update MSYS2 and install the UCRT64 GCC toolchain
#
# This script:
#   1. Verifies the existing MSYS2 installation.
#   2. Performs a full MSYS2 system update.
#   3. Repeats the update to complete any post-core-update work.
#   4. Installs the UCRT64 GCC toolchain group, GNU Make, and pkgconf.
#   5. Verifies the compiler, linker, binutils, Make, and pkg-config.
#   6. Builds and runs native Windows C and C++ test programs.
#   7. Confirms the generated executables are PE32+ x86-64 binaries.
#
# This script DOES NOT:
#   - Require administrator privileges.
#   - Modify the Windows system or user PATH.
#   - Install Rust.
#   - Modify Git for Windows.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

$MSYS2Root = Join-Path $HOME 'msys64'
$BashPath = Join-Path $MSYS2Root 'usr\bin\bash.exe'
$PacmanPath = Join-Path $MSYS2Root 'usr\bin\pacman.exe'
$UCRT64Bin = Join-Path $MSYS2Root 'ucrt64\bin'

$ToolchainGroup = 'mingw-w64-ucrt-x86_64-toolchain'
$AdditionalBuildPackages = @(
    'make'
    'mingw-w64-ucrt-x86_64-pkgconf'
)

$TestRootWindows = Join-Path $env:TEMP 'msys2-gcc-test'
$TestRootMSYS = '/tmp/msys2-gcc-test'

# Number of complete update passes.
#
# The first pass may update the MSYS2 core. The second pass completes the
# remaining package updates. A third pass verifies that no further update work
# remains.
$MaximumUpdatePasses = 3

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

function Invoke-MSYS2 {
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [switch]$AllowNonZeroExit
    )

    $PreviousMSYSTEM = $env:MSYSTEM
    $PreviousCHERE = $env:CHERE_INVOKING
    $PreviousMSYS2PathType = $env:MSYS2_PATH_TYPE

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

        if ($null -eq $PreviousMSYS2PathType) {
            Remove-Item Env:\MSYS2_PATH_TYPE -ErrorAction SilentlyContinue
        }
        else {
            $env:MSYS2_PATH_TYPE = $PreviousMSYS2PathType
        }
    }

    if (($ExitCode -ne 0) -and (-not $AllowNonZeroExit)) {
        throw "The MSYS2 command failed with exit code ${ExitCode}: $Command"
    }

    return $ExitCode
}

function Test-RequiredPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing $Description`: $Path"
    }

    Write-Host "Found $Description`: $Path"
}

function Test-CommandInMSYS2 {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    Invoke-MSYS2 -Command "command -v '$CommandName' >/dev/null 2>&1"

    Write-Host "Found command: $CommandName"
}

# -----------------------------------------------------------------------------
# Verify installation layout
# -----------------------------------------------------------------------------

Write-Step 'Checking the MSYS2 installation'

Test-RequiredPath `
    -Path $MSYS2Root `
    -Description 'MSYS2 root'

Test-RequiredPath `
    -Path $BashPath `
    -Description 'MSYS2 Bash'

Test-RequiredPath `
    -Path $PacmanPath `
    -Description 'Pacman'

Test-RequiredPath `
    -Path $UCRT64Bin `
    -Description 'UCRT64 bin directory'

# -----------------------------------------------------------------------------
# Verify UCRT64 environment
# -----------------------------------------------------------------------------

Write-Step 'Checking the UCRT64 shell environment'

$EnvironmentOutput = & {
    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'

    try {
        & $BashPath `
            --login `
            -c 'printf "MSYSTEM=%s\nMINGW_PREFIX=%s\nPATH_HEAD=%s\n" "$MSYSTEM" "$MINGW_PREFIX" "${PATH%%:*}"'
    }
    finally {
        Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
        Remove-Item Env:\CHERE_INVOKING -ErrorAction SilentlyContinue
    }
}

if ($LASTEXITCODE -ne 0) {
    throw 'The UCRT64 environment check failed.'
}

$EnvironmentOutput | ForEach-Object {
    Write-Host $_
}

$EnvironmentText = $EnvironmentOutput -join "`n"

if ($EnvironmentText -notmatch '(?m)^MSYSTEM=UCRT64$') {
    throw 'The MSYS2 shell did not report MSYSTEM=UCRT64.'
}

if ($EnvironmentText -notmatch '(?m)^MINGW_PREFIX=/ucrt64$') {
    throw 'The MSYS2 shell did not report MINGW_PREFIX=/ucrt64.'
}

if ($EnvironmentText -notmatch '(?m)^PATH_HEAD=/ucrt64/bin$') {
    throw 'The UCRT64 bin directory is not first in the MSYS2 PATH.'
}

Write-Host 'UCRT64 environment verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Update MSYS2
# -----------------------------------------------------------------------------

Write-Step 'Updating MSYS2'

for ($Pass = 1; $Pass -le $MaximumUpdatePasses; $Pass++) {
    Write-Host
    Write-Host "MSYS2 update pass $Pass of $MaximumUpdatePasses" `
        -ForegroundColor Yellow

    # A core MSYS2 runtime update may close or restart the invoking shell.
    # We therefore permit a nonzero result here and start a fresh shell for
    # the next pass. The final package-state check below determines success.

    $UpdateExitCode = Invoke-MSYS2 `
        -Command 'pacman --noconfirm -Syu' `
        -AllowNonZeroExit

    Write-Host "Update pass exit code: $UpdateExitCode"

    Start-Sleep -Seconds 2
}

# -----------------------------------------------------------------------------
# Verify that no package upgrades remain
# -----------------------------------------------------------------------------

Write-Step 'Checking for remaining package upgrades'

$RemainingUpdates = $null
$UpgradeCheckExitCode = $null

& {
    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'

    try {
        $RemainingUpdates = & $BashPath `
            --login `
            -c 'pacman -Qu'

        $UpgradeCheckExitCode = $LASTEXITCODE
    }
    finally {
        Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
        Remove-Item Env:\CHERE_INVOKING -ErrorAction SilentlyContinue
    }
} | Write-Output

# pacman -Qu may return 0 when upgrades exist and 1 when none exist.
# We determine the state from whether package lines were returned.

$RemainingUpdateLines = @(
    $RemainingUpdates |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }
)

if ($RemainingUpdateLines.Count -gt 0) {
    Write-Host
    Write-Host 'The following package upgrades remain:' `
        -ForegroundColor Red

    $RemainingUpdateLines | ForEach-Object {
        Write-Host $_
    }

    throw @'
MSYS2 is not fully updated after the allowed update passes.

Close any open MSYS2 terminals and rerun this script.
'@
}

Write-Host 'MSYS2 is fully updated.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Install the UCRT64 GCC toolchain group
# -----------------------------------------------------------------------------

Write-Step "Installing $ToolchainGroup"

$PackagesToInstall = @(
    $ToolchainGroup
    $AdditionalBuildPackages
)

$InstallCommand = (
    'pacman --noconfirm --needed -S ' +
    ($PackagesToInstall -join ' ')
)

Invoke-MSYS2 -Command $InstallCommand

Write-Host
Write-Host 'UCRT64 GCC toolchain installation completed.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Verify package installation
# -----------------------------------------------------------------------------

Write-Step 'Verifying installed toolchain packages'

Invoke-MSYS2 `
    -Command "pacman -Q '$ToolchainGroup' >/dev/null 2>&1" `
    -AllowNonZeroExit |
Out-Null

# A pacman group is not necessarily represented as one installed package.
# Verify the critical packages individually.

$RequiredPackages = @(
    'mingw-w64-ucrt-x86_64-binutils'
    'mingw-w64-ucrt-x86_64-gcc'
    'mingw-w64-ucrt-x86_64-crt'
    'mingw-w64-ucrt-x86_64-headers'
    'mingw-w64-ucrt-x86_64-libwinpthread'
    'mingw-w64-ucrt-x86_64-winpthreads'
    'make'
    'mingw-w64-ucrt-x86_64-pkgconf'
)

foreach ($Package in $RequiredPackages) {
    Invoke-MSYS2 -Command "pacman -Q '$Package'"

    Write-Host "Verified package: $Package"
}

# -----------------------------------------------------------------------------
# Verify commands
# -----------------------------------------------------------------------------

Write-Step 'Verifying compiler and build commands'

$RequiredCommands = @(
    'gcc'
    'g++'
    'ld'
    'ar'
    'ranlib'
    'windres'
    'objdump'
    'strip'
    'make'
)

foreach ($CommandName in $RequiredCommands) {
    Test-CommandInMSYS2 -CommandName $CommandName
}

Write-Step 'Verifying pkg-config'

$PkgConfigExitCode = Invoke-MSYS2 `
    -Command 'command -v pkg-config >/dev/null 2>&1 || command -v pkgconf >/dev/null 2>&1' `
    -AllowNonZeroExit

if ($PkgConfigExitCode -ne 0) {
    throw 'Neither pkg-config nor pkgconf is available in the UCRT64 environment.'
}

Write-Host 'Found pkg-config or pkgconf.'

# -----------------------------------------------------------------------------
# Display versions and compiler target
# -----------------------------------------------------------------------------

Write-Step 'Displaying toolchain versions'

Invoke-MSYS2 -Command @'
printf '%s\n' '--- GCC ---'
gcc --version | head -n 1

printf '%s\n' '--- G++ ---'
g++ --version | head -n 1

printf '%s\n' '--- Binutils linker ---'
ld --version | head -n 1

printf '%s\n' '--- GCC target ---'
gcc -dumpmachine

printf '%s\n' '--- GCC search directories ---'
gcc -print-search-dirs
'@

$CompilerTarget = & {
    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'

    try {
        & $BashPath `
            --login `
            -c 'gcc -dumpmachine'
    }
    finally {
        Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
        Remove-Item Env:\CHERE_INVOKING -ErrorAction SilentlyContinue
    }
}

if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the GCC target.'
}

$CompilerTarget = ($CompilerTarget | Select-Object -First 1).Trim()

Write-Host "Detected compiler target: $CompilerTarget"

if ($CompilerTarget -notmatch 'x86_64.*mingw32') {
    throw @"
Unexpected GCC target:

$CompilerTarget

Expected an x86-64 MinGW Windows target.
"@
}

Write-Host 'GCC target verification PASSED.' -ForegroundColor Green

# ----
# Create test sources
# ----

Write-Step 'Creating compiler test sources'

if (Test-Path -LiteralPath $TestRootWindows) {
    Remove-Item `
        -LiteralPath $TestRootWindows `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $TestRootWindows `
    -Force |
Out-Null

$CTestSource = @'
#include <stdio.h>
#include <windows.h>

int main(void) {
    printf("C compiler test passed.\n");
    printf("Windows major version: %lu\n",
           (unsigned long)LOBYTE(LOWORD(GetVersion())));
    return 0;
}
'@

$CppTestSource = @'
#include <iostream>
#include <string>

int main() {
    const std::string message = "C++ compiler test passed.";
    std::cout << message << '\n';
    return 0;
}
'@

Set-Content `
    -LiteralPath (Join-Path $TestRootWindows 'test.c') `
    -Value $CTestSource `
    -Encoding utf8NoBOM

Set-Content `
    -LiteralPath (Join-Path $TestRootWindows 'test.cpp') `
    -Value $CppTestSource `
    -Encoding utf8NoBOM

Write-Host "Test directory: $TestRootWindows"

# -----------------------------------------------------------------------------
# Copy source files into the MSYS2 temporary directory
# -----------------------------------------------------------------------------

Write-Step 'Preparing the MSYS2 test directory'

Invoke-MSYS2 -Command @"
rm -rf '$TestRootMSYS'
mkdir -p '$TestRootMSYS'
"@

$MSYS2TempWindows = Join-Path $MSYS2Root 'tmp\msys2-gcc-test'

Copy-Item `
    -LiteralPath (Join-Path $TestRootWindows 'test.c') `
    -Destination (Join-Path $MSYS2TempWindows 'test.c') `
    -Force

Copy-Item `
    -LiteralPath (Join-Path $TestRootWindows 'test.cpp') `
    -Destination (Join-Path $MSYS2TempWindows 'test.cpp') `
    -Force

# -----------------------------------------------------------------------------
# Compile C test
# -----------------------------------------------------------------------------

Write-Step 'Compiling the native Windows C test'

Invoke-MSYS2 -Command @"
cd '$TestRootMSYS'

gcc \
    -Wall \
    -Wextra \
    -Wpedantic \
    -O2 \
    test.c \
    -o test-c.exe
"@

$CTestExecutable = Join-Path $MSYS2TempWindows 'test-c.exe'

if (-not (Test-Path -LiteralPath $CTestExecutable -PathType Leaf)) {
    throw "The C test executable was not created: $CTestExecutable"
}

Write-Host "Created: $CTestExecutable"

# -----------------------------------------------------------------------------
# Compile C++ test
# -----------------------------------------------------------------------------

Write-Step 'Compiling the native Windows C++ test'

Invoke-MSYS2 -Command @"
cd '$TestRootMSYS'

g++ \
    -Wall \
    -Wextra \
    -Wpedantic \
    -O2 \
    test.cpp \
    -o test-cpp.exe
"@

$CppTestExecutable = Join-Path $MSYS2TempWindows 'test-cpp.exe'

if (-not (Test-Path -LiteralPath $CppTestExecutable -PathType Leaf)) {
    throw "The C++ test executable was not created: $CppTestExecutable"
}

Write-Host "Created: $CppTestExecutable"

# -----------------------------------------------------------------------------
# Inspect generated executable formats
# -----------------------------------------------------------------------------

Write-Step 'Inspecting generated executable formats'

$FileOutput = & {
    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'

    try {
        & $BashPath `
            --login `
            -c "file '$TestRootMSYS/test-c.exe' '$TestRootMSYS/test-cpp.exe'"
    }
    finally {
        Remove-Item Env:\MSYSTEM -ErrorAction SilentlyContinue
        Remove-Item Env:\CHERE_INVOKING -ErrorAction SilentlyContinue
    }
}

if ($LASTEXITCODE -ne 0) {
    throw 'The file-format inspection command failed.'
}

$FileOutput | ForEach-Object {
    Write-Host $_
}

$FileText = $FileOutput -join "`n"

if ($FileText -notmatch 'PE32\+') {
    throw 'The generated files were not reported as PE32+ executables.'
}

if ($FileText -notmatch 'x86-64') {
    throw 'The generated files were not reported as x86-64 executables.'
}

Write-Host
Write-Host 'Native executable format verification PASSED.' `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# Run the C executable
# -----------------------------------------------------------------------------

Write-Step 'Running the native Windows C test'

$CTestOutput = & $CTestExecutable
$CTestExitCode = $LASTEXITCODE

$CTestOutput | ForEach-Object {
    Write-Host $_
}

if ($CTestExitCode -ne 0) {
    throw "The C test executable returned exit code $CTestExitCode."
}

if (($CTestOutput -join "`n") -notmatch 'C compiler test passed\.') {
    throw 'The C test executable did not return its expected success message.'
}

Write-Host 'Native C execution test PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Run the C++ executable with UCRT64 runtime libraries available
# -----------------------------------------------------------------------------

Write-Step 'Running the native Windows C++ test'

$PreviousPath = $env:PATH

try {
    $env:PATH = "$UCRT64Bin;$env:PATH"

    $CppTestOutput = & $CppTestExecutable
    $CppTestExitCode = $LASTEXITCODE
}
finally {
    $env:PATH = $PreviousPath
}

$CppTestOutput | ForEach-Object {
    Write-Host $_
}

if ($CppTestExitCode -ne 0) {
    throw "The C++ test executable returned exit code $CppTestExitCode."
}

if (($CppTestOutput -join "`n") -notmatch 'C\+\+ compiler test passed\.') {
    throw 'The C++ test executable did not return its expected success message.'
}

Write-Host 'Native C++ execution test PASSED.' -ForegroundColor Green

# -----------------------------------------------------------------------------
# Confirm that Windows PATH was not persistently modified
# -----------------------------------------------------------------------------

Write-Step 'Checking persistent Windows PATH values'

$UserPath = [Environment]::GetEnvironmentVariable(
    'Path',
    'User'
)

$MachinePath = [Environment]::GetEnvironmentVariable(
    'Path',
    'Machine'
)

$EscapedUCRT64Bin = [regex]::Escape($UCRT64Bin)

if ($UserPath -match $EscapedUCRT64Bin) {
    Write-Warning 'The UCRT64 bin directory was already present in the user PATH.'
}
else {
    Write-Host 'UCRT64 is not present in the persistent user PATH.'
}

if ($MachinePath -match $EscapedUCRT64Bin) {
    Write-Warning 'The UCRT64 bin directory was already present in the machine PATH.'
}
else {
    Write-Host 'UCRT64 is not present in the persistent machine PATH.'
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' STEP 5 COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green

Write-Host
Write-Host 'MSYS2 installation:'
Write-Host "  $MSYS2Root"

Write-Host
Write-Host 'MSYS2 full update:       COMPLETE' -ForegroundColor Green
Write-Host 'UCRT64 GCC toolchain:    INSTALLED' -ForegroundColor Green
Write-Host 'GCC target:              VERIFIED' -ForegroundColor Green
Write-Host 'C compilation:           PASSED' -ForegroundColor Green
Write-Host 'C++ compilation:         PASSED' -ForegroundColor Green
Write-Host 'PE32+ x86-64 format:     VERIFIED' -ForegroundColor Green
Write-Host 'Native C execution:      PASSED' -ForegroundColor Green
Write-Host 'Native C++ execution:    PASSED' -ForegroundColor Green

Write-Host
Write-Host "Compiler target:"
Write-Host "  $CompilerTarget"

Write-Host
Write-Host 'The Windows system and user PATH values were not modified.'
Write-Host 'Rust has not been installed.'