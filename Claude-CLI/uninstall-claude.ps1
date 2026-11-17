#Requires -Version 7.0

param(
    [switch]$KeepCache
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Uninstaller for Claude Code CLI
# -----------------------------------------------------------------------------

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "UNINSTALLING CLAUDE CODE CLI" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

$GlobalDir = Join-Path $HOME '.npm-global'

if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
    Write-Host "Removing @anthropic-ai/claude-code via npm global uninstall..." -ForegroundColor Yellow
    npm.cmd uninstall -g @anthropic-ai/claude-code 2>$null | Out-Null
}

# Clean up any leftover shim binaries or command scripts
$Shims = @(
    Join-Path $GlobalDir 'claude',
    Join-Path $GlobalDir 'claude.cmd',
    Join-Path $GlobalDir 'claude.ps1',
    $null
) | Where-Object { $null -ne $_ }

foreach ($Shim in $Shims) {
    if (Test-Path -LiteralPath $Shim) {
        Remove-Item -LiteralPath $Shim -Force -ErrorAction SilentlyContinue
        Write-Host "Removed shim: $Shim" -ForegroundColor Gray
    }
}

$PkgDir = Join-Path $GlobalDir "node_modules\@anthropic-ai/claude-code"
if (Test-Path -LiteralPath $PkgDir) {
    Remove-Item -LiteralPath $PkgDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "✓ Claude Code CLI has been uninstalled." -ForegroundColor Green
exit 0
