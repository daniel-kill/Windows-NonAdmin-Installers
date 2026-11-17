# fzf Fuzzy Finder Non-Admin Installer

Automated, reproducible, zero-elevation installer for fzf command-line fuzzy finder for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\fzf\bin\fzf.exe`
- **Official Source:** [junegunn/fzf Releases](https://github.com/junegunn/fzf/releases)
- **Integrity Verification:** SHA-256 verification against official `checksums.txt`
- **Environment:** Appends `$HOME\.local\fzf\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-fzf.ps1
```

## Modular Execution
```powershell
.\01-download-fzf.ps1
.\02-install-fzf.ps1
.\03-configure-fzf-environment.ps1
```
