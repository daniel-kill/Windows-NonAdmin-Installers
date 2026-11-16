# 🚀 START HERE - KeePassXC & KeePassXC-CLI Installation

Official website: [https://keepassxc.org/](https://keepassxc.org/)  
Official documentation: [https://keepassxc.org/docs/](https://keepassxc.org/docs/)  
Signature verification guide: [https://keepassxc.org/verifying-signatures/](https://keepassxc.org/verifying-signatures/)

## Overview

This directory provides an automated, zero-administrator installation for **KeePassXC** and the **KeePassXC-CLI** on Windows 10/11 using PowerShell 7.

KeePassXC is a community-driven, cross-platform password manager and secure credential store utilizing strong AES-256 and ChaCha20 encryption. It includes:
1. **`keepassxc-cli.exe`**: A scriptable command-line interface for reading, querying, editing, generating credentials, extracting passkeys, and managing TOTP tokens directly from PowerShell or automated agent workflows.
2. **`KeePassXC.exe`**: The full-featured desktop GUI with browser integration (Firefox, Chrome, Edge) and SSH agent support.

## Quickstart

Run the master orchestrator to download, verify, extract, and configure KeePassXC in user space:

```powershell
.\install-keepassxc.ps1
```

To force a clean reinstallation:
```powershell
.\install-keepassxc.ps1 -Force
```

## What Gets Installed

- **Target Location:** `$HOME\.local\keepassxc\`
- **Key Executables:**
  - `keepassxc-cli.exe`: Command-line interface.
  - `KeePassXC.exe`: Desktop GUI application.
  - `keepassxc-proxy.exe`: Native messaging host for browser extensions.
- **Portability Mode:** An empty `.portable` marker file is placed in the installation root, instructing KeePassXC to store its configuration, bookmarks, and settings strictly in user space without requiring machine registry modifications.
- **User Environment:** Prepends `$HOME\.local\keepassxc` to **User PATH** with an automatic timestamped backup saved in `$HOME\.local\keepassxc\environment-backups/`.
- **Elevation:** None required (Standard User permissions).

## Cryptographic Verification

Every download is verified through multiple security layers prior to extraction:
1. **SHA-256 Digest Verification:** Validated against the official `.DIGEST` release asset published by the KeePassXC project.
2. **OpenPGP Detached Signature:** Validated using GnuPG (`gpg.exe`) against the pinned official KeePassXC Release Master Key fingerprint:
   ```text
   Primary Key Fingerprint: BF5A 669F 2272 CF43 24C1 FDA8 CFB4 C216 6397 D0D2
   Signing Subkey:          C1E4 CBA3 AD78 D3AF D894 F9E0 B7A6 6F03 B590 76A8
   ```
3. **Windows Authenticode Signatures:** Extracted binaries (`KeePassXC.exe` and `keepassxc-cli.exe`) are validated against the official digital certificate issued to `DroidMonkey Apps, LLC`.

## CLI Usage & Quick Reference

After installation finishes, restart your PowerShell or terminal window:

### Check Version & Help
```powershell
keepassxc-cli --version
keepassxc-cli --help
```

### Generate a Strong Password
```powershell
keepassxc-cli generate -L 32 --lower --upper --numeric --special
```

### Create a New Database
```powershell
keepassxc-cli db-create "$HOME\Passwords.kdbx"
```

### List Entries in a Database
```powershell
keepassxc-cli ls "$HOME\Passwords.kdbx"
```

### Copy Password to Clipboard (10-second timeout)
```powershell
keepassxc-cli clip "$HOME\Passwords.kdbx" "MyEntryTitle" 10
```

### Launch GUI
```powershell
keepassxc
```
