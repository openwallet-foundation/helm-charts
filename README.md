# OpenWallet Foundation Helm Charts

This repository hosts Helm charts for projects belonging to the OpenWallet Foundation.

See `CONTRIBUTING.md` for guidelines on contributing new or updated charts.

## Development

### Shared script utilities

Scripts under `hack/` use a small logging helper `hack/lib/log.sh` for consistent messages. Source it and use:
- `log_info`, `log_warn`, `log_error`, `die`

### Tool versions

All tool versions (Helm, kubectl, kind, yq, jq, helm-docs, yamllint, shellcheck, shfmt, ct, chart-releaser, Node generators) are pinned in `hack/versions.env` and validated with `make tools-check`.

### Local CI-like testing

- Run quick local smoke for one chart (deps + lint + template + ct install):
	- `make local-test CHART=<name>`

### Local workflow testing (optional, with act)

You can dry-run GitHub workflows locally using `act`.

1) Install act: https://github.com/nektos/act
2) Pick a chart and run:

```
make act-pr CHART=acapy        # simulate PR workflow for a single chart
make act-push CHART=acapy      # simulate push detection

# Or directly:
DETECT_CHART=acapy act pull_request -j lint-test -W .github/workflows/ci-cd.yaml --container-architecture linux/amd64
```

Notes:
- The composite action `detect-chart` honors `DETECT_CHART` to select a chart in local runs.
- The real CI pins tool versions via `hack/versions.env`; act uses container-provided tools.
