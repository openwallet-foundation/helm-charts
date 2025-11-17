# Contributing to OpenWallet Foundation Helm Charts

Thank you for contributing to the OpenWallet Foundation Helm Charts repository!

To maintain clarity, consistency, and automation reliability, please follow these contribution guidelines.

## General Guidelines

- **Keep PRs focused:** Focus each PR on a single chart - introduce a new chart or modify an existing one. CI will validate this for you.

- **Chart location:** Create new charts under `charts/<CHART>` with a meaningful name that reflects the OWF project.

- **Chart versioning:** Don't bump the chart `version` in `Chart.yaml` - automation handles version increments.

- **Maintainers:** Include a valid `maintainers` list in your chart's `Chart.yaml`.

- **Documentation:**
  - Keep `values.yaml` annotations current - CI validates README generation
  - Regenerate README with: `make docs CHART=<CHART>`
  - Don't edit `CHANGELOG.md` manually - automation generates it from commits
  - New scripts should use shared logging helpers from `hack/lib/log.sh`
  - Tool versions are pinned in `hack/versions.env` (validated by CI)

## How to Contribute

<details>
<summary><strong>For Contributors</strong></summary>

If you're new to GitHub collaboration, see [GitHub's guide on forking and pull requests](https://docs.github.com/en/get-started/quickstart/contributing-to-projects).

1. **(Optional)** Open an issue first for significant changes (new features, major refactors, breaking changes)
2. Fork the repository and create a feature branch: `git checkout -b fix/acapy-health-probe`
3. Make your changes
   - Follow existing patterns and conventions
   - Update `values.yaml` annotations if adding/changing parameters
   - Add or update `ci/*-values.yaml` if install tests need specific overrides
4. Test locally (see [Testing & Validation](#testing--validation) section below)
5. Commit with DCO sign-off: `git commit -s -m "fix(acapy): resolve health probe timeout"`
   - The `-s` flag is required for Linux Foundation projects ([DCO](https://developercertificate.org/))
   - Use Conventional Commits format: `feat:`, `fix:`, `docs:`, `chore:`
   - Scope is optional in commits, but include the chart name in PR titles: `feat(acapy): add health probe`
6. Open a Pull Request from your fork to `main`
   - Provide a clear description of what changed and why
   - Address CI feedback and review comments
7. Maintainer merges your PR
   - Version bumping and publishing is handled by maintainers
   - Your contribution will be included in the next release
</details>

<details>
<summary><strong>For Maintainers</strong></summary>

1. **Review and merge feature PRs**
   - Ensure CI passes and changes follow conventions
   - Merge to `main` when ready

2. **Manage Release PRs** (opened automatically by workflow)
   - Review generated version bumps and changelogs
   - Apply labels to control release behavior:
     - `bump:major`, `bump:minor`, `bump:patch` - override automatic version calculation
     - `skip-release` - accumulate more changes before releasing
   - Merge Release PR to trigger publishing

After a feature PR merges, the Release-PR workflow runs (2 AM UTC or on push to main) and opens a Release PR with bumped version and generated changelog.

**To defer release:** Add `skip-release` label to the Release PR (not the feature PR). More changes can accumulate. When ready, remove the label or close the PR to create a new one with all accumulated commits.

**To release immediately:** Review and merge the Release PR. Publishing triggers automatically.
</details>

## Testing & Validation

A devcontainer is provided to assist with local development and testing.
A `Makefile` is included to simplify common tasks.
All testing commands require `CHART=<name>` parameter (e.g., `acapy`, `vc-authn-oidc`, `endorser-service`).

```bash
make check CHART=acapy           # Fast (~30s): lint + docs validation
make test CHART=acapy            # Full (~5m): deps + lint + template + install
make lint CHART=acapy            # Lint only (helm + yaml + maintainers + version)
make install CHART=acapy         # Install test only (requires kind cluster)
make docs CHART=acapy            # Regenerate/validate README
```

Pre-commit hooks are available to catch common issues before pushing - run `pre-commit install` to enable them.
