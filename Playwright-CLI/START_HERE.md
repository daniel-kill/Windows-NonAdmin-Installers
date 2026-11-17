# 🚀 START HERE - Playwright CLI Installation

Official repository: [https://github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)

## Overview

This directory provides a zero-administrator installation for Microsoft's official **Playwright CLI** (`@playwright/cli`) on Windows 10/11 using PowerShell 7. The Playwright CLI provides terminal-friendly, token-efficient browser automation commands with persistent daemon sessions and element refs, tailored specifically for AI coding agents (Claude Code, GitHub Copilot, Antigravity, Cline) and automated workflows.

## Quickstart

```powershell
.\install-playwright.ps1
```

To force reinstall:
```powershell
.\install-playwright.ps1 -Force
```

## Prerequisites

- **Node.js:** Node.js v20+ and npm. If not yet installed, run:
  ```powershell
  cd ..\Node-Installer
  .\install-node.ps1
  ```

## What Gets Installed

- **Package:** `@playwright/cli` installed into user-local space (`$HOME\.npm-global`).
- **Launchers:** `playwright-cli.cmd`, `playwright-cli.ps1`, `playwright-cli` in `$HOME\.npm-global`.
- **User Environment:** Prepends `$HOME\.npm-global` to User `PATH`.
- **Elevation:** None required. Zero registry changes.

## Usage

After installation, open a terminal window:

```powershell
# Display help and available commands
playwright-cli --help

# Verify installed version
playwright-cli --version

# Open a browser session
playwright-cli open https://playwright.dev

# Inspect elements and interact
playwright-cli snapshot
playwright-cli click e12
playwright-cli screenshot

# List and manage browser sessions
playwright-cli list
playwright-cli close-all
```

## Uninstallation

To remove Playwright CLI from your user profile:

```powershell
.\uninstall-playwright.ps1
```
