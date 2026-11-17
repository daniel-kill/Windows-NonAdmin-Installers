# Chocolatey Non-Administrative User Installer

Automated, reproducible, zero-elevation installer for Chocolatey CLI on Windows using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\chocolatey` (`bin\choco.exe`)
- **Official Documentation:** [Chocolatey Non-Administrative Install](https://docs.chocolatey.org/en-us/choco/setup/#non-administrative-install)
- **Official Source:** [Chocolatey Releases](https://github.com/chocolatey/choco/releases)
- **Environment:** Sets User environment variable `ChocolateyInstall` and appends `bin` to User `PATH`.
- **Package Scope:** Standard non-administrative installations target `.portable` packages (e.g. `choco install <pkg>.portable`).

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-chocolatey.ps1
```

## Modular Execution
```powershell
.\01-download-chocolatey.ps1
.\02-install-chocolatey.ps1
.\03-configure-chocolatey-environment.ps1
```

## Clean Uninstallation
```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall-chocolatey.ps1
```
