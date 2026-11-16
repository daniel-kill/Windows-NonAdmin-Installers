# 🚀 START HERE - PortableGit Installation

Official website: [https://git-scm.com/](https://git-scm.com/)  
Git for Windows: [https://gitforwindows.org/](https://gitforwindows.org/)

## Overview

PortableGit provides the complete Git for Windows environment—including `git.exe`, Git Bash (`bash.exe`), OpenSSH, cURL, and Git Credential Manager—packaged for zero-administrator portable execution in user space.

## Quickstart

```powershell
.\install-git.ps1
```

To force reinstall:
```powershell
.\install-git.ps1 -Force
```

## What Gets Installed

- **Location:** `$HOME\.local\git\`
- **Key Executables:** `cmd\git.exe`, `bin\bash.exe`, `usr\bin\ssh.exe`
- **User Environment:** Prepends `$HOME\.local\git\cmd` to User `PATH`.
- **Elevation:** None required.

## Usage

```powershell
git --version
git clone <url>
git status
```
