# Cloudflare Tunnel CLI (cloudflared) Non-Admin Installer

Automated, reproducible, zero-elevation installer for `cloudflared` (Cloudflare Tunnel client) for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\cloudflared\bin\cloudflared.exe`
- **Official Source:** [cloudflare/cloudflared Releases](https://github.com/cloudflare/cloudflared/releases)
- **Integrity Verification:** SHA-256 verification against official release digests
- **Environment:** Appends `$HOME\.local\cloudflared\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-cloudflared.ps1
```

## Modular Execution
```powershell
.\01-download-cloudflared.ps1
.\02-install-cloudflared.ps1
.\03-configure-cloudflared-environment.ps1
```
