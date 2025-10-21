---
name: New chart
about: Submit a brand new chart
labels: ["chart","new-chart"]
---

## Summary

- New Chart: <chart-name>
- Upstream app/image version: <x.y.z>

## What's included

- [ ] `charts/<chart-name>/Chart.yaml` with maintainers
- [ ] Templates follow helpers/naming conventions
- [ ] `values.yaml` annotated with `@param` for README generator
- [ ] `README.md` generated (prefer `helm-docs`, Bitnami fallback OK)
- [ ] Minimal `ci/ci-values.yaml` for chart-testing install tests
- [ ] `.helmignore` includes `ci/*.*` to exclude test files from package

## Testing

- [ ] `helm lint charts/<chart-name>` passes
- [ ] `make check CHART=<chart-name>` passes (all validations)
- [ ] `make ct-install CHART=<chart-name>` passes (install test in kind)
- [ ] (optional) `make local-test CHART=<chart-name>` (full CI simulation)

## Notes for reviewers

- Any special considerations, secrets handling, migration notes, or GitOps idempotency concerns.
