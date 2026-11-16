# 🚀 START HERE - Python Installation Orchestrator

## Overview

This directory provides an automated, zero-administrator installation system for a fully functional, portable Python toolchain with pip on Windows 10/11 (x86-64) using PowerShell 7.

To install Python and Pip:

```powershell
.\install-python.ps1
```

To perform a clean reinstall:
```powershell
.\install-python.ps1 -Force
```

---

## What Gets Installed

- **Python Runtime:** Latest stable 64-bit Windows embeddable package from official `python.org`.
- **Package Manager:** `pip` and `setuptools` automatically bootstrapped via `get-pip.py`.
- **Target Location:** `$HOME\.local\python` (`C:\Users\<username>\.local\python`).
- **User Environment:**
  - Prepends `$HOME\.local\python` and `$HOME\.local\python\Scripts` to **User PATH**.
  - Configures `._pth` to support standard user `site-packages` so packages installed via `pip install <pkg>` work out of the box.
  - Automatically saves a timestamped backup of your previous user PATH in `$HOME\.local\python\environment-backups/`.
- **Machine State:** Zero modifications to machine PATH or registry; no UAC or administrator elevation needed.

---

## Modular Step Execution

You can run individual steps for auditability or debugging:

```powershell
# Step 1: Discover, download, and verify Python archive and get-pip.py
.\01-download-python.ps1

# Step 2: Extract to $HOME\.local\python, enable site-packages, and bootstrap pip
.\02-install-python.ps1

# Step 3: Configure persistent user environment and test execution
.\03-configure-python-environment.ps1
```

---

## Post-Installation Verification

Open a new PowerShell or Command Prompt terminal and run:

```powershell
python --version
pip --version
python -c "import sys; print('Hello from user Python:', sys.version)"
```
