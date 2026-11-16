# 🚀 START HERE - Gpg4win & GnuPG Installation

Official website: [https://www.gpg4win.org/](https://www.gpg4win.org/)

## Overview

This directory provides an automated, zero-administrator installation for **Gpg4win** and the **GnuPG** engine on Windows 10/11 using PowerShell 7. 

Because GnuPG (`gpg.exe`) is a critical prerequisite for verifying cryptographic OpenPGP signatures across MSYS2, Rust, and other toolchain distributions in this repository, this installer provides a seamless, non-elevated way to install and configure GnuPG in user space (`$HOME\.local\gpg4win`) without requiring administrator privileges or UAC elevation.

## Quickstart

```powershell
.\install-gpg4win.ps1
```

To force reinstall:
```powershell
.\install-gpg4win.ps1 -Force
```

## What Gets Installed

- **GnuPG Core Engine:** `gpg.exe`, `gpgv.exe`, `gpg-agent.exe`, `dirmngr.exe`, `pinentry.exe` under `$HOME\.local\gpg4win\GnuPG\bin\`.
- **Gpg4win Suite:** `kleopatra.exe` and cryptographic utility components under `$HOME\.local\gpg4win\Gpg4win\bin\`.
- **User Environment:** Prepends `$HOME\.local\gpg4win\GnuPG\bin` to **User PATH** with an automatic timestamped backup saved in `$HOME\.local\gpg4win\environment-backups/`.
- **Elevation:** None required (`__COMPAT_LAYER=RunAsInvoker`).

## Usage

After installation completes, restart your PowerShell or terminal window:

```powershell
gpg --version
gpg --help
```
