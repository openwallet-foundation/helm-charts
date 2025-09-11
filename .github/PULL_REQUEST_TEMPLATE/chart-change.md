---
name: Chart change
about: Propose changes to a single chart (required)
labels: ["chart"]
---

## Summary

- Chart: <chart-name>
- Changes:
	- Types (select all that apply): feat | fix | docs | chore | refactor | perf | test
	- Recommended PR title (preferred): `feat(<chart-name>): <short description>`
	- Alternative (accepted): `[<chart-name>] <short description>`

## What changed

- Briefly describe the changes and their intent. If multiple types are included, group by type for readability (e.g., Feat, Fix, Docs).

## Checklist

- [ ] This PR changes exactly one chart (`charts/<chart-name>`)
- [ ] No manual version bump in `Chart.yaml` (handled by Release‑PR)
- [ ] Values are annotated (`@param`) and README regenerates cleanly
	- Prefer `helm-docs`; Bitnami generator also supported via `make docs CHART=<chart-name>`
- [ ] Added/updated `charts/<chart-name>/ci/*-values.yaml` if needed for `ct`
- [ ] `make verify CHART=<chart-name>` passes locally
- [ ] If mixing multiple change types, the description clearly separates them (Feat/Fix/Docs/etc.)

## Release notes (optional)

- User-facing notes worth highlighting in the CHANGELOG.

### Examples

- `[acapy] add configurable serviceAccount`
- `fix(acapy): correct init container env var name`

