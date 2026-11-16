# 🚀 START HERE - Cline CLI Installation

Official documentation: [https://cline.bot/cli](https://cline.bot/cli)

## Overview

This directory provides a zero-administrator installation for the **Cline CLI** on Windows 10/11 using PowerShell 7. The CLI installs directly into user-local space under `$HOME\.npm-global`, requiring no administrative elevation or UAC prompts.

## Quickstart

```powershell
.\install-cline.ps1
```

To force reinstall:
```powershell
.\install-cline.ps1 -Force
```

## Prerequisites

- **Node.js:** Node.js v20+ and npm. If not yet installed, run:
  ```powershell
  cd ..\Node-Installer
  .\install-node.ps1
  ```

## Usage

After installation, open a new terminal window:

```powershell
# Authenticate your AI provider (Anthropic, OpenAI, OpenRouter, etc.)
cline auth

# Start an interactive session
cline
```
