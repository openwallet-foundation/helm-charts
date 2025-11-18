# OpenWallet Foundation Helm Charts

This repository hosts Helm charts for projects belonging to the OpenWallet Foundation.

## Quick Start

Add the Helm repository:

```bash
helm repo add owf https://openwallet-foundation.github.io/helm-charts
helm repo update
```

Search and install charts:

```bash
helm search repo owf
helm install my-release owf/<chart-name>
```

## Development

### Development Environment

A VS Code devcontainer is available with all tools pre-installed. Open in VS Code with the Dev Containers extension or use GitHub Codespaces.

Alternatively, install tools manually—versions are pinned in `hack/versions.env`. Run `make tools-check` to verify.

### Common Tasks

All commands require `CHART=<name>` (e.g., `acapy`, `vc-authn-oidc`).

```bash
# Testing & Validation
make check CHART=acapy           # Fast (~30s): lint + docs validation (pre-PR)
make test CHART=acapy            # Full (~5m): deps + lint + template + install in kind
make lint CHART=acapy            # Chart linting (helm + yaml + maintainers + version)
make install CHART=acapy         # Install test only (in kind cluster)

# Documentation
make docs CHART=acapy            # Regenerate README from values.yaml annotations

# Tools
make tools-check                 # Verify tool versions match pins
make help                        # Show all available targets
```

**Typical workflow:**

- Use `make check` during development for fast feedback
- Run `make test` before opening PR for full validation

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines. Key requirements:

- One chart per PR
- Use Conventional Commits format (`feat:`, `fix:`, etc.)
- Run `make check CHART=<name>` before submitting
- Validate docs with `make docs CHART=<name>` when changing values
