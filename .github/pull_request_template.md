## Summary

Provide a short description of the change. This repo enforces one chart per PR.

Title convention (preferred): `feat(<chart>): <short description>`
Alternative (accepted): `[<chart>] <short description>`

- Chart: <chart-name>
- Type: feat | fix | chore | docs | refactor | perf | test

## Details

- What changed and why
- Any upgrade/rollback notes

## Checks

- [ ] One chart only (`charts/<chart-name>`) changed
- [ ] No manual `Chart.yaml` version bump
- [ ] README regenerates from values annotations (prefer `helm-docs`; Bitnami generator also supported)
- [ ] `make verify CHART=<chart-name>` passes locally

## Release PR considerations

- The Release‑PR workflow will compute the bump and open a PR.
- Consider adding a chart scope in the PR title for readability, e.g. `feat(<chart>): ...`.
