# Bun Runtime Non-Admin Installer

Automated, reproducible, zero-elevation installer for Bun JavaScript & TypeScript runtime, package manager, and bundler for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\bun\bin\bun.exe`
- **Official Source:** [oven-sh/bun Releases](https://github.com/oven-sh/bun/releases)
- **Integrity Verification:** SHA-256 verification against official `SHASUMS256.txt`
- **Environment:** Appends `$HOME\.local\bun\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-bun.ps1
```

## Modular Execution
```powershell
.\01-download-bun.ps1
.\02-install-bun.ps1
.\03-configure-bun-environment.ps1
```
