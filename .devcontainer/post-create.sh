#!/usr/bin/env bash
# shell safety: attempt strict modes, degrade gracefully if shell lacks pipefail
set -euo pipefail 2>/dev/null || set -euo || set -eu

echo "[post-create] Verifying tool versions..."
versions || true

echo "[post-create] Installing project (npm) dev dependencies if package.json exists (none currently)."
if [ -f package.json ]; then
  npm install --no-audit --no-fund
fi

echo "[post-create] Install CLI shims and persist prompt/completion in ~/.bashrc."
bash hack/dev/install-cli.sh || true

# Ensure PATH includes common user-local/bin locations for shims (idempotent)
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' /home/vscode/.bashrc 2>/dev/null; then
  echo '[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.bashrc
fi
if ! grep -q 'export PATH="/workspace/.bin:$PATH"' /home/vscode/.bashrc 2>/dev/null; then
  echo '[ -d "/workspace/.bin" ] && export PATH="/workspace/.bin:$PATH"' >> /home/vscode/.bashrc
fi

# Persist prompt & completion sourcing (idempotent)
if ! grep -q 'hack/dev/bash-prompt.sh' /home/vscode/.bashrc 2>/dev/null; then
  echo '. /workspace/hack/dev/bash-prompt.sh' >> /home/vscode/.bashrc
fi
if ! grep -q 'hack/dev/bash-completion.sh' /home/vscode/.bashrc 2>/dev/null; then
  echo '. /workspace/hack/dev/bash-completion.sh' >> /home/vscode/.bashrc
fi

echo "[post-create] Creating local helm repo cache directories..."
mkdir -p /home/vscode/.cache/helm /home/vscode/.cache/ct

echo "[post-create] Done. Run 'make help' for available targets."
