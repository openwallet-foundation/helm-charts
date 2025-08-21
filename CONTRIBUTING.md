# Contributing to OpenWallet Foundation Helm Charts

Thank you for contributing to the OpenWallet Foundation Helm Charts repository!

To maintain clarity, consistency, and automation reliability, please follow these contribution guidelines:

## General Guidelines

- **One Chart per PR:** Each pull request (PR) must be scoped to a single chart:
  - You may introduce one new Helm chart.
  - Or you may modify an existing Helm chart.
  - Do **not** include changes for multiple charts in a single PR.

- **Chart Location:** Create new charts in the `charts/` directory using a unique, meaningful name that reflects the OWF project the chart supports.

- **Chart Versioning:** Bump the chart `version` in `Chart.yaml` whenever you make changes.

- **Maintainers:** Ensure that a valid `maintainers` list is included in the chart’s `Chart.yaml`.

- **Documentation:**
  - Update the chart's `README.md` to reflect any changes.
    - Use [`@bitnami/readme-generator-for-helm`](https://github.com/bitnami/readme-generator-for-helm) to keep documentation consistent. Run `npx @bitnami/readme-generator-for-helm --readme charts/<CHART>/README.md --values charts/<CHART>/values.yaml` after modifying `values.yaml` with `@param` annotations.
    - **Note:** CI will fail the PR if `README.md` requires updates due to `values.yaml` changes.
  - Update the chart's `CHANGELOG.md` with a description of the changes.
    - Use [`conventional-changelog-cli`](https://github.com/conventional-changelog/conventional-changelog) to generate changelogs. Run `npx conventional-changelog -p conventionalcommits -i charts/<CHART>/CHANGELOG.md -s` for significant changes (e.g., features, bug fixes).

## CI/CD and Automation

- All charts are automatically linted and tested on pull requests.
- On merge to `main`, any changed charts are automatically published to GitHub Pages.
- **CI override values**: To make KIND-safe CI installs pass without changing chart defaults, you may add an optional `values.ci.yaml` in the chart directory. This file is only used by CI during test installs and should be excluded from packaging via `.helmignore`.

By adhering to these rules, you help ensure a smooth, automated release process and make reviewing PRs easier for maintainers. Thank you!
