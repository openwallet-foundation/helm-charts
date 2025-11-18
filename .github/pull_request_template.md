## Summary

Provide a short description of the change. Please keep your PR focused on a single chart.

**PR Title:** `<type>(<chart>): <short description>`
Examples: `feat(acapy): add configurable serviceAccount`, `fix(vc-authn-oidc): correct env var name`- **Chart:** `<chart-name>`
- **Type:** feat | fix | chore | docs | refactor | perf | test

## Details

- What changed and why
- Any upgrade/rollback notes

## Checklist

- [ ] Changes are focused on a single chart (`charts/<chart-name>`)
- [ ] No manual version bump in `Chart.yaml` (handled by Release PR automation)
- [ ] Values are annotated (`@param`) and README regenerates cleanly
  - Run: `make docs CHART=<chart-name>`
- [ ] Added/updated `charts/<chart-name>/ci/*-values.yaml` if needed for `ct`
- [ ] `make check CHART=<chart-name>` passes locally

### For new charts only:

- [ ] `Chart.yaml` includes maintainers
- [ ] Templates follow helpers/naming conventions
- [ ] Minimal `ci/ci-values.yaml` for chart-testing install

## Release notes (optional)

User-facing notes worth highlighting in the CHANGELOG.

---

## For Maintainers (post-merge)

**If this change should NOT trigger an immediate release:**

When the automated Release PR is created (e.g., `release/acapy-vX.Y.Z`), add the `skip-release` label to defer publishing. This allows accumulating multiple changes before release.

**Note:** The label is applied to the **Release PR**, not this PR.
