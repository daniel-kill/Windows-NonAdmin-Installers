# 🚀 START HERE - Go Installation Orchestrator

## Overview

This directory provides an automated, zero-administrator installation system for the official Go toolchain on Windows 10/11 (x86-64) using PowerShell 7.

To install Go:

```powershell
.\install-go.ps1
```

To perform a clean reinstall:
```powershell
.\install-go.ps1 -Force
```

---

## What Gets Installed

- **Go Toolchain:** Latest official stable Go release downloaded from `https://go.dev/dl/?mode=json`.
- **Target Location:** `$HOME\.local\go` (`C:\Users\<username>\.local\go`).
- **User Environment:**
  - `GOROOT = $HOME\.local\go`
  - `GOPATH = $HOME\go`
  - Prepends `$HOME\.local\go\bin` and `$HOME\go\bin` to **User PATH**.
  - Automatically saves a timestamped backup of your previous user PATH in `$HOME\.local\go\environment-backups/`.
- **Machine State:** Zero modifications to machine PATH or registry; no UAC or administrator elevation needed.

---

## Modular Step Execution

You can run individual steps for auditability or debugging:

```powershell
# Step 1: Discover, download, and verify SHA-256 against official manifest
.\01-download-go.ps1

# Step 2: Extract and install Go under $HOME\.local\go
.\02-install-go.ps1

# Step 3: Configure persistent user environment and test compilation
.\03-configure-go-environment.ps1
```

---

## Post-Installation Verification

Open a new PowerShell or Command Prompt terminal and run:

```powershell
go version
go env GOROOT GOPATH
```
