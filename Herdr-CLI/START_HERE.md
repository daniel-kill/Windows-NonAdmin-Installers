# Herdr AI Agent Runtime Non-Admin Installer

Automated, reproducible, zero-elevation installer for `Herdr` agent runtime and terminal manager (`herdr-core` / `hc`) for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\herdr\bin` (`hc.exe`, `herdr-core.exe`, `conpty/`)
- **Official Source:** [herdr.dev](https://herdr.dev/)
- **Release Manifest:** `https://releases.herdr.dev/core/latest.json`
- **Integrity Verification:** SHA-256 verification against official release manifest
- **Environment:** Appends `$HOME\.local\herdr\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-herdr.ps1
```

## Modular Execution
```powershell
.\01-download-herdr.ps1
.\02-install-herdr.ps1
.\03-configure-herdr-environment.ps1
```
