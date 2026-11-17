#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify CMake Portable'; Script = Join-Path $ScriptRoot '01-download-cmake.ps1' }
    @{ Number = 2; Name = 'Extract & Install CMake';         Script = Join-Path $ScriptRoot '02-install-cmake.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify CMake';   Script = Join-Path $ScriptRoot '03-configure-cmake-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "CMAKE PORTABLE NON-ADMIN INSTALLATION" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

foreach ($Step in $Steps) {
    Write-Host
    Write-Host "==> Step $($Step.Number): $($Step.Name)" -ForegroundColor Yellow
    $Params = @{}
    if ($Step.Number -eq 2 -and $Force) { $Params['Force'] = $true }

    try {
        $global:LASTEXITCODE = 0
        & $Step.Script @Params
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Step $($Step.Number) FAILED: $($Step.Name)" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "✗ Step $($Step.Number) ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "✓ CMAKE INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\cmake\bin\cmake.exe"
Write-Host "Run 'cmake --version' in a new terminal window to begin."
exit 0
