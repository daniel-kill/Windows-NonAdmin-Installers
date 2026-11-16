# Roadmap: Windows-NonAdmin-Installers

## Goal & Constraints

- **Primary Objective:** Provide automated, fully non-elevated (zero-administrator) developer toolchain installers for Windows 10/11 x86-64 using PowerShell 7, guaranteeing end-to-end cryptographic verification and zero pollution of machine-wide system state.
- **Key Constraints:**
  - **Zero Elevation:** Under no circumstances should scripts invoke UAC, require Administrator group membership, or modify system-wide machine registries.
  - **Local Scope:** All binaries, toolchains, caches, and configuration must reside strictly within `$HOME` (`$HOME\msys64`, `$HOME\.local\...`).
  - **Strict Cryptographic Authentication:** Pinned OpenPGP primary key fingerprints, detached signature verification (`GOODSIG`/`VALIDSIG`), SHA-256 release checksum verification, and Authenticode signature checks prior to extraction.
  - **Environment Hygiene:** User PATH mutations must be backed up to timestamped restore files before alteration. Deduplicate PATH entries and avoid mutating the machine PATH.
  - **Fail-Fast & Cleanup:** Halt immediately upon any verification anomaly; clean up partial or corrupted extractions.

---

## Phase 0 — Core Architecture & Modular Implementation (Completed)

- [x] **MSYS2 SFX Downloader (`01-install-msys2.ps1`):** Scrape official distribution index for newest stable `msys2-base-x86_64-YYYYMMDD.sfx.exe` and detached OpenPGP signature.
- [x] **MSYS2 PGP Key Ingestion (`02-import-msys2-signing-key.ps1`):** Import official key from keyserver and validate against pinned primary fingerprint `0EBF782C5D53F7E5FB02A66746BD761F7A49B0EC`.
- [x] **MSYS2 Archive Verification (`03-verify-msys2-archive.ps1`):** Multi-check validation covering SHA-256 release asset, GPG detached signature status file parsing, and Authenticode.
- [x] **MSYS2 Extraction & Shell Init (`04-install-msys2.ps1`):** Extract SFX to `$HOME\msys64`, initialize first login shell, verify `bash.exe`, `pacman.exe`, and UCRT64 environment.
- [x] **UCRT64 Toolchain Provisioning (`05-install-gcc.ps1`):** Full multi-pass system update, install `mingw-w64-ucrt-x86_64-toolchain`, verify compiler target (`x86_64.*mingw32`), build and run native PE32+ C/C++ test binaries.
- [x] **Rust Standalone Downloader (`01-download-rustup.ps1`):** Authenticate Rust stable manifest (`channel-rust-stable.toml`) via Keybase Rust release key (`108F66205EAEB0AAA8DD5E1C85AB96E6FA1BE5FE`), download standalone GNU distribution.
- [x] **Rust Standalone Extractor (`02-install-rust-standalone.ps1`):** Extract archive via MSYS2 tar into temporary space, install into `$HOME\.local\rust`, verify `rustc`, `cargo`, `rustdoc`, and build debug/release Cargo test projects.
- [x] **Rust Environment Configurator (`03-configure-rust-environment.ps1`):** Backup user PATH to `$HOME\.local\rust\environment-backups/`, prepend Rust and UCRT64 bin directories, and test native Cargo builds from PowerShell.
**Exit:** Verified, modular, end-to-end installation scripts for MSYS2 UCRT64 and Rust standalone GNU.

---

## Phase 1 — Orchestration, Hardening & Documentation (Completed)

- [x] **MSYS2 Master Orchestrator (`install-msys2.ps1`):** Single-command runner with installation detection, progress reporting, fail-fast mechanics, and `-Force` reinstall flag.
- [x] **Rust Master Orchestrator (`install-rust.ps1`):** Single-command runner for three-step Rust deployment with prerequisite checks and test validation.
- [x] **Robust Error Handling & Recovery:** Partial installation cleanup (`Remove-PartialInstallation`), multi-pass pacman update loop for core MSYS2 restarts, and temporary GPG status file parsing.
- [x] **Repository Documentation Standards:**
  - [x] `AGENTS.md`: Operational guidelines, signed commit mandates, doc and hardware snapshot references.
  - [x] `README.md`: Complete user-facing guide, feature lists, quickstarts, and security details.
  - [x] `ROADMAP.md`: Project constraints, completed milestones, and future development phases.
  - [x] `HANDOFF.md`: Current runtime state, completed tasks, and operational gotchas.
**Exit:** Fully documented repository with automated orchestrators and passing verification tests.

---

## Phase 2 — Toolchain Expansion (Completed)

- [x] **Non-Admin Go Toolchain Installer (`Go-Installer/`):**
  - [x] Automated discovery and download of official `go*.windows-amd64.zip` from `https://go.dev/dl/?mode=json`.
  - [x] Cryptographic SHA-256 verification against official manifest hash.
  - [x] Non-elevated extraction to `$HOME\.local\go`.
  - [x] Persistent User PATH and `GOPATH` (`$HOME\go`) / `GOBIN` (`$HOME\go\bin`) configuration with automated PATH backup.
  - [x] Native Go build and execution verification (`go run` and `go build`).
- [x] **Non-Admin Node.js / Runtime Installer (`Node-Installer/`):**
  - [x] Automated discovery and download of official Node.js LTS x64 zip from `https://nodejs.org/dist/index.json`.
  - [x] Cryptographic SHA-256 verification against official `SHASUMS256.txt`.
  - [x] Non-elevated extraction to `$HOME\.local\node`.
  - [x] Configuration of user-level npm global prefix to `$HOME\.npm-global` with User PATH updates and automated PATH backup.
  - [x] Native Node.js and NPM execution verification (`node -e`).
- [x] **Non-Admin Python Standalone Installer (`Python-Installer/`):**
  - [x] Automated discovery and download of official 64-bit Python embeddable package and `get-pip.py`.
  - [x] SHA-256 verification against official release table.
  - [x] Extraction to `$HOME\.local\python` with `._pth` configuration enabling site-packages.
  - [x] User-level pip and setuptools bootstrapping via `get-pip.py`.
  - [x] User PATH persistent configuration and runtime verification.
- [x] **Unified Multi-Toolchain CLI Runner (`install-all.ps1`):**
  - [x] Full interactive console menu when run bare.
  - [x] Detailed `-Help` manual with synopsis, flag definitions, and real-world examples.
  - [x] Toolchain inventory inspection via `-List`.
  - [x] Single-command batch installation with `-All` or selective flags (`-MSYS2`, `-Rust`, `-Go`, `-Node`, `-Python`).
  - [x] Executive summary reporting with per-toolchain duration and status badges.
**Exit:** Multi-language developer suite operable entirely from user space.

---

## Phase 3 — Lifecycle Management & CI Automation (Future)

- [ ] **Dedicated Uninstaller Scripts:**
  - `uninstall-msys2.ps1`: Safe removal of `$HOME\msys64` with optional backup of user dotfiles.
  - `uninstall-rust.ps1`: Clean deletion of `$HOME\.local\rust` and automated restoration of original user PATH from backup files.
  - `uninstall-go.ps1`: Clean deletion of `$HOME\.local\go` and restoration of user PATH.
  - `uninstall-node.ps1`: Clean deletion of `$HOME\.local\node` and restoration of user PATH.
  - `uninstall-python.ps1`: Clean deletion of `$HOME\.local\python` and restoration of user PATH.
- [ ] **Toolchain Upgrader / Integrity Auditor:**
  - Check upstream for new MSYS2, Rust, Go, Node.js, and Python releases; perform clean in-place updates.
  - Integrity checker verifying installed binaries against checksums.
- [ ] **Headless CI Regression Testing:**
  - Automated GitHub Actions workflow running on clean Windows Server runner to test all installation scripts end-to-end without administrative elevation.
**Exit:** Self-updating, self-healing, automated non-admin developer platform.
