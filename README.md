# Codex Optimization Kit (Linux)

This repository bootstraps a consistent Codex CLI setup across multiple Linux servers.

## What it configures

- Repomix (global npm install)
- Superpowers (global Agent Skills install)
- Global `~/.codex/AGENTS.md` (only if one does not already exist)
- `~/.local/bin` in interactive Bash PATH
- RTK detection and optional upstream installation

It does **not** sync Codex login sessions, API credentials, project files, or local MCP configuration between servers.

## Requirements

- Linux
- Bash
- Git
- Node.js and npm
- Codex CLI installed separately (recommended)

## Install

Clone this repository on each server:

```bash
git clone https://github.com/YOUR-ORG/codex-optimization-kit.git
cd codex-optimization-kit
chmod +x install.sh
./install.sh
```

To also run the upstream RTK installer:

```bash
INSTALL_RTK=1 ./install.sh
```

Review the RTK upstream installer/repository before opting in, especially on production servers.

## Verify

```bash
repomix --version
rtk --version
npx --yes skills list -g
codex --version
```

Open a new shell and restart Codex after installation.

## Existing AGENTS.md

If `~/.codex/AGENTS.md` already exists, the installer does not overwrite it. Merge the supplied `AGENTS.md` manually to preserve your own instructions.

## Repomix usage

From a project directory:

```bash
repomix --compress
```

Review `.repomixignore` and the generated output before sharing it with an AI tool. Never include secrets, credentials, `.env` files, private keys, production dumps or customer data.

## RTK compatibility

RTK must be executable on the server CPU. If it reports `Illegal instruction`, check the VM CPU model and exposed CPU flags. On Proxmox, `CPU Type: host` may expose host flags if the physical CPU supports them. Restart the VM fully after changing CPU type.

## Notes

- Run the installer separately on every server/user account where Codex CLI is used.
- Global skills and global instructions are local to that Linux user.
- Extra MCP servers are intentionally not installed automatically because their tool descriptions and outputs can add context overhead.
- Review commands before running this installer on production systems.
# codex-optimization-kit
