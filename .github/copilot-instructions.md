# Copilot Guardrails — OWF Helm Charts

## 1) Repository & Project Context

* **Repo purpose:** Centralized Helm charts for OpenWallet Foundation (Linux Foundation project). Publishes versioned charts to GitHub Releases via Chart Releaser and updates a `gh-pages` index. Used by multiple teams/projects (e.g., AcaPy, vc-authn-oidc, bc-wallet components) across multiple clusters (OpenShift, AKS) with GitOps tooling (Argo CD).
* **Key expectations:**

  * Multi‑project, multi‑team development with strong CI/CD.
  * Reproducible, well‑documented workflows.
  * Conventional Commits, clear CHANGELOGs, and semantic versioning.
  * Secure handling of secrets and deterministic templates for GitOps upgrades.

## 2) Code & Content That Lives Here

* **Helm charts** under `charts/<name>` with standard structure.
* **Composite actions & workflows** under `.github/actions/` and `.github/workflows/`.
* **Automation helpers** (scripts, linters, docs generators).

## 3) Design Principles

1. **Determinism:** Same inputs → same rendered manifests. Avoid nondeterministic generators at deploy time.
2. **Least surprise:** Follow upstream chart patterns (helpers, naming, labels, annotations).
3. **Separation of concerns:** Authoring vs. releasing vs. consuming charts are distinct stages.
4. **Docs as code:** READMEs and CHANGELOGs are generated/validated from sources of truth (values, commits).
5. **Security first:** No plaintext secrets; avoid auto‑rotate in ways that break idempotent GitOps upgrades.

## 4) Contributor Workflow (High Level)

* **Branches/PRs:** One chart per PR when possible. Keep changes narrowly scoped.
* **Commits:** Use **Conventional Commits** (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, etc.).
* **Tests:** Run lint & install tests with chart-testing (ct). Include minimal `values.ci.yaml`/`ci/*-values.yaml` for install tests.
* **Docs:** Keep chart `values.yaml` annotated; README regenerated via generator.
* **DCO/Sign‑off:** Required for Linux Foundation projects.

## 5) Versioning & Changelog Policy

* **SemVer for charts** (affects `charts/<name>/Chart.yaml: version`).
* **`appVersion`** reflects upstream app image version; **chart `version`** reflects chart changes.
* **CHANGELOG** follows Conventional Commits categories and is generated/validated.

### Automation Patterns (choose one per repository)

Copilot **must not invent** a pattern—only modify in line with the selected pattern below and existing workflows.

**A) Validate‑only (developer‑driven):**

* Developer bumps `Chart.yaml` version and updates CHANGELOG in PR.
* CI validates version bump + changelog + README regeneration.
* Pros: explicit; no force‑pushes. Cons: higher contributor burden.

**B) Bot‑driven bump on merge (maintainer‑driven):**

* On PR merge to `main`, a workflow determines the next version from commit history (Conventional Commits), updates `Chart.yaml` and CHANGELOG on `main`, then runs packaging/release.
* Pros: low burden for contributors. Cons: requires trusted automation pushing to `main`; needs careful race‑condition handling for multiple concurrent chart changes.

**C) Release‑PR model (recommended for busy repos):**

* A release bot opens a **Release PR** per chart with computed version + generated CHANGELOG; humans review/merge; merge triggers packaging.
* Pros: transparent, reviewable diffs; avoids direct pushes to `main`. Cons: extra bot PR noise.

> **Repository decision:** *Default to (C) Release‑PR model for multi‑team scaling unless explicitly overridden in repo docs.*

## 6) Publishing (Chart Releaser)

* Use chart‑releaser (CR) to package and upload charts to GitHub Releases and update `gh-pages` index.
* Ensure single‑chart scope per PR to simplify detection and packaging (`detect-chart` composite action).
* \$1
* We do not publish OCI charts; do not suggest `helm push oci://` or GitHub Packages for charts.

## 7) Linting, Testing, and Docs

* **Lint:** `helm lint` + schema checks.
* **Install tests:** `ct install` against a kind cluster with `ci/*-values.yaml` to keep tests fast and minimal.
* **Docs:** Use Bitnami readme generator (or helm-docs) to regenerate chart README from `values.yaml` annotations. Add a CI step that fails if README drift is detected.
* **CHANGELOG:** Generated via conventional‑changelog or equivalent; avoid duplicate historical entries by scoping to the chart path and previous released tag.

## 8) Secrets & GitOps Guardrails

* Avoid runtime value generators that produce different values when Argo CD or other controllers template the chart (e.g., helpers that re‑generate secrets every render). Prefer:

  * **Lookup‑then‑retain** patterns (only generate if missing, never mutate existing Secret data on upgrade).
  * Explicit **`existingSecret`** values or external secret operators.
* Document secret ownership (chart‑owned vs. cluster‑owned) and upgrade behavior.

## 9) Copilot Behavior Rules (Very Important)

1. **Do not hallucinate CLI flags or action inputs.** When suggesting GitHub Actions, **link to Marketplace docs** for each action used.
2. **Propose incremental diffs** (minimal changes) over large rewrites.
3. **Respect selected automation pattern (Section 5).** Do not mix patterns.
4. **Prefer POSIX‑compatible shell** in workflows; avoid bash‑isms unless runner image guarantees bash.
5. **YAML correctness first:** Keep indentation, anchors, and templating precise. Provide complete snippets that pass `yamllint` and `helm lint`.
6. **Conventional Commits only** in examples; include meaningful scope (e.g., `fix(acapy): ...`).
7. **Cite upstream sources** for complex suggestions (Helm, ct, chart‑releaser, Argo CD, Kubernetes) with official docs links.
8. **Security:** Never hardcode secrets. Use GitHub Environments, OIDC‑based auth, or `secrets` inputs; document required permissions.
9. **Idempotency:** Suggestions must be safe for re‑runs (e.g., avoid double‑publishing; guard with `if: needs.detect-changed-chart.outputs.chart != ''`).
10. **Performance:** Cache toolchains and avoid unnecessary matrix expansion.

## 10) Files & Conventions Copilot Should Know

* `charts/<name>/Chart.yaml`: authoritative chart version.
* `charts/<name>/values.yaml`: annotated params (@param) for README generation.
* `charts/<name>/ci/*-values.yaml`: minimal install values for `ct`.
* `.github/actions/detect-chart`: outputs a single changed chart; enforce single‑chart PRs.
* `.github/workflows/*`: split into `detect-changed-chart`, `lint-test`, `publish` jobs; `publish` only runs when a new chart version is detected.

## 11) How to Propose Version/Changelog Automation

When asked to implement automation, Copilot should:

1. **Confirm the selected pattern** (A/B/C) from Section 5.
2. **Show the job graph** (detect → generate (version/changelog) → package → release → index) and required permissions (`contents: write`, `pull-requests: write`).
3. **Scope commit range** to the chart path to avoid duplicating history (e.g., use `git log -- <charts/name>` between previous released tag and `HEAD`).
4. **Guard concurrent releases** per chart (use per‑chart mutex or workflow concurrency groups).
5. **Demonstrate rollback safety** (do not delete tags; re‑run publishes idempotently; `cr index` no‑ops if unchanged).

## 12) Documentation & Community Standards

* Follow Linux Foundation/OWF contribution guidelines: DCO sign‑off, clear PR descriptions, reviewer checklists.
* Keep PR titles informative (e.g., `feat(acapy): add configurable serviceAccount`), with a concise body and release‑notes block if relevant.
* Add/maintain `OWNERS`/CODEOWNERS for per‑chart review routing where applicable.

## 13) Known Pitfalls (Do Not Repeat)

* **Conventional‑changelog duplication:** Configure the generator to use the previous released tag per chart and limit the path to avoid pulling old commits repeatedly.
* **Forcing secret regeneration:** Avoid helpers that mutate on every render; this breaks Argo CD upgrades.
* **Missing `appVersion` bumps:** When bumping app images, update `appVersion` alongside values and docs.
* **Caching not working:** Ensure cache keys include tool versions; restore‑keys should be broad but deterministic.

## 14) Example Prompts for This Repo

* “Propose a Release‑PR workflow that bumps `charts/acapy/Chart.yaml` and regenerates CHANGELOG and README using Conventional Commits, scoped to `charts/acapy`, and opens a PR with those diffs. Include action permissions and concurrency settings.”
* “Generate a `ct` config and `ci/values` for a smoke‑install of `charts/acapy` with minimal dependencies.”
* “Refactor secret templates to support `existingSecret` and ensure idempotent upgrades under Argo CD.”

## 15) Output Quality Checklist for Copilot Suggestions

* ✅ Uses official action names/inputs; links to docs.
* ✅ YAML validates with `yamllint`, `helm lint`, and `ct lint`.
* ✅ Reproducible and idempotent; safe on re‑run.
* ✅ Minimal changes, well‑commented, with commit messages in Conventional Commits.
* ✅ Matches the chosen automation pattern and repository conventions above.

---

**Maintainers:** Update this guardrail when the repo’s automation pattern or policies change. Keep it short, specific, and actionable for assistants and contributors.

## 16) Coding & scripting conventions (repo‑specific)

### Bash scripts (for `hack/` and composite actions)

* Start every script with:

  ```bash
  #!/usr/bin/env bash
  set -Eeuo pipefail
  IFS=$'
    '
  ```
* Prefer pure bash; use `jq`, `yq`, and `envsubst` when needed. Avoid `eval`. Prefer arrays over word‑splitting.
* Validate inputs early; exit with **actionable** error messages and non‑zero codes. Provide `--help` that documents env vars and flags.
* Make scripts **idempotent**: probe (detect) → decide → act; log when skipping because a resource already exists.
* Safe temp files/dirs via `mktemp`; always clean up with `trap 'rm -rf "$TMPDIR"' EXIT`.
* Quote expansions by default; use `read -r` and process substitution over subshell pipelines where clarity improves.
* Lint with `shellcheck` and format with `shfmt -i 2 -ci -sr` before committing.
* Keep functions focused (< 40 lines). Factor repeated logic into helpers (`hack/lib/*.sh`).
* Logging: prefix with `[info]`, `[warn]`, `[error]`; print what failed, likely cause, and fix.
* Toggle verbose debugging via `DEBUG=1` → `[[ "${DEBUG:-0}" == 1 ]] && set -x`.

### GitHub Actions (workflows & composite actions)

* **YAML style:** 2‑space indent; readable step names; consistent `id:`s. Prefer `shell: bash` and start multi‑line `run:` blocks with `set -Eeuo pipefail`.
* **Pin actions & tools:** Use tagged actions (or SHA pins) and explicit tool versions. Do not rely on "latest".
* **Least privilege:** Set `permissions:` per job; never default to `write` globally.
* **Determinism:** Use `working-directory` and per‑chart scoping; the `detect-chart` output must gate downstream jobs.
* **Concurrency:** Use per‑branch or per‑chart `concurrency.group` and `cancel-in-progress: true` for publish jobs to prevent races.
* **Caching:** Cache Helm, ct, npm, and yq under the runner’s cache dir; use stable keys and broad `restore-keys` to warm cold caches.
* **Guards:** Use `if:` conditions for event types (PR vs. push), and for packaging only when a new version is detected.
* **Install once:** Prefer official setup actions for Helm/Node and reuse across jobs; avoid ad‑hoc curl|bash.
* **Artifacts:** Upload logs/manifests on failure for easier triage (e.g., `helm template` output when lint fails).
* **Docs & changelog generation:** Run generators in validation mode during PRs (fail on README drift), and only write files in Release‑PR flows.

### Changelog/version tooling (Node)

* Use `conventional-changelog` with the **`conventionalcommits-helm`** preset.
* Scope generation to the **changed chart path** (`charts/<name>`) and bound by the **previous released tag** for that chart to prevent historic duplication.
* Enforce Conventional Commits in PR titles/bodies; map `feat`, `fix`, `perf`, `refactor`, `docs`, `chore` to CHANGELOG sections.
* Script entry points:

  * `npm run changelog:chart` → generate/patch `charts/<name>/CHANGELOG.md` deterministically.
  * `hack/changelog-chart.js` → resolve last tag (`<chart>-<semver>`), run generator with `--commit-path charts/<name>`.

### Makefiles & task runners

* Provide `PHONY` targets: `tools-check`, `lint`, `ct-lint`, `ct-install`, `docs`, `changelog`, `release-pr`.
* Every target should accept `CHART=<name>`; default to a no‑op if unset or detect via the current branch.
* `tools-check` must print tool versions and fail on drift against the repo’s pinned versions file (e.g., `hack/versions.env`).

### Script layout & docs

* Place scripts in `hack/` (single‑purpose) and libraries in `hack/lib/`.
* Each script starts with a short header: purpose, inputs (flags/env), assumptions, and side effects.
* When adding scripts or tasks, add a one‑liner to the Makefile and, if user‑facing, a note in the chart README or `docs/`.

## 17) Readability & maintainability (customized)

Aim for code a teammate can understand quickly and change safely:

* Prefer clear multi‑line conditionals for non‑trivial logic with a brief comment that explains **intent** (what/why) over mechanics.
* Use descriptive, consistent variable names (e.g., `CHART`, `APP_VERSION`, `NEW_VERSION`). Avoid hidden globals; pass values into functions.
* Centralize wrappers for external CLIs (e.g., Helm, ct, cr) so options and retries are consistent across scripts.
* Keep one pipeline per line; avoid unrelated `;` chains; prefer backslash continuations for long commands.
* Normalize redirections (`> /dev/null`, `2> /dev/null`), avoid masking real errors—only suppress when documented.
* Break up large blocks with helpers and comments; keep functions cohesive.
* Add reviewer affordances: echo computed decisions (e.g., the previous tag, next version, and commit range) before making changes.

## 18) Workflow development conventions (CI alignment)

* **Select one release pattern** (Section 5) and keep workflows consistent with it. Do not mix validate‑only with Release‑PR automation.
* **Per‑chart scoping everywhere:** Lint, template, ct‑install, and changelog/version generation must target `charts/<name>` only.
* **Fail early with helpful messages:** When README drift is detected, print the exact generator command to run locally.
* **Retry policy:** For flaky network steps (repo add, index fetch), add a short retry with backoff; never in tight loops.
* **Outputs first:** Prefer extracting machine‑readable outputs (JSON/YAML) and parsing with `jq`/`yq` over grepping human text.
* **Testability:** Workflows should be runnable locally with the devcontainer + Makefile (same versions, same scripts).
* **Security:** Avoid plaintext secrets and nondeterministic secret generation; document `existingSecret` patterns and upgrade behavior in chart READMEs.
