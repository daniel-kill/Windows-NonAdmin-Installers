# 🚀 START HERE - Node.js Installation Orchestrator

## Overview

This directory provides an automated, zero-administrator installation system for Node.js (LTS) on Windows 10/11 (x86-64) using PowerShell 7.

To install Node.js and NPM:

```powershell
.\install-node.ps1
```

To perform a clean reinstall:
```powershell
.\install-node.ps1 -Force
```

---

## What Gets Installed

- **Node.js LTS:** Latest official Node.js Long Term Support release downloaded from `https://nodejs.org/dist/index.json`.
- **Target Location:** `$HOME\.local\node` (`C:\Users\<username>\.local\node`).
- **NPM Global Prefix:** `$HOME\.npm-global` — configured in user-level `.npmrc` so global packages (`npm install -g <pkg>`) install entirely without administrator elevation.
- **User Environment:**
  - Prepends `$HOME\.local\node` and `$HOME\.npm-global` to **User PATH**.
  - Automatically saves a timestamped backup of your previous user PATH in `$HOME\.local\node\environment-backups/`.
- **Machine State:** Zero modifications to machine PATH or registry; no UAC or administrator elevation needed.

---

## Modular Step Execution

You can run individual steps for auditability or debugging:

```powershell
# Step 1: Discover, download, and verify SHA-256 against official SHASUMS256.txt
.\01-download-node.ps1

# Step 2: Extract and install Node.js under $HOME\.local\node
.\02-install-node.ps1

# Step 3: Configure persistent user environment, set npm prefix, and test runtime
.\03-configure-node-environment.ps1
```

---

## Post-Installation Verification

Open a new PowerShell or Command Prompt terminal and run:

```powershell
node --version
npm --version
node -e 'console.log("Node non-admin test passed.")'
```
