#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install Playwright CLI globally into user-local space ($HOME\.npm-global)
#
# Parameters:
#   -Force: Force reinstall of the @playwright/cli npm package.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

Write-Step 'Configuring non-admin npm prefix and installing Playwright CLI'

$NpmGlobalDir = Join-Path $HOME '.npm-global'
if (-not (Test-Path -LiteralPath $NpmGlobalDir)) {
    New-Item -ItemType Directory -Path $NpmGlobalDir -Force | Out-Null
}

$LocalNpmCmd = Join-Path $HOME '.local\node\npm.cmd'
$NpmCmd = if (Test-Path -LiteralPath $LocalNpmCmd) {
    $LocalNpmCmd
} else {
    $cmd = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command npm -ErrorAction SilentlyContinue }
    if ($cmd) { $cmd.Source } else { throw 'NPM not found in environment.' }
}

Write-Host "Using NPM: $NpmCmd"

# Ensure user prefix is directed to .npm-global
$PrefixNorm = $NpmGlobalDir -replace '\\', '/'
& $NpmCmd config set prefix $PrefixNorm --location=user

Write-Step 'Installing @playwright/cli npm package'
$InstallArgs = @('install', '-g', '@playwright/cli')
if ($Force) {
    $InstallArgs += '--force'
}

& $NpmCmd @InstallArgs

if ($LASTEXITCODE -ne 0) {
    throw "npm install failed with exit code $LASTEXITCODE"
}

$PlaywrightCmd = Join-Path $NpmGlobalDir 'playwright-cli.cmd'
if (-not (Test-Path -LiteralPath $PlaywrightCmd -PathType Leaf)) {
    # Check bin subdirectory just in case
    $PlaywrightCmd = Join-Path (Join-Path $NpmGlobalDir 'bin') 'playwright-cli.cmd'
}

if (-not (Test-Path -LiteralPath $PlaywrightCmd -PathType Leaf)) {
    Write-Warning "Could not find playwright-cli.cmd directly in $NpmGlobalDir. It may be named playwright-cli or in a subfolder."
}
else {
    Write-Host "Found Playwright CLI command: $PlaywrightCmd" -ForegroundColor Green
}

Write-Host
Write-Host "Playwright CLI package installed successfully into: $NpmGlobalDir" -ForegroundColor Green
