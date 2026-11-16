# Rust Standalone Installation

This folder contains a three-step installer for the x86-64 GNU Rust standalone
toolchain on Windows. The orchestrator downloads and verifies the distribution,
installs it, then configures and tests the persistent user environment. If any
step fails, later steps will not run.

## Quick start

Open PowerShell 7, change to this folder, and run:

```powershell
.\install-rust.ps1
```

For example:

```powershell
cd "$HOME\Repos\_temp\Rust-win-install"
.\install-rust.ps1
```

Allow the scripts to finish before closing PowerShell. They report progress and
stop with an error if a required step fails.

## Requirements

- Windows x86-64
- PowerShell 7.0 or later
- GnuPG (`gpg`) available in `PATH`
- MSYS2 installed at `$HOME\msys64`, including the UCRT64 GCC, G++, and GNU
  linker tools
- Internet access to download the Rust release files
- No existing `$HOME\.local\rust` directory; the installer will not overwrite
  or merge with an existing installation

## What the scripts do

1. `01-download-rustup.ps1` downloads the Rust stable GNU Windows standalone
   archive and verifies it against the authenticated Rust manifest and signing
   key. Despite its filename, it does not install Rustup.
2. `02-install-rust-standalone.ps1` re-verifies the downloaded files, installs
   Rust under `$HOME\.local\rust`, and checks the tools and GNU target. This
   step does not modify persistent PATH values.
3. `03-configure-rust-environment.ps1` backs up the current user PATH, adds
   `$HOME\.local\rust\bin` and `$HOME\msys64\ucrt64\bin` to the front of it,
   verifies command resolution, and builds and runs a test Cargo project.

The scripts do not require administrator privileges. Step 3 persistently
updates the **user PATH**; it does not change the machine PATH. A timestamped
backup of the previous user PATH is saved under
`$HOME\.local\rust\environment-backups`. Close and reopen PowerShell, CMD,
Windows Terminal, and VS Code after installation so they receive the updated
PATH.

The installed Rust executables are in `$HOME\.local\rust\bin`. If you run only
the first two steps and want Rust available in the current PowerShell session,
add its directory to the process PATH:

```powershell
$env:PATH = "$HOME\.local\rust\bin;$env:PATH"
```

## Running steps on their own

The steps can also be run individually, in order. Run step 3 only after step 2
has completed successfully:

```powershell
.\01-download-rustup.ps1
.\02-install-rust-standalone.ps1
.\03-configure-rust-environment.ps1
```
