# Windows-NonAdmin-Installers

Automated, cryptographically authenticated, zero-administrator developer toolchain installers for Windows 10 and 11 (x86-64) built in PowerShell 7.

This repository provides reproducible, fully non-elevated installers for modern developer toolchains. Every binary and archive is cryptographically verified (pinned OpenPGP signatures, SHA-256 release checksums, and Authenticode inspection) before execution, and all components install strictly into the current user's profile (`$HOME\msys64` and `$HOME\.local\rust`) without requiring UAC elevation or modifying machine-wide system state.

---

## Project Documents

- [Agent Guidelines](AGENTS.md) — Operational guidelines, signing requirements, docs & hardware snapshot locations.
- [Active Handoff](HANDOFF.md) — Current state, in-progress tasks, gotchas, and immediate next steps.
- [Project Roadmap](ROADMAP.md) — Architecture constraints, milestone phases, and future toolchain expansions.

---

## Toolchains Provided

### 1. MSYS2 & UCRT64 GCC Toolchain (`MSYS2-Installer/`)
A complete Unix-like build environment and native Windows C/C++ compiler toolchain targeting the modern Universal C Runtime (UCRT).
- **Target Location:** `$HOME\msys64` (`C:\Users\<username>\msys64`)
- **Key Features:**
  - Automated download of official versioned SFX archive (`msys2-base-x86_64-YYYYMMDD.sfx.exe`).
  - OpenPGP key retrieval from keyserver and strict validation against pinned primary key fingerprint (`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`).
  - Release SHA-256 checksum download from GitHub releases and cryptographic hash verification.
  - Windows Authenticode digital signature inspection.
  - Multi-pass `pacman -Syu` full system upgrade (handles core runtime updates cleanly).
  - Complete `mingw-w64-ucrt-x86_64-toolchain` installation (`gcc`, `g++`, `ld`, `ar`, `ranlib`, `windres`, `objdump`, `strip`, `make`, `pkg-config`).
  - Automated test compilation of native C and C++ programs verifying PE32+ x86-64 binary output and runtime execution.
  - Leaves Windows system and user PATH untouched to prevent global environment pollution.

### 2. Rust Standalone GNU Toolchain (`Rust-Installer/`)
A self-contained native Rust toolchain (`x86_64-pc-windows-gnu`) configured to utilize MSYS2's UCRT64 GCC and GNU binutils linker.
- **Target Location:** `$HOME\.local\rust` (`C:\Users\<username>\.local\rust`)
- **Key Features:**
  - Authenticated download of official `channel-rust-stable.toml` manifest using pinned Rust release key (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`).
  - Automatic extraction and installation of `rust-*-x86_64-pc-windows-gnu.tar.gz` via MSYS2 `tar`.
  - Verification of `rustc`, `cargo`, and `rustdoc` host targets.
  - Persistent **User PATH** configuration adding `$HOME\.local\rust\bin` and `$HOME\msys64\ucrt64\bin`.
  - Automatic timestamped backup of previous user PATH to `$HOME\.local\rust\environment-backups/` before any changes.
  - Automated end-to-end Cargo test project creation, debug/release build, and execution from native PowerShell.

---

## Prerequisites & Requirements

- **Operating System:** Windows 10 or Windows 11 (64-bit x86-64).
- **Shell:** PowerShell 7.0 or later (`pwsh.exe`).
- **Permissions:** Standard User (no administrator / UAC elevation required).
- **Disk Space:** ~3 GB free space on an NTFS drive.
- **Dependencies:**
  - GnuPG (`gpg.exe`) available in `PATH` (e.g. from [Gpg4win](https://www.gpg4win.org/) or Git for Windows).
  - Active internet connection for release artifact downloads.
- **Path Rules:** Installation paths must not contain spaces, non-ASCII characters, or reparse points (symlinks/junctions).

---

## Quickstart

### Step 1: Install MSYS2 & UCRT64 GCC Toolchain
Launch PowerShell 7 and run the master MSYS2 orchestrator:

```powershell
cd MSYS2-Installer
.\install-msys2.ps1
```

*To perform a clean reinstall and overwrite an existing `$HOME\msys64`:*
```powershell
.\install-msys2.ps1 -Force
```

### Step 2: Install & Configure Rust Standalone Toolchain
Once MSYS2 is installed, install Rust:

```powershell
cd ..\Rust-Installer
.\install-rust.ps1
```

After installation completes, restart your terminal, CMD, or VS Code session so the updated User PATH takes effect.

---

## Modular Step-by-Step Execution

Each installer can be executed as a sequence of isolated, auditable steps.

### MSYS2 Modular Steps
```powershell
cd MSYS2-Installer

# 1. Download SFX archive and signature
.\01-install-msys2.ps1

# 2. Import and validate official MSYS2 GPG signing key
.\02-import-msys2-signing-key.ps1

# 3. Verify SHA-256 hash, OpenPGP signature, and Authenticode
.\03-verify-msys2-archive.ps1

# 4. Extract archive to $HOME\msys64 and initialize login shell
.\04-install-msys2.ps1

# 5. Perform system upgrade, install UCRT64 GCC toolchain, and run test builds
.\05-install-gcc.ps1
```

### Rust Modular Steps
```powershell
cd Rust-Installer

# 1. Authenticate manifest and download Rust GNU standalone archive
.\01-download-rustup.ps1

# 2. Extract and install Rust toolchain under $HOME\.local\rust
.\02-install-rust-standalone.ps1

# 3. Configure user PATH, backup previous settings, and run Cargo test project
.\03-configure-rust-environment.ps1
```

---

## Launching & Verifying Environments

### Opening the MSYS2 UCRT64 Shell
To launch an interactive MSYS2 bash terminal in the UCRT64 environment:
```powershell
& "$HOME\msys64\msys2_shell.cmd" -ucrt64 -here
```

### Verifying from Standard PowerShell
Once Rust Step 3 has updated the user PATH (or after a shell restart):
```powershell
rustc --version
cargo --version
gcc --version
ld --version
```

### Testing a Native Cargo Project
```powershell
cargo new --bin hello-world
cd hello-world
cargo run
```

---

## Security & Verification Guarantees

| Property | Implementation Detail |
| :--- | :--- |
| **Privilege Model** | Zero elevation required. All operations scoped strictly to `$HOME`. |
| **GPG Fingerprint Pinning** | MSYS2 (`0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`) and Rust (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`). |
| **Integrity Verification** | Detached OpenPGP signatures (`GOODSIG`/`VALIDSIG`), SHA-256 release digests, and Windows Authenticode signatures. |
| **Fail-Fast Safety** | Any verification failure halts immediately before extraction or execution. Partial installs are cleaned up on error. |
| **Environment Isolation** | User PATH changes are backed up with timestamped recovery files under `$HOME\.local\rust\environment-backups/`. System PATH is never touched. |

---

## Troubleshooting

- **"File ... cannot be loaded because running scripts is disabled"**:
  Run PowerShell with execution policy bypass:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\install-msys2.ps1
  ```
- **"GnuPG was not found in PATH"**:
  Ensure `gpg.exe` is installed and accessible in your PATH. If you have Git for Windows installed, it is typically located at `C:\Program Files\Git\usr\bin\gpg.exe`.
- **"Installation stopped during Step 3"**:
  Check your internet connectivity or firewall settings. Step 3 retrieves release metadata and SHA-256 checksums from GitHub releases.
