# Active Task Handoff: Windows-NonAdmin-Installers

## Current State

The repository is a fully unified non-administrator developer platform for Windows 10/11 x86-64, hosting **33 dedicated, cryptographically verified installers** and a top-level unified CLI orchestrator:

### 1. Foundation & Security Tools
1. `Gpg4win-Installer`: Provisions Gpg4win suite (`$HOME\.local\gpg4win\Gpg4win`) and official GnuPG core engine (`$HOME\.local\gpg4win\GnuPG\bin\gpg.exe`) silently without UAC prompts using `$env:__COMPAT_LAYER = 'RunAsInvoker'`.
2. `KeePassXC-Installer`: Provisions KeePassXC desktop password manager (`$HOME\.local\keepassxc\KeePassXC.exe`) and `keepassxc-cli.exe` in portable mode with OpenPGP release signature verification and Authenticode validation.

### 2. Core Language Toolchains & Modern Runtimes
3. `MSYS2-Installer`: Provisions MSYS2, UCRT64 GCC/G++, binutils, Make, and pkg-config into `$HOME\msys64`.
4. `Rust-Installer`: Provisions official Rust standalone GNU (`x86_64-pc-windows-gnu`) into `$HOME\.local\rust`.
5. `Go-Installer`: Provisions official Go compiler and tools into `$HOME\.local\go`, setting `GOROOT` and `GOPATH` (`$HOME\go`).
6. `Node-Installer`: Provisions Node.js LTS into `$HOME\.local\node` and configures user prefix at `$HOME\.npm-global`.
7. `Python-Installer`: Provisions portable Python 3 into `$HOME\.local\python`, configures site-packages, and bootstraps `pip`.
8. `Bun-CLI`: Provisions Bun all-in-one JavaScript/TypeScript runtime & package manager (`$HOME\.local\bun\bin\bun.exe`) with official `SHASUMS256.txt` verification.
9. `Deno-CLI`: Provisions Deno modern TypeScript/JavaScript runtime (`$HOME\.local\deno\bin\deno.exe`) with official `.sha256sum` verification.

### 3. Native Build Systems
10. `CMake-Installer`: Provisions CMake Portable suite (`$HOME\.local\cmake\bin\cmake.exe`, `ctest.exe`, `cpack.exe`) with official SHA-256 verification.
11. `Ninja-Installer`: Provisions Ninja build system (`$HOME\.local\ninja\bin\ninja.exe`) with SHA-256 integrity verification.

### 4. VCS & Core Terminal Utilities
12. `PortableGit-Installer`: Provisions official Git for Windows portable (`$HOME\.local\git`) with Git Bash, OpenSSH, curl, and fast 7-Zip extraction.
13. `GitHub-CLI`: Provisions official GitHub CLI (`$HOME\.local\gh\bin\gh.exe`) with SHA-256 and Authenticode validation (`GitHub, Inc.`).
14. `7Zip-Installer`: Provisions 7-Zip archiver CLI (`$HOME\.local\7zip\7z.exe`), `7z.dll`, and GUI extracted non-elevated via `msiexec /a`.
15. `Ripgrep-CLI`: Provisions ripgrep (`$HOME\.local\ripgrep\bin\rg.exe`) ultra-fast search engine with official SHA-256 validation.
16. `Fd-CLI`: Provisions fd (`$HOME\.local\fd\bin\fd.exe`) user-friendly find alternative with official SHA-256 validation.
17. `Jq-CLI`: Provisions jq (`$HOME\.local\jq\bin\jq.exe`) command-line JSON processor with official release checksum validation.
18. `Fzf-CLI`: Provisions fzf (`$HOME\.local\fzf\bin\fzf.exe`) interactive fuzzy finder with official checksum verification.
19. `Bat-CLI`: Provisions bat (`$HOME\.local\bat\bin\bat.exe`) syntax-highlighting cat clone with SHA-256 integrity verification.
20. `Delta-CLI`: Provisions git-delta (`$HOME\.local\delta\bin\delta.exe`) syntax-highlighting diff pager with SHA-256 integrity verification.
21. `Eza-CLI`: Provisions eza (`$HOME\.local\eza\bin\eza.exe`) modern ls replacement with release digest verification.
22. `Cloudflared-CLI`: Provisions Cloudflare Tunnel CLI (`$HOME\.local\cloudflared\bin\cloudflared.exe`) with official release digest verification.

### 5. Editors & Development Environments
23. `VSCode-Installer`: Provisions official VS Code Portable (`$HOME\.local\vscode\Code.exe`) with isolated `data/` directory, Authenticode validation (`Microsoft Corporation`), and zero registry pollution.

### 6. AI Developer CLIs & Agent Runtimes
24. `Cline-CLI`: Autonomous coding agent CLI installed globally in user space (`$HOME\.npm-global`).
25. `Hermes-CLI`: Nous Research Hermes Agent CLI in an isolated user virtualenv (`$HOME\.local\hermes`).
26. `Vibe-CLI`: Mistral AI Vibe coding assistant CLI in an isolated user virtualenv (`$HOME\.local\vibe`).
27. `Ori-CLI`: OpenRouter Ori CLI native Windows binary (`$HOME\.local\ori\bin\ori.exe`) verified via `SHA256SUMS`.
28. `Antigravity-CLI`: Google Antigravity CLI native Windows binary (`$HOME\.local\antigravity\bin\agy.exe`) verified via SHA-512 manifest.
29. `Copilot-CLI`: GitHub Copilot CLI (`@github/copilot`) installed in user space (`$HOME\.npm-global`).
30. `Claude-CLI`: Anthropic Claude Code CLI (`@anthropic-ai/claude-code`) installed in user space (`$HOME\.npm-global`).
31. `Aider-CLI`: Aider Pair Programmer CLI (`aider-chat`) in an isolated user virtualenv (`$HOME\.local\aider\venv`) with `bin\aider.cmd` launcher shim.
32. `Uv-CLI`: Astral uv and uvx Python package & project manager (`$HOME\.local\uv\bin\uv.exe`) verified via official SHA-256 digest.
33. `Herdr-CLI`: Herdr agent workspace runtime & terminal manager (`$HOME\.local\herdr\bin\hc.exe` / `herdr-core.exe`, ConPTY) verified via official release manifest.

### 7. Unified Orchestrator
- `install-all.ps1`: Interactive console menu, `-List` status dashboard, detailed `-Help` manual, batch flags (`-All`, `-CliTools`, individual flags for all 33 tools, `-Force`), and automatic dependency management.

---

## Completed Checklist

- [x] **Phase 0 — Core Modular Implementations:** MSYS2 & Rust modular steps.
- [x] **Phase 1 — Orchestrations & Documentation Baseline:** Master scripts and repository standards.
- [x] **Phase 2 — Toolchain Expansion:** Go, Node.js, Python, Gpg4win, KeePassXC, and `install-all.ps1`.
- [x] **Phase 2.5 — AI Developer CLIs:** Cline, Hermes, Vibe, Ori, Antigravity, Copilot.
- [x] **Phase 2.75 — Modern VCS Utilities, Search Tools, Editors & Agent Expansion:** PortableGit, GitHub CLI, 7-Zip, ripgrep, fd, jq, VS Code Portable, Claude Code, Aider.
- [x] **Phase 2.85 — Build Systems, Next-Gen Runtimes, Terminal Suite & Agent Runtime Expansion:**
  - [x] `CMake-Installer/` (cmake, ctest, cpack, official SHA-256 check, extraction, PATH config, `install-cmake.ps1`).
  - [x] `Ninja-Installer/` (ninja build system, SHA-256 check, PATH config, `install-ninja.ps1`).
  - [x] `Bun-CLI/` (bun runtime, official SHASUMS256 check, PATH config, `install-bun.ps1`).
  - [x] `Deno-CLI/` (deno runtime, official sha256sum check, PATH config, `install-deno.ps1`).
  - [x] `Uv-CLI/` (astral uv and uvx, official sha256 check, PATH config, `install-uv.ps1`).
  - [x] `Fzf-CLI/` (fzf fuzzy finder, official checksums check, PATH config, `install-fzf.ps1`).
  - [x] `Bat-CLI/` (bat cat clone, SHA-256 check, PATH config, `install-bat.ps1`).
  - [x] `Delta-CLI/` (git-delta diff pager, SHA-256 check, PATH config, `install-delta.ps1`).
  - [x] `Eza-CLI/` (eza ls replacement, release digest check, PATH config, `install-eza.ps1`).
  - [x] `Cloudflared-CLI/` (cloudflare tunnel client, release digest check, PATH config, `install-cloudflared.ps1`).
  - [x] `Herdr-CLI/` (herdr-core & hc agent runtime with ConPTY, manifest SHA-256 check, PATH config, `install-herdr.ps1`).
  - [x] `install-all.ps1` expanded to 33 tools with 6 categories, `-List` updated, `-CliTools` expanded to 9 agent runtimes.
  - [x] `README.md` and `ROADMAP.md` updated with complete tool tables and Phase 2.85 tracking.

---

## In Progress & Immediate Next Steps

1. **Remote Sync:** Commit `03944a8` pushed to `origin/master` (33 tools deployed and verified).
2. **Phase 3 Scoping:**
   - Develop dedicated uninstallation scripts (`uninstall-*.ps1`) for clean rollbacks and PATH restoration.
   - Design automated headless CI regression test workflow.

---

## Blockers & Gotchas

- **PowerShell Version:** Requires PowerShell 7 (`pwsh.exe`) with `-ExecutionPolicy Bypass`.
- **7-Zip Non-Admin MSI Extraction:** `msiexec.exe /a <msi> /qn TARGETDIR=<dir>` operates fully in user-space without UAC elevation.
- **VS Code Portable Mode:** Placing an empty `data` directory inside `$HOME\.local\vscode` directs all user configuration, caches, and extensions to remain inside the folder, preventing any writes to `%APPDATA%\Code` or the Windows Registry.
- **Deno SHA-256 Checksum Format:** Deno's Windows checksum file is produced via PowerShell format-list (`Hash : <hex>`), handled via word-boundary regex `\b([0-9a-fA-F]{64})\b`.
- **KeePassXC Password Generation Parameter:** In `keepassxc-cli generate`, password length is passed via `-L <length>` (e.g. `-L 32`), as `-l` denotes the `--lower` flag for lowercase character inclusion.
- **Node.js-based CLIs:** `Cline`, `Copilot`, and `Claude Code` require Node.js. If missing, running `..\Node-Installer\install-node.ps1` resolves this prerequisite immediately.
- **Python-based CLIs:** `Hermes`, `Vibe`, and `Aider` require Python 3.10+. If missing, running `..\Python-Installer\install-python.ps1` resolves this prerequisite immediately.
- **Environment Refresh:** Modifying the Windows Registry User `Path` takes effect immediately for new shells, but active terminal sessions must be restarted to inherit the refreshed PATH.
