#!/usr/bin/env bash
set -Eeuo pipefail

# Codex CLI optimization bootstrap for Linux.
# Installs Repomix + Superpowers, deploys global instructions,
# detects RTK, and optionally installs RTK from its upstream installer.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AGENTS_FILE="$CODEX_DIR/AGENTS.md"
SOURCE_AGENTS="$SCRIPT_DIR/AGENTS.md"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

command -v bash >/dev/null 2>&1 || die "bash is required."
command -v codex >/dev/null 2>&1 || warn "Codex CLI not found in PATH. Install/login to Codex separately."
command -v git >/dev/null 2>&1 || die "Git is required. Install git and rerun."
command -v node >/dev/null 2>&1 || die "Node.js is required. Install a supported Node.js LTS release and rerun."
command -v npm >/dev/null 2>&1 || die "npm is required. Install npm and rerun."

mkdir -p "$CODEX_DIR"

log "Installing/updating Repomix globally..."
npm install -g repomix

log "Installing/updating Superpowers as global Agent Skills..."
npx --yes skills add obra/superpowers -g

# Preserve any existing global instructions. Do not silently overwrite user content.
if [[ -f "$AGENTS_FILE" ]]; then
  if cmp -s "$SOURCE_AGENTS" "$AGENTS_FILE"; then
    log "Global AGENTS.md already matches this kit."
  else
    warn "$AGENTS_FILE already exists; leaving it untouched."
    warn "Review the kit's AGENTS.md and merge it manually if you have custom instructions."
  fi
else
  install -m 0644 "$SOURCE_AGENTS" "$AGENTS_FILE"
  log "Installed global instructions: $AGENTS_FILE"
fi

# Ensure ~/.local/bin and npm global bin are discoverable in interactive bash.
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if [[ -f "$HOME/.bashrc" ]] && ! grep -Fq "$PATH_LINE" "$HOME/.bashrc"; then
  printf '\n# Codex tools\n%s\n' "$PATH_LINE" >> "$HOME/.bashrc"
  log "Added ~/.local/bin to ~/.bashrc"
fi

# RTK is deliberately detected rather than replaced blindly. If requested,
# use the upstream project's installer after the user explicitly opts in.
if command -v rtk >/dev/null 2>&1; then
  log "RTK found at: $(command -v rtk)"
  if rtk --version >/dev/null 2>&1; then
    log "RTK executable check passed."
  else
    warn "RTK is installed but cannot execute on this CPU/OS. Check CPU flags and binary compatibility."
  fi
else
  warn "RTK was not found in PATH."
  if [[ "${INSTALL_RTK:-0}" == "1" ]]; then
    command -v curl >/dev/null 2>&1 || die "curl is required to install RTK."
    warn "Running the upstream RTK installer. Review the upstream repository before enabling this on production servers."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | bash
    hash -r
    command -v rtk >/dev/null 2>&1 || warn "RTK installer completed but rtk is still not in PATH."
  else
    warn "To opt in to the upstream RTK installer, rerun: INSTALL_RTK=1 ./install.sh"
  fi
fi

log "Checking installed tools..."
command -v repomix >/dev/null 2>&1 && repomix --version || warn "Repomix command not found; check npm global bin PATH."
npx --yes skills list -g || warn "Could not list global skills; inspect the skills installer output."

if command -v codex >/dev/null 2>&1; then
  log "Codex CLI detected. Restart Codex to reload global instructions and skills."
  log "MCP servers are not added automatically; extra MCP tools can increase context overhead."
fi

cat <<'EOF'

Setup finished.

Next:
  1. Open a new shell (or run: source ~/.bashrc)
  2. Run: rtk --version
  3. Run: repomix --version
  4. Run: codex

For a large repository:
  cd /path/to/repository
  repomix --compress

RTK is only usable if its binary supports the server's CPU instruction set.
EOF
