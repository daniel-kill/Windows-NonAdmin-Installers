# bat Non-Admin Installer

Automated, reproducible, zero-elevation installer for `bat` (a `cat` clone with syntax highlighting and Git integration) for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\bat\bin\bat.exe`
- **Official Source:** [sharkdp/bat Releases](https://github.com/sharkdp/bat/releases)
- **Integrity Verification:** SHA-256 integrity hash verification
- **Environment:** Appends `$HOME\.local\bat\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-bat.ps1
```

## Modular Execution
```powershell
.\01-download-bat.ps1
.\02-install-bat.ps1
.\03-configure-bat-environment.ps1
```
