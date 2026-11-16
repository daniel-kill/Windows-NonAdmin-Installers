# 🚀 START HERE - OpenRouter Ori CLI Installation

Official documentation: [https://openrouter.ai/ori](https://openrouter.ai/ori) / [GitHub: OpenRouterLabs/ori-releases](https://github.com/OpenRouterLabs/ori-releases)

## Overview

This directory provides a zero-administrator installation for the **OpenRouter Ori CLI** on Windows 10/11 using PowerShell 7. The installer downloads the official pre-built native Windows x64 binary, verifies its cryptographic hash against `SHA256SUMS`, and installs it directly into user-local space at `$HOME\.local\ori\bin\ori.exe`.

## Quickstart

```powershell
.\install-ori.ps1
```

To force reinstall:
```powershell
.\install-ori.ps1 -Force
```

## Usage

After installation, open a new terminal window:

```powershell
# Authenticate with OpenRouter OAuth
ori login

# Verify version
ori --version

# Run an agent through Ori
ori
```
