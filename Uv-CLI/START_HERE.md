# Astral uv Non-Admin Installer

Automated, reproducible, zero-elevation installer for Astral `uv` and `uvx` Python package and tool runner for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\uv\bin` (`uv.exe`, `uvx.exe`)
- **Official Source:** [astral-sh/uv Releases](https://github.com/astral-sh/uv/releases)
- **Integrity Verification:** SHA-256 verification against official `.sha256` digest
- **Environment:** Appends `$HOME\.local\uv\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-uv.ps1
```

## Modular Execution
```powershell
.\01-download-uv.ps1
.\02-install-uv.ps1
.\03-configure-uv-environment.ps1
```
