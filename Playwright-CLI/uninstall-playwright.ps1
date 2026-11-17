#Requires -Version 7.0

param(
    [switch]$KeepCache
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Uninstaller for Playwright CLI
# -----------------------------------------------------------------------------

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "UNINSTALLING PLAYWRIGHT CLI" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$GlobalDir = Join-Path $HOME '.npm-global'

if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
    Write-Host "Removing @playwright/cli via npm global uninstall..." -ForegroundColor Yellow
    npm.cmd uninstall -g @playwright/cli 2>$null | Out-Null
}

# Clean up any leftover shim binaries or command scripts
$Shims = @(
    Join-Path $GlobalDir 'playwright-cli',
    Join-Path $GlobalDir 'playwright-cli.cmd',
    Join-Path $GlobalDir 'playwright-cli.ps1',
    $null
) | Where-Object { $null -ne $_ }

foreach ($Shim in $Shims) {
    if (Test-Path -LiteralPath $Shim) {
        Remove-Item -LiteralPath $Shim -Force -ErrorAction SilentlyContinue
        Write-Host "Removed shim: $Shim" -ForegroundColor Gray
    }
}

$PkgDir = Join-Path $GlobalDir "node_modules\@playwright\cli"
if (Test-Path -LiteralPath $PkgDir) {
    Remove-Item -LiteralPath $PkgDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "✓ Playwright CLI has been uninstalled." -ForegroundColor Green
exit 0
