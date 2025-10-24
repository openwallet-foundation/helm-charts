---
name: New chart
about: Submit a brand new chart
labels: ["chart","new-chart"]
---

## Summary

- New Chart: <chart-name>
- Upstream app/image version: <x.y.z>

## What’s included

- [ ] `charts/<chart-name>/Chart.yaml` with maintainers
- [ ] Templates follow helpers/naming conventions
- [ ] `values.yaml` annotated for README generator
- [ ] `README.md` generated (Bitnami generator)
- [ ] Minimal `ci/ci-values.yaml` for chart-testing install

## Testing

- [ ] `helm lint charts/<chart-name>`
- [ ] `make verify CHART=<chart-name>`
- [ ] (optional) `make local-test CHART=<chart-name>`

## Notes for reviewers

- Any special considerations, secrets handling, migration notes, or GitOps idempotency concerns.
