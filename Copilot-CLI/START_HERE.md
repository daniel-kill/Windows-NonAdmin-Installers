# 🚀 START HERE - GitHub Copilot CLI Installation

Official documentation: [https://github.com/github/copilot-cli](https://github.com/github/copilot-cli)

## Overview

This directory provides a zero-administrator installation for the official **GitHub Copilot CLI** (`@github/copilot`) on Windows 10/11 using PowerShell 7. The CLI installs directly into user-local space under `$HOME\.npm-global`, requiring no administrative elevation or UAC prompts.

## Quickstart

```powershell
.\install-copilot.ps1
```

To force reinstall:
```powershell
.\install-copilot.ps1 -Force
```

## Prerequisites

- **Node.js:** Node.js v22+ (or v20+) and npm. If not yet installed, run:
  ```powershell
  cd ..\Node-Installer
  .\install-node.ps1
  ```

## Usage

After installation, open a new terminal window:

```powershell
# Authenticate with GitHub
copilot

# Verify version
copilot --version
```
