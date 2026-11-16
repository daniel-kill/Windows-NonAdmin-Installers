# Environment Context

User-local development and AI-agent host. Prefer existing tools and user-local installs; do not assume sudo/root access.

## Operating Guidance

- Prefer `~/.local/bin` and `~/.local/share` for user-local software.
- Check existing commands before installing replacements.
- Installation/rebuild commands are recorded in `~/_CONFIGURATION.md`.
- Agent-specific documentation is under `~/Repos/agents-docs/`; consult it before guessing an agent CLI's commands or behavior.
- Database servers are configured for local access only unless their configuration explicitly says otherwise.

## Available CLI Tools
- `git` — version control (git 2.53.0)
- `curl` — HTTP client (curl 8.18.0)
- `tmux` — terminal multiplexer (tmux 3.6)
- `rsync` — file synchronization (rsync 3.4.1)
- `git-utils` — Git repository utilities
- `sh-confirm` — shell formatter and validator
- `py-confirm` — Python script syntax and linter validator

## Languages & Runtimes
- `python3` — Python (python3 3.14.4)
- `uv` — Python package/tool manager (uv 0.13.4)
- `node` — Node.js (node 24.22.1)
- `npm` — Node package manager (npm 11.19.1)
- `go` — Go (go 1.27.3)
- `rustc` — Rust compiler (rustc 1.99.1)
- `cargo` — Rust package manager (cargo 1.99.1)
- `pwsh` — PowerShell (pwsh 7.6.6)

## Native Development Toolchain
- `cmake` — cross-platform build generator (cmake 4.5.0)
- `make` — GNU Make build executor (make 4.4.1)
- `cc` — compatibility alias for the user-local C compiler
- `c++` — compatibility alias for the user-local C++ compiler
- `gcc` — compatibility alias for Clang; not a GNU GCC installation
- `g++` — compatibility alias for Clang++; not a GNU G++ installation

## Databases

## AI Agents

## Hermes Agent

- Home: `/home/daniel/.hermes`
- Config: `/home/daniel/.hermes/config.yaml`
- Identity: `/home/daniel/.hermes/SOUL.md`
- Memory: `/home/daniel/.hermes/memories/`
- Plugins: `/home/daniel/.hermes/plugins/`

## Reference

- `~/_CONFIGURATION.md` — installation and rebuild commands; not the primary agent context.
- Regenerate this file after changing installed tools, runtimes, agents, databases, native toolchains, or Hermes plugins.

## Manual Notes

<!-- MANUAL:START -->
<!-- Add durable environment-specific notes here. This block is preserved on regeneration. -->
<!-- MANUAL:END -->
