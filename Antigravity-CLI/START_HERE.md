# 🚀 START HERE - Google Antigravity CLI Installation

Official documentation: [https://antigravity.google/product/antigravity-cli](https://antigravity.google/product/antigravity-cli)

## Overview

This directory provides a zero-administrator installation for the **Google Antigravity CLI** (`agy`) on Windows 10/11 using PowerShell 7. The installer queries the official Google manifest, cryptographically verifies the native Windows x64 binary hash (SHA-512), and installs it directly into user-local space at `$HOME\.local\antigravity\bin\agy.exe`.

## Quickstart

```powershell
.\install-antigravity.ps1
```

To force reinstall:
```powershell
.\install-antigravity.ps1 -Force
```

## Usage

After installation, open a new terminal window:

```powershell
# Authenticate and launch interactive agent session
agy

# Display CLI version and help
agy --version
agy --help
```
