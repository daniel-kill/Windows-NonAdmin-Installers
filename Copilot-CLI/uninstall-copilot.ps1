#Requires -Version 7.0

param(
    [switch]$KeepCache
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Uninstaller for GitHub Copilot CLI
# -----------------------------------------------------------------------------

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "UNINSTALLING GITHUB COPILOT CLI" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$GlobalDir = Join-Path $HOME '.npm-global'

if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
    Write-Host "Removing @github/copilot via npm global uninstall..." -ForegroundColor Yellow
    npm.cmd uninstall -g @github/copilot 2>$null | Out-Null
}

# Clean up any leftover shim binaries or command scripts
$Shims = @(
    Join-Path $GlobalDir 'copilot',
    Join-Path $GlobalDir 'copilot.cmd',
    Join-Path $GlobalDir 'copilot.ps1',
    Join-Path $GlobalDir 'github-copilot',
    Join-Path $GlobalDir 'github-copilot.cmd',
    $null
) | Where-Object { $null -ne $_ }

foreach ($Shim in $Shims) {
    if (Test-Path -LiteralPath $Shim) {
        Remove-Item -LiteralPath $Shim -Force -ErrorAction SilentlyContinue
        Write-Host "Removed shim: $Shim" -ForegroundColor Gray
    }
}

$PkgDir = Join-Path $GlobalDir "node_modules\@github/copilot"
if (Test-Path -LiteralPath $PkgDir) {
    Remove-Item -LiteralPath $PkgDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "✓ GitHub Copilot CLI has been uninstalled." -ForegroundColor Green
exit 0
