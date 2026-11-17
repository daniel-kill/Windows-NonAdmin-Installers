# eza Non-Admin Installer

Automated, reproducible, zero-elevation installer for `eza` (a modern replacement for `ls` and `dir`) for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\eza\bin\eza.exe`
- **Official Source:** [eza-community/eza Releases](https://github.com/eza-community/eza/releases)
- **Integrity Verification:** SHA-256 verification against official release digests
- **Environment:** Appends `$HOME\.local\eza\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-eza.ps1
```

## Modular Execution
```powershell
.\01-download-eza.ps1
.\02-install-eza.ps1
.\03-configure-eza-environment.ps1
```
