#!/usr/bin/env bash
# shell safety: attempt strict modes, degrade gracefully if shell lacks pipefail
set -euo pipefail 2>/dev/null || set -euo || set -eu

echo "[post-create] Verifying tool versions..."
versions || true

echo "[post-create] Installing project (npm) dev dependencies if package.json exists (none currently)."
if [ -f package.json ]; then
  npm install --no-audit --no-fund
fi

# Ensure PATH includes common user-local/bin locations for shims (idempotent)
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' /home/vscode/.bashrc 2>/dev/null; then
  echo '[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.bashrc
fi
if ! grep -q 'export PATH="/workspace/.bin:$PATH"' /home/vscode/.bashrc 2>/dev/null; then
  echo '[ -d "/workspace/.bin" ] && export PATH="/workspace/.bin:$PATH"' >> /home/vscode/.bashrc
fi

# Persist prompt sourcing (idempotent)
if ! grep -q 'hack/dev/bash-prompt.sh' /home/vscode/.bashrc 2>/dev/null; then
  echo '. /workspace/hack/dev/bash-prompt.sh' >> /home/vscode/.bashrc
fi

echo "[post-create] Creating local helm repo cache directories..."
mkdir -p /home/vscode/.cache/helm /home/vscode/.cache/ct

echo "[post-create] Installing pre-commit hooks..."
if [ -f /workspace/.pre-commit-config.yaml ]; then
  cd /workspace || exit 1
  pre-commit install --install-hooks || echo "[warn] pre-commit install failed (non-fatal)"
  pre-commit install --hook-type commit-msg || echo "[warn] pre-commit commit-msg hook install failed (non-fatal)"
  echo "[post-create] Pre-commit hooks installed successfully"
else
  echo "[warn] No .pre-commit-config.yaml found; skipping pre-commit setup"
fi

# Check mount status and provide helpful warnings
echo "[post-create] Checking mount status..."
if [ ! -e /home/vscode/.gitconfig ]; then
  echo "[warn] ~/.gitconfig not mounted (host file may not exist)"
  echo "[warn] You may need to configure git identity: git config --global user.name/user.email"
fi
if [ ! -d /home/vscode/.kube ]; then
  echo "[info] ~/.kube not mounted (expected if no host kubeconfig exists)"
fi

# Wait for Docker daemon to be ready (for kind cluster testing)
echo "[post-create] Waiting for Docker daemon..."
timeout=30
elapsed=0
while ! docker info >/dev/null 2>&1; do
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "[warn] Docker daemon not ready after ${timeout}s (kind tests may fail)"
    break
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done
if docker info >/dev/null 2>&1; then
  echo "[post-create] Docker daemon ready"
fi

echo "[post-create] Done."
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║       OpenWallet Foundation Helm Charts Devcontainer      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Quick commands:"
echo "  make help                    - See all commands"
echo "  make check CHART=<name>      - Validate chart (lint, format)"
echo "  make install CHART=<name>    - Full install test in kind"
echo "  make docs CHART=<name>       - Regenerate README"
echo ""
echo "Documentation:"
echo "  CONTRIBUTING.md - Contribution guide"
echo ""
