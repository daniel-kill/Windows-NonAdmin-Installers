# Ninja Build System Non-Admin Installer

Automated, reproducible, zero-elevation installer for the Ninja build system for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\ninja\bin\ninja.exe`
- **Official Source:** [ninja-build/ninja Releases](https://github.com/ninja-build/ninja/releases)
- **Integrity Verification:** SHA-256 integrity hash verification
- **Environment:** Appends `$HOME\.local\ninja\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-ninja.ps1
```

## Modular Execution
```powershell
.\01-download-ninja.ps1
.\02-install-ninja.ps1
.\03-configure-ninja-environment.ps1
```
