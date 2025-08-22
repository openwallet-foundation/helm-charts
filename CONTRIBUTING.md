# Contributing to OpenWallet Foundation Helm Charts

Thank you for contributing to the OpenWallet Foundation Helm Charts repository!

To maintain clarity, consistency, and automation reliability, please follow these contribution guidelines.

## General Guidelines

- **One Chart per PR:** Each pull request (PR) must be scoped to a single chart.
  - You may introduce **one new** Helm chart, **or**
  - Modify **one existing** Helm chart.
  - Do **not** include changes for multiple charts in a single PR (this is enforced by CI).

- **Chart Location:** Create new charts under `charts/<CHART>` using a unique, meaningful name that reflects the OWF project the chart supports.

- **Chart Versioning:** Bump the chart `version` in `Chart.yaml` whenever you make changes.

- **Maintainers:** Ensure that a valid `maintainers` list is included in the chart’s `Chart.yaml`.

- **Documentation:**
  - Update the chart’s `README.md` to reflect any changes.
    - Use [`@bitnami/readme-generator-for-helm`](https://github.com/bitnami/readme-generator-for-helm).
    - Command:
      `npx @bitnami/readme-generator-for-helm --readme charts/<CHART>/README.md --values charts/<CHART>/values.yaml`
    - **Note:** CI fails the PR if `README.md` needs regeneration due to `@param` annotations in `values.yaml`.
  - Update the chart’s `CHANGELOG.md` for meaningful changes.
    - Use [`conventional-changelog-cli`](https://github.com/conventional-changelog/conventional-changelog).
    - Command:
      `npx conventional-changelog -p conventionalcommits -i charts/<CHART>/CHANGELOG.md -s`

## CI / Test-Install Values (Kind-friendly)

- To supply CI-only overrides without changing chart defaults, add one or more files under:
`charts/<CHART>/ci/*-values.yaml`

  Examples:
  - `charts/acapy/ci/ci-values.yaml`
  - `charts/acapy/ci/disable-ingress-values.yaml`
  - `charts/acapy/ci/minimal-values.yaml`

- The chart-testing tool (`ct`) **automatically discovers** and uses any files ending in `-values.yaml` in the `ci/` folder during test installs.

- **Packaging tip:** Add the following to your chart’s `.helmignore` so CI-only files aren’t included in release artifacts: `ci/**`


## CI/CD and Automation

- **Pull Requests**
- CI lints and test-installs the changed chart(s) in a temporary Kind cluster.
- **Pull Requests:** When you open a pull request, automated checks will run to ensure chart quality and compliance.
  - CI lints and test-installs the changed chart(s) in a temporary Kind cluster.
  - PRs that modify more than one chart will fail a guardrail check.

- **Publishing on merge to `main`**
  - If a chart’s `version` changed, the workflow:
    1. Packages the chart and publishes it as a **GitHub Release asset** (release name: `<name>-<version>`).
    2. Rebuilds `index.yaml` from Releases and pushes it to the `gh-pages` branch.
  - Users can use the repo like any Helm repository:
    ```bash
    helm repo add owf https://openwallet-foundation.github.io/helm-charts
    helm repo update
    helm install <release> owf/<chart> --version <x.y.z>
    ```

### Notes
- Prefer small, focused PRs.
- Keep `CHANGELOG.md` meaningful (features, fixes, breaking changes).
- Consider adding `OWNERS`/CODEOWNERS for charts you maintain.

By adhering to these rules, you help ensure a smooth, automated release process and make reviewing PRs easier for maintainers. Thank you!
