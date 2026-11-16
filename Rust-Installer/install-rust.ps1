#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Steps = @(
    [pscustomobject]@{
        Name = 'Download and verify the Rust standalone distribution'
        Path = (Join-Path $PSScriptRoot '01-download-rustup.ps1')
    }
    [pscustomobject]@{
        Name = 'Install and verify the Rust standalone toolchain'
        Path = (Join-Path $PSScriptRoot '02-install-rust-standalone.ps1')
    }
    [pscustomobject]@{
        Name = 'Configure and verify the persistent Rust environment'
        Path = (Join-Path $PSScriptRoot '03-configure-rust-environment.ps1')
    }
)

foreach ($Step in $Steps) {
    if (-not (Test-Path -LiteralPath $Step.Path -PathType Leaf)) {
        throw "Required installation script was not found: $($Step.Path)"
    }

    Write-Host
    Write-Host "============================================================" `
        -ForegroundColor Cyan
    Write-Host " $($Step.Name)" -ForegroundColor Cyan
    Write-Host "============================================================" `
        -ForegroundColor Cyan

    try {
        & $Step.Path
    }
    catch {
        throw "Installation stopped during '$($Step.Name)'. $($_.Exception.Message)"
    }
}

Write-Host
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host ' RUST INSTALLATION AND CONFIGURATION COMPLETE' -ForegroundColor Green
Write-Host '============================================================' `
    -ForegroundColor Green
Write-Host
Write-Host "Rust is installed under: $(Join-Path $HOME '.local\rust')"
Write-Host 'The user PATH now includes Rust and MSYS2 UCRT64.'
Write-Host 'The machine PATH is unchanged; reopen terminals and VS Code to refresh PATH.'
