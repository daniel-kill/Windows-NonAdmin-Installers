# git-delta Non-Admin Installer

Automated, reproducible, zero-elevation installer for `delta` (a syntax-highlighting pager for git, diff, and grep output) for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\delta\bin\delta.exe`
- **Official Source:** [dandavison/delta Releases](https://github.com/dandavison/delta/releases)
- **Integrity Verification:** SHA-256 integrity hash verification
- **Environment:** Appends `$HOME\.local\delta\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-delta.ps1
```

## Modular Execution
```powershell
.\01-download-delta.ps1
.\02-install-delta.ps1
.\03-configure-delta-environment.ps1
```
