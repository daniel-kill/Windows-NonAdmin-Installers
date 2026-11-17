# Scoop Command-Line Package Manager Installer

Automated, reproducible, zero-elevation installer for Scoop on Windows using PowerShell 7.

## Overview
- **Destination:** `$HOME\scoop` (`shims\scoop.cmd`, `shims\scoop.ps1`, `apps\scoop\current`)
- **Official Website:** [https://scoop.sh/](https://scoop.sh/)
- **Official Source:** [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop)
- **Environment:** Sets User environment variable `SCOOP` and appends `shims` to User `PATH`.
- **Package Scope:** Focuses on clean, portable CLI programs and developer utilities installed entirely within the user profile without administrative elevation or registry pollution.

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-scoop.ps1
```

## Modular Execution
```powershell
.\01-download-scoop.ps1
.\02-install-scoop.ps1
.\03-configure-scoop-environment.ps1
```

## Clean Uninstallation
```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall-scoop.ps1
```
