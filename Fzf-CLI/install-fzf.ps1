#Requires -Version 7.0

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Steps = @(
    @{ Number = 1; Name = 'Download & Verify fzf';       Script = Join-Path $ScriptRoot '01-download-fzf.ps1' }
    @{ Number = 2; Name = 'Extract & Install fzf';       Script = Join-Path $ScriptRoot '02-install-fzf.ps1' }
    @{ Number = 3; Name = 'Configure PATH & Verify fzf'; Script = Join-Path $ScriptRoot '03-configure-fzf-environment.ps1' }
)

Write-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "FZF FUZZY FINDER NON-ADMIN INSTALLATION" -ForegroundColor Cyan
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
Write-Host "✓ FZF INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host "Location: $HOME\.local\fzf\bin\fzf.exe"
Write-Host "Run 'fzf --help' in a new terminal window to begin."
exit 0
