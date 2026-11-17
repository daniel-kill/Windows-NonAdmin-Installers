# CMake Portable Non-Admin Installer

Automated, reproducible, zero-elevation installer for CMake Portable for Windows x86-64 using PowerShell 7.

## Overview
- **Destination:** `$HOME\.local\cmake` (`bin\cmake.exe`, `bin\ctest.exe`, `bin\cpack.exe`)
- **Official Source:** [Kitware/CMake Releases](https://github.com/Kitware/CMake/releases)
- **Integrity Verification:** SHA-256 verification against official `cmake-*-SHA-256.txt`
- **Environment:** Appends `$HOME\.local\cmake\bin` to User PATH with timestamped backups

## Quickstart
```powershell
pwsh -ExecutionPolicy Bypass -File .\install-cmake.ps1
```

## Modular Execution
```powershell
.\01-download-cmake.ps1
.\02-install-cmake.ps1
.\03-configure-cmake-environment.ps1
```
