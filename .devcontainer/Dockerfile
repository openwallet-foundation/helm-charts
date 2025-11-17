## Devcontainer Dockerfile for OWF Helm Charts
## Uses pinned versions (ARGs) – defaults align with hack/versions.env.
## Rebuild after changing ARG values or hack/versions.env.

FROM ubuntu:24.04

# Buildx provides TARGETARCH/TARGETOS; allow manual override (FORCE_AMD64=1) for consistency across hosts.
ARG TARGETARCH
ARG TARGETOS
ARG FORCE_AMD64=0

ARG DEBIAN_FRONTEND=noninteractive

# Single Source of Truth for tool versions: hack/versions.env
# We COPY it and source it for each install step instead of duplicating ARG defaults.
# Editing hack/versions.env + rebuilding the devcontainer is sufficient to bump tools.
COPY hack/versions.env /tmp/versions.env

ENV PATH=/usr/local/bin:$PATH
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Use bash for subsequent RUN instructions (dash /bin/sh lacks 'pipefail').
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git jq bash make tar gzip xz-utils gnupg lsb-release openssh-client yamllint python3-pip python3-venv locales \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Create non-root user (UID 1000 to align with vscode) with passwordless sudo
RUN useradd -m -s /bin/bash vscode && \
    apt-get update && apt-get install -y sudo && \
    echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-vscode && chmod 440 /etc/sudoers.d/90-vscode

WORKDIR /tmp

## Install all pinned tools in a single layer to ensure versions come ONLY from /tmp/versions.env
RUN set -euo pipefail 2>/dev/null || set -euo || set -eu; \
    . /tmp/versions.env; \
    raw_arch="${TARGETARCH:-$(uname -m)}"; \
    if [ "$FORCE_AMD64" = "1" ]; then raw_arch=amd64; fi; \
    case "$raw_arch" in \
    x86_64|amd64) ARCH=amd64; HELM_ARCH=amd64; NODE_ARCH=x64; YQ_ARCH=amd64; HELM_DOCS_ARCH=x86_64; SHELLCHECK_ARCH=x86_64; SHFMT_ARCH=amd64 ;; \
    aarch64|arm64) ARCH=arm64; HELM_ARCH=arm64; NODE_ARCH=arm64; YQ_ARCH=arm64; HELM_DOCS_ARCH=arm64; SHELLCHECK_ARCH=aarch64; SHFMT_ARCH=arm64 ;; \
    *) echo "Unsupported architecture: $raw_arch" >&2; exit 1 ;; \
    esac; \
    echo "== Installing toolchain (ARCH=$ARCH) =="; set -x; \
    fetch() { url="$1"; out="$2"; echo "[fetch] $url"; curl -fL --retry 3 --retry-delay 2 -o "$out" "$url" || { echo "[error] download failed: $url" >&2; exit 16; }; }; \
    # Helm
    fetch https://get.helm.sh/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz helm.tar.gz; \
    tar -xzf helm.tar.gz linux-${HELM_ARCH}/helm; mv linux-${HELM_ARCH}/helm /usr/local/bin/helm; rm -rf linux-${HELM_ARCH} helm.tar.gz; helm version --short || { echo 'helm failed'; exit 20; }; \
    # chart-testing
    fetch https://github.com/helm/chart-testing/releases/download/v${CHART_TESTING_VERSION}/chart-testing_${CHART_TESTING_VERSION}_linux_${ARCH}.tar.gz ct.tgz; \
    if tar -xzf ct.tgz ct 2>/dev/null; then mv ct /usr/local/bin/ct; rm ct.tgz; else echo '[warn] chart-testing binary extract failed; attempting source build'; rm -f ct.tgz; NEED_GO=1; fi; \
    if [ -n "${NEED_GO:-}" ]; then \
    if ! command -v go >/dev/null 2>&1; then apt-get update && apt-get install -y --no-install-recommends golang; fi; \
    GOBIN=/usr/local/bin go install github.com/helm/chart-testing/v3/ct@v${CHART_TESTING_VERSION}; \
    fi; \
    ct version || { echo 'ct failed'; exit 21; }; \
    # chart-releaser (fallback to source build if binary missing for arch)
    if fetch https://github.com/helm/chart-releaser/releases/download/v${CHART_RELEASER_VERSION}/chart-releaser_${CHART_RELEASER_VERSION}_linux_${ARCH}.tar.gz cr.tgz; then \
    tar -xzf cr.tgz cr; mv cr /usr/local/bin/cr; rm cr.tgz; \
    else \
    echo "[warn] binary chart-releaser for ${ARCH} not found; building from source"; \
    apt-get update && apt-get install -y --no-install-recommends golang; \
    GOBIN=/usr/local/bin go install github.com/helm/chart-releaser@v${CHART_RELEASER_VERSION}; \
    fi; cr version || { echo 'cr failed'; exit 22; }; \
    # kubectl
    fetch https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl /usr/local/bin/kubectl; chmod +x /usr/local/bin/kubectl; kubectl version --client=true --output=yaml || { echo 'kubectl failed'; exit 23; }; \
    # kind
    fetch https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH} /usr/local/bin/kind; chmod +x /usr/local/bin/kind; kind version || { echo 'kind failed'; exit 24; }; \
    # yq
    fetch https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${YQ_ARCH} /usr/local/bin/yq; chmod +x /usr/local/bin/yq; yq --version || { echo 'yq failed'; exit 25; }; \
    # helm-docs
    fetch https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOCS_VERSION}/helm-docs_${HELM_DOCS_VERSION}_Linux_${HELM_DOCS_ARCH}.tar.gz helm-docs.tar.gz; \
    if tar -xzf helm-docs.tar.gz helm-docs 2>/dev/null; then mv helm-docs /usr/local/bin/helm-docs; rm helm-docs.tar.gz; else echo '[warn] helm-docs binary extract failed; attempting source build'; rm -f helm-docs.tar.gz; NEED_GO_HD=1; fi; \
    if [ -n "${NEED_GO_HD:-}" ]; then \
    if ! command -v go >/dev/null 2>&1; then apt-get update && apt-get install -y --no-install-recommends golang; fi; \
    GOBIN=/usr/local/bin go install github.com/norwoodj/helm-docs/cmd/helm-docs@v${HELM_DOCS_VERSION}; \
    fi; \
    helm-docs --version || echo 'helm-docs version check skipped'; \
    # Node.js
    fetch https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz node.tar.xz; \
    tar -xJf node.tar.xz --strip-components=1 -C /usr/local || { echo 'node extract failed'; exit 27; }; rm node.tar.xz; node --version; npm --version; \
    npm install -g conventional-changelog-cli@${CONVENTIONAL_CHANGELOG_CLI_VERSION} conventional-changelog-conventionalcommits @bitnami/readme-generator-for-helm@${BITNAMI_README_GENERATOR_VERSION} || { echo 'npm global installs failed'; exit 28; }; \
    # pre-commit
    python3 -m pip install --break-system-packages pre-commit==${PRECOMMIT_VERSION} || { echo 'pre-commit install failed'; exit 29; }; \
    # shellcheck
    fetch https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${SHELLCHECK_ARCH}.tar.xz shellcheck.tar.xz; \
    tar -xJf shellcheck.tar.xz shellcheck-v${SHELLCHECK_VERSION}/shellcheck || { echo 'shellcheck untar failed'; exit 30; }; mv shellcheck-v${SHELLCHECK_VERSION}/shellcheck /usr/local/bin/shellcheck; rm -rf shellcheck.tar.xz shellcheck-v${SHELLCHECK_VERSION}; shellcheck --version | head -2; \
    # shfmt
    fetch https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${SHFMT_ARCH} /usr/local/bin/shfmt; chmod +x /usr/local/bin/shfmt; shfmt --version || { echo 'shfmt failed'; exit 31; }; set +x


# Cache dirs (persisted across container restarts if volume mapped)
RUN mkdir -p /home/vscode/.cache/helm /home/vscode/.cache/ct && chown -R vscode:vscode /home/vscode/.cache

# Versions reporting script
RUN cat > /usr/local/bin/versions <<'EOF' && chmod +x /usr/local/bin/versions
#!/usr/bin/env bash
set -euo pipefail
echo "Tool versions (expected pins should match hack/versions.env):"
printf '\n%-18s %s\n' HELM "$(helm version --short 2>/dev/null)"
printf '%-18s %s\n' CT "$(ct version 2>/dev/null | sed 's/.*Version: //')"
printf '%-18s %s\n' CHART_RELEASER "$(cr version 2>/dev/null | sed 's/^Version: //')"
printf '%-18s %s\n' KUBECTL "$(kubectl version --client --output=json 2>/dev/null | jq -r '.clientVersion.gitVersion')"
printf '%-18s %s\n' KIND "$(kind version 2>/dev/null | awk '{print $2}')"
printf '%-18s %s\n' YQ "$(yq --version 2>/dev/null)"
printf '%-18s %s\n' HELM_DOCS "$(helm-docs --version 2>/dev/null || echo 'n/a')"
printf '%-18s %s\n' NODE "$(node --version)"
printf '%-18s %s\n' NPM "$(npm --version)"
printf '%-18s %s\n' SHELLCHECK "$(shellcheck --version 2>/dev/null | awk '/version:/ {print $2}')"
printf '%-18s %s\n' SHFMT "$(shfmt --version 2>/dev/null | sed 's/^v//')"
printf '%-18s %s\n' PRE_COMMIT "$(pre-commit --version 2>/dev/null | awk '{print $2}')"
EOF

USER vscode
WORKDIR /workspace

# Warm basic helm repository metadata (optional; avoids first-run penalty). Ignore errors offline.
RUN helm repo add bitnami https://charts.bitnami.com/bitnami || true && helm repo update || true

# Final sanity check (non-fatal): report installed vs pinned
RUN set -euo pipefail; \
    . /tmp/versions.env; \
    echo "[verify] Reporting tool versions (no hard fail)"; \
    helm_raw=$(helm version --short 2>/dev/null || true); \
    ct_raw=$(ct version 2>/dev/null | head -1 || true); \
    cr_raw=$(cr version 2>/dev/null | head -1 || true); \
    echo "[verify] HELM pin=$HELM_VERSION actual=${helm_raw}"; \
    echo "[verify] CT   pin=$CHART_TESTING_VERSION actual=${ct_raw}"; \
    echo "[verify] CR   pin=$CHART_RELEASER_VERSION actual=${cr_raw}"; \
    echo "[verify] (Skipping strict enforcement to keep build unblocked)"

CMD ["sleep", "infinity"]
