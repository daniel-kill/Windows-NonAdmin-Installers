# 🚀 START HERE - Mistral Vibe CLI Installation

Official documentation: [https://chat.mistral.ai/code/extensions](https://chat.mistral.ai/code/extensions) / [GitHub: mistralai/mistral-vibe](https://github.com/mistralai/mistral-vibe)

## Overview

This directory provides a zero-administrator installation for the **Mistral Vibe CLI** on Windows 10/11 using PowerShell 7. The CLI installs into an isolated user-local environment under `$HOME\.local\vibe`, requiring no administrative elevation or UAC prompts.

## Quickstart

```powershell
.\install-vibe.ps1
```

To force reinstall:
```powershell
.\install-vibe.ps1 -Force
```

## Prerequisites

- **Python:** Python 3.11+ and pip. If not yet installed, run:
  ```powershell
  cd ..\Python-Installer
  .\install-python.ps1
  ```

## Usage

After installation, open a new terminal window:

```powershell
# Start an interactive Vibe session
vibe

# View CLI options
vibe --help
```
