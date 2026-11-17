# Deno Runtime Non-Admin Installer

Automated, reproducible, zero-elevation installer for Deno modern TypeScript & JavaScript runtime for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\deno\bin\deno.exe`
- **Official Source:** [denoland/deno Releases](https://github.com/denoland/deno/releases)
- **Integrity Verification:** SHA-256 verification against official `.sha256sum`
- **Environment:** Appends `$HOME\.local\deno\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-deno.ps1
```

## Modular Execution
```powershell
.\01-download-deno.ps1
.\02-install-deno.ps1
.\03-configure-deno-environment.ps1
```
