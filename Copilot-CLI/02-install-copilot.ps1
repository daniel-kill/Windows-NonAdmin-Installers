#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Step 2: Install GitHub Copilot CLI globally into user-local space ($HOME\.npm-global)
#
# Parameters:
#   -Force: Force reinstall of the @github/copilot npm package.
# -----------------------------------------------------------------------------

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host
    Write-Host "==> $Message" -ForegroundColor Cyan
}

Write-Step 'Configuring non-admin npm prefix and installing GitHub Copilot CLI'

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

$PrefixNorm = $NpmGlobalDir -replace '\\', '/'
& $NpmCmd config set prefix $PrefixNorm --location=user

Write-Step 'Installing @github/copilot npm package'
$InstallArgs = @('install', '-g', '@github/copilot')
if ($Force) {
    $InstallArgs += '--force'
}

& $NpmCmd @InstallArgs

if ($LASTEXITCODE -ne 0) {
    throw "npm install failed with exit code $LASTEXITCODE"
}

$CopilotCmd = Join-Path $NpmGlobalDir 'copilot.cmd'
if (-not (Test-Path -LiteralPath $CopilotCmd -PathType Leaf)) {
    $CopilotCmd = Join-Path (Join-Path $NpmGlobalDir 'bin') 'copilot.cmd'
}

if (-not (Test-Path -LiteralPath $CopilotCmd -PathType Leaf)) {
    Write-Warning "Could not find copilot.cmd directly in $NpmGlobalDir. It may be named copilot or in a subfolder."
}
else {
    Write-Host "Found Copilot CLI command: $CopilotCmd" -ForegroundColor Green
}

Write-Host
Write-Host "GitHub Copilot CLI package installed successfully into: $NpmGlobalDir" -ForegroundColor Green
