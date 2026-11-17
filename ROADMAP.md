# Roadmap: Windows-NonAdmin-Installers

## Goal & Constraints

- **Primary Objective:** Provide automated, fully non-elevated (zero-administrator) developer toolchain and AI agent CLI installers for Windows 10/11 x86-64 using PowerShell 7, guaranteeing end-to-end cryptographic verification and zero pollution of machine-wide system state.
- **Key Constraints:**
  - **Zero Elevation:** Under no circumstances should scripts invoke UAC, require Administrator group membership, or modify system-wide machine registries.
  - **Local Scope:** All binaries, toolchains, caches, and configuration must reside strictly within `$HOME` (`$HOME\msys64`, `$HOME\.local\...`, `$HOME\.npm-global`).
  - **Strict Cryptographic Authentication:** Pinned OpenPGP primary key fingerprints, detached signature verification (`GOODSIG`/`VALIDSIG`), SHA-256 / SHA-512 release checksum verification, and Authenticode signature checks prior to execution.
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

## Phase 2 — Toolchain & Dependency Expansion (Completed)

- [x] **Non-Admin Gpg4win & GnuPG Foundation Installer (`Gpg4win-Installer/`):**
  - [x] Automated discovery and download of official Gpg4win installer and detached signature.
  - [x] Cryptographic SHA-256 verification and Authenticode inspection.
  - [x] Silent non-elevated installation into `$HOME\.local\gpg4win` via `RunAsInvoker`.
  - [x] Persistent User PATH update adding GnuPG (`gpg.exe`) and Gpg4win (`kleopatra.exe`).
- [x] **Non-Admin KeePassXC & CLI Installer (`KeePassXC-Installer/`):**
  - [x] Automated discovery of latest release from GitHub API, with sidecar `.DIGEST` and `.sig` downloads.
  - [x] Cryptographic SHA-256 verification against official digest and OpenPGP detached signature authentication via pinned release key (`BF5A669F2272CF4324C1FDA8CFB4C2166397D0D2`).
  - [x] Portable non-elevated deployment to `$HOME\.local\keepassxc` with `.portable` configuration marker.
  - [x] Authenticode digital signature validation (`DroidMonkey Apps, LLC`) on `KeePassXC.exe` and `keepassxc-cli.exe`.
  - [x] Persistent User PATH configuration and CLI execution/functional verification.
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
  - [x] Single-command batch installation with `-All` or selective flags.
  - [x] Automatic dependency checking (GnuPG prerequisite for MSYS2/Rust).
**Exit:** Multi-language developer suite and foundational cryptographic tools operable entirely from user space.

---

## Phase 2.5 — AI Developer CLI Expansion (Completed)

- [x] **Cline CLI Installer (`Cline-CLI/`):**
  - [x] Node.js prerequisite inspection.
  - [x] User-local `npm install -g cline` directed to `$HOME\.npm-global`.
  - [x] User PATH configuration and `cline --version` verification.
- [x] **Hermes Agent CLI Installer (`Hermes-CLI/`):**
  - [x] Python prerequisite inspection.
  - [x] Isolated virtualenv / pip installation of `hermes-agent` under `$HOME\.local\hermes`.
  - [x] Launcher shim `hermes.cmd` in `$HOME\.local\hermes\bin` and User PATH update.
- [x] **Mistral Vibe CLI Installer (`Vibe-CLI/`):**
  - [x] Python 3.11+ prerequisite inspection.
  - [x] Isolated virtualenv / pip installation of `mistral-vibe` under `$HOME\.local\vibe`.
  - [x] Launcher shim `vibe.cmd` in `$HOME\.local\vibe\bin` and User PATH update.
- [x] **OpenRouter Ori CLI Installer (`Ori-CLI/`):**
  - [x] Automated download of official native binary `ori-windows-x64.exe` and `SHA256SUMS`.
  - [x] Cryptographic SHA-256 verification.
  - [x] Installation under `$HOME\.local\ori\bin\ori.exe` and User PATH update.
- [x] **Google Antigravity CLI Installer (`Antigravity-CLI/`):**
  - [x] Automated query of official release manifest (`windows_amd64.json`).
  - [x] Cryptographic SHA-512 verification of native binary `cli_windows_x64.exe`.
  - [x] Installation under `$HOME\.local\antigravity\bin\agy.exe` and User PATH update.
- [x] **GitHub Copilot CLI Installer (`Copilot-CLI/`):**
  - [x] Node.js prerequisite inspection.
  - [x] User-local `npm install -g @github/copilot` directed to `$HOME\.npm-global`.
  - [x] User PATH configuration and `copilot --version` verification.
- [x] **Integrated CLI Provisioning:**
  - [x] Added `-CliTools` flag and dedicated interactive menu options in `install-all.ps1`.
**Exit:** Complete autonomous coding agent CLI suite provisioned without administrator rights.

---

## Phase 2.75 — Modern VCS Utilities, Search Tools, Editors & Agent Expansion (Completed)

- [x] **Non-Admin PortableGit Installer (`PortableGit-Installer/`):**
  - [x] Automated discovery and download of official 64-bit PortableGit (`.7z.exe`).
  - [x] SHA-256 release digest calculation and verification.
  - [x] High-speed non-elevated extraction via `7z.exe` into `$HOME\.local\git`.
  - [x] Persistent User PATH update (`bin\`, `cmd\`, `usr\bin\`) with automated backup and `git --version` verification.
- [x] **Non-Admin GitHub CLI Installer (`GitHub-CLI/`):**
  - [x] Automated discovery of official `gh_*_windows_amd64.zip` and `checksums.txt`.
  - [x] Cryptographic SHA-256 verification and Authenticode digital signature check (`GitHub, Inc.`).
  - [x] Non-elevated extraction to `$HOME\.local\gh\bin\gh.exe`, User PATH configuration, and `gh --version` verification.
- [x] **Non-Admin 7-Zip Console & Suite Installer (`7Zip-Installer/`):**
  - [x] Automated discovery of official `7z*-x64.msi`.
  - [x] SHA-256 verification and non-elevated administrative extraction (`msiexec.exe /a ... /qn TARGETDIR=...`) into `$HOME\.local\7zip`.
  - [x] User PATH configuration, PATH backup, and functional `7z.exe` test.
- [x] **Non-Admin ripgrep CLI Installer (`Ripgrep-CLI/`):**
  - [x] Automated discovery of official `ripgrep-*-x86_64-pc-windows-msvc.zip` and `.sha256`.
  - [x] Cryptographic SHA-256 verification and extraction to `$HOME\.local\ripgrep\bin\rg.exe`.
  - [x] User PATH configuration and `rg --version` test.
- [x] **Non-Admin fd CLI Installer (`Fd-CLI/`):**
  - [x] Automated discovery of official `fd-*-x86_64-pc-windows-msvc.zip`.
  - [x] SHA-256 release verification and extraction to `$HOME\.local\fd\bin\fd.exe`.
  - [x] User PATH configuration and `fd --version` test.
- [x] **Non-Admin jq CLI Installer (`Jq-CLI/`):**
  - [x] Automated discovery of official `jq-win64.exe` and release hash.
  - [x] SHA-256 verification and installation to `$HOME\.local\jq\bin\jq.exe`.
  - [x] User PATH configuration and JSON query functional test (`jq -n '{"status": "ok"}'`).
- [x] **Non-Admin VS Code Portable Installer (`VSCode-Installer/`):**
  - [x] Automated resolution of Microsoft direct download URL for Windows x64 zip.
  - [x] Extraction via 7-Zip into `$HOME\.local\vscode`.
  - [x] Portable mode activation via dedicated `data/` directory (zero machine registry or `%APPDATA%` writes).
  - [x] Authenticode digital signature validation (`Microsoft Corporation`).
  - [x] User PATH configuration (`bin\code.cmd`), PATH backup, and `code -v` test.
- [x] **Non-Admin Claude Code CLI Installer (`Claude-CLI/`):**
  - [x] Node.js runtime prerequisite validation.
  - [x] User-local npm global installation (`npm install -g @anthropic-ai/claude-code`) directed to `$HOME\.npm-global`.
  - [x] User PATH configuration and `claude -v` test.
- [x] **Non-Admin Aider Pair Programmer CLI Installer (`Aider-CLI/`):**
  - [x] Python 3.10+ and Git prerequisite verification.
  - [x] Provisioning of isolated virtualenv at `$HOME\.local\aider\venv`.
  - [x] Installation of `aider-chat` with launcher shim `bin\aider.cmd`.
  - [x] User PATH configuration and `aider --version` test.
- [x] **Unified Multi-Toolchain CLI Runner (`install-all.ps1`) Expansion:**
  - [x] Expanded toolchain inventory to 22 tools across 5 logical categories.
  - [x] Added dedicated flags: `-Git`, `-Gh`, `-SevenZip`, `-Ripgrep`, `-Fd`, `-Jq`, `-VSCode`, `-Claude`, `-Aider`.
  - [x] Updated interactive console menu and `-List` status dashboard.
**Exit:** Comprehensive modern development environment with VCS, search utilities, portable IDE, and complete AI agent suite fully operable without administrator rights.

---

## Phase 2.85 — Build Systems, Next-Gen Runtimes, Terminal Suite & Agent Runtime Expansion (Completed)

- [x] **Non-Admin CMake Portable Installer (`CMake-Installer/`):**
  - [x] Automated discovery and download of official `cmake-*-windows-x86_64.zip` and `cmake-*-SHA-256.txt`.
  - [x] Cryptographic SHA-256 verification against official digest.
  - [x] Extraction and deployment to `$HOME\.local\cmake` with PATH backup and `cmake --version` verification.
- [x] **Non-Admin Ninja Build System Installer (`Ninja-Installer/`):**
  - [x] Automated discovery and download of official `ninja-win.zip`.
  - [x] SHA-256 integrity calculation and deployment to `$HOME\.local\ninja\bin\ninja.exe`.
  - [x] User PATH configuration with automated backup and `ninja --version` verification.
- [x] **Non-Admin Bun Runtime Installer (`Bun-CLI/`):**
  - [x] Automated discovery and download of official `bun-windows-x64.zip` and `SHASUMS256.txt`.
  - [x] Cryptographic SHA-256 verification against official digest.
  - [x] Deployment to `$HOME\.local\bun\bin\bun.exe` with PATH backup and `bun --version` verification.
- [x] **Non-Admin Deno Runtime Installer (`Deno-CLI/`):**
  - [x] Automated discovery and download of official `deno-x86_64-pc-windows-msvc.zip` and `.sha256sum`.
  - [x] Cryptographic SHA-256 verification against official release hash.
  - [x] Deployment to `$HOME\.local\deno\bin\deno.exe` with PATH backup and `deno --version` verification.
- [x] **Non-Admin Astral uv Python Package Manager (`Uv-CLI/`):**
  - [x] Automated discovery and download of official `uv-x86_64-pc-windows-msvc.zip` and `.sha256`.
  - [x] Cryptographic SHA-256 verification.
  - [x] Deployment to `$HOME\.local\uv\bin` (`uv.exe` and `uvx.exe`) with PATH backup and verification.
- [x] **Non-Admin fzf Fuzzy Finder Installer (`Fzf-CLI/`):**
  - [x] Automated discovery and download of official `fzf-*-windows_amd64.zip` and `checksums.txt`.
  - [x] Cryptographic SHA-256 verification against official checksum list.
  - [x] Deployment to `$HOME\.local\fzf\bin\fzf.exe` with PATH backup and `fzf --version` verification.
- [x] **Non-Admin bat Cat Clone Installer (`Bat-CLI/`):**
  - [x] Automated discovery and download of official `bat-*-x86_64-pc-windows-msvc.zip`.
  - [x] SHA-256 integrity calculation and deployment to `$HOME\.local\bat\bin\bat.exe`.
  - [x] User PATH configuration with automated backup and `bat --version` verification.
- [x] **Non-Admin git-delta Pager Installer (`Delta-CLI/`):**
  - [x] Automated discovery and download of official `delta-*-x86_64-pc-windows-msvc.zip`.
  - [x] SHA-256 integrity calculation and deployment to `$HOME\.local\delta\bin\delta.exe`.
  - [x] User PATH configuration with automated backup and `delta --version` verification.
- [x] **Non-Admin eza Modern ls Installer (`Eza-CLI/`):**
  - [x] Automated discovery of official `eza.exe_x86_64-pc-windows-gnu.zip` and release notes SHA-256 parsing.
  - [x] Cryptographic SHA-256 verification.
  - [x] Deployment to `$HOME\.local\eza\bin\eza.exe` with PATH backup and `eza --version` verification.
- [x] **Non-Admin Cloudflare Tunnel CLI Installer (`Cloudflared-CLI/`):**
  - [x] Automated discovery of official `cloudflared-windows-amd64.exe` and release notes SHA-256 parsing.
  - [x] Cryptographic SHA-256 verification.
  - [x] Deployment to `$HOME\.local\cloudflared\bin\cloudflared.exe` with PATH backup and `cloudflared --version` verification.
- [x] **Non-Admin Herdr AI Agent Runtime & Terminal Installer (`Herdr-CLI/`):**
  - [x] Automated query of official Herdr release manifest (`latest.json`).
  - [x] Cryptographic SHA-256 verification of `herdr-core-*-windows-x86_64.zip`.
  - [x] Deployment of `herdr-core.exe`, `hc.exe`, and ConPTY into `$HOME\.local\herdr\bin`.
  - [x] User PATH configuration with automated backup and `hc --version` verification.
- [x] **Unified Multi-Toolchain CLI Runner (`install-all.ps1`) Expansion:**
  - [x] Expanded toolchain inventory to **33 tools** across 6 logical categories.
  - [x] Added dedicated flags: `-Cmake`, `-Ninja`, `-Bun`, `-Deno`, `-Uv`, `-Fzf`, `-Bat`, `-Delta`, `-Eza`, `-Cloudflared`, `-Herdr`.
  - [x] Updated interactive console menu, `-List` dashboard, and `-CliTools` bundle to 9 AI agent runtimes.
**Exit:** Comprehensive non-admin workstation offering build systems, next-gen runtimes, advanced terminal navigation, local tunneling, and AI agent runtime environments.

---

## Phase 3 — Lifecycle Management & CI Automation (Future)

- [ ] **Dedicated Uninstaller Scripts:**
  - `uninstall-*.ps1` for clean removal and automated user PATH restoration.
- [ ] **Toolchain Upgrader / Integrity Auditor:**
  - Upstream release checkers and clean in-place update orchestrators.
- [ ] **Headless CI Regression Testing:**
  - Automated GitHub Actions workflow running on clean Windows Server runner to test all installation scripts end-to-end without administrative elevation.
**Exit:** Self-updating, self-healing, automated non-admin developer platform.
