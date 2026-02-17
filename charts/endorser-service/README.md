# endorser-service

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.1.1](https://img.shields.io/badge/AppVersion-1.1.1-informational?style=flat-square)
A Helm chart for ACA-Py Endorser Service

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm repo add owf https://openwallet-foundation.github.io/helm-charts/
helm install my-release owf/endorser-service
```

The command deploys the ACA-Py Endorser Service along with PostgreSQL on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Architecture

This chart deploys an endorser service with the following components:

- **Endorser API** - Transaction endorsement controller
- **ACA-Py Agent** - Hyperledger Aries agent (endorser role)
- **Caddy Proxy** - Reverse proxy for routing traffic to agent and API endpoints
- **PostgreSQL** (x2) - Databases for endorser API and ACA-Py agent wallet

```
                  +---------+
  ingress ------->|  Caddy  |
                  |  Proxy  |
                  +----+----+
                       |
          +------------+------------+
          |                         |
     +----v----+             +------v------+
     | Endorser|  webhook    |   ACA-Py    |
     |   API   |<------------|   Agent     |
     +----+----+  admin API  +------+------+
          |       --------->        |
     +----v----+             +------v------+
     |Postgres |             |  Postgres   |
     |  (API)  |             |  (wallet)   |
     +---------+             +-------------+
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| esune | <emiliano.sune@quartech.com> | <https://github.com/esune> |
| i5okie | <ivan.polchenko@quartech.com> | <https://github.com/i5okie> |
## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://openwallet-foundation.github.io/helm-charts/ | acapy | 1.0.0 |
| oci://registry-1.docker.io/cloudpirates | postgres | 0.15.5 |

## Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| acapy."argfile.yml".auto-promote-author-did | bool | `false` | Automatically promote author DIDs |
| acapy."argfile.yml".endorser-alias | string | `""` | Endorser alias in connections |
| acapy."argfile.yml".endorser-protocol-role | string | `"endorser"` | Endorser protocol role (must be "endorser") |
| acapy."argfile.yml".monitor-revocation-notification | bool | `true` | Monitor for revocation notifications |
| acapy."argfile.yml".no-ledger | bool | `true` | Disable ledger configuration |
| acapy."argfile.yml".notify-revocation | bool | `true` | Send revocation notifications |
| acapy."argfile.yml".plugin | list | `["webvh"]` | Required plugins |
| acapy."argfile.yml".public-invites | bool | `true` | Enable public connection invitations |
| acapy."argfile.yml".read-only-ledger | bool | `false` | Ledger read-only mode |
| acapy."argfile.yml".requests-through-public-did | bool | `true` | Allow endorsement requests through public DID |
| acapy."argfile.yml".wallet-name | string | `"aries-endorser-agent-wallet"` | Wallet name for ACA-Py agent |
| acapy."ledgers.yml" | list | `[]` |  |
| acapy."plugin-config.yml".did-webvh.server_url | string | `""` | Set WebVH server url |
| acapy."plugin-config.yml".did-webvh.witness | bool | `true` | Enable witnessing |
| acapy.adminUrl | string | `"https://endorser-agent-admin.example.com"` | External admin URL (public endpoint) |
| acapy.agentUrl | string | `"https://endorser-agent.example.com"` | External agent URL (public endpoint) |
| acapy.enabled | bool | `true` | Enable ACA-Py agent deployment |
| acapy.extraEnvVars | list | `[]` | Extra environment variables as an array |
| acapy.extraEnvVarsSecret | string | `"{{ printf \"%s-acapy-webhook\" .Release.Name | trunc 63 | trimSuffix \"-\" }}"` | Name of existing secret containing extra environment variables (webhook URL for endorser) Template is evaluated by common.tplvalues.render in Aca-Py deployment |
| acapy.image.registry | string | `"ghcr.io"` | Container image registry |
| acapy.image.repository | string | `"openwallet-foundation/acapy-endorser-service/agent"` | Container image repository |
| acapy.image.tag | string | `"1.1.2"` | Image tag (defaults to ACA-Py's chart appVersion) |
| acapy.ingress.admin.enabled | bool | `false` | Enable admin ingress |
| acapy.ingress.admin.hostname | string | `""` | Admin hostname |
| acapy.ingress.agent.enabled | bool | `false` | Enable agent ingress |
| acapy.ingress.agent.hostname | string | `""` | Agent hostname |
| acapy.networkPolicy.enabled | bool | `false` | Disable ACA-Py chart's built-in NetworkPolicy (managed by parent chart instead) |
| acapy.persistence.enabled | bool | `false` | Enable persistent volume for ACA-Py |
| acapy.postgres.enabled | bool | `true` | Enable Postgres for ACA-Py wallet |
| acapy.postgres.nameOverride | string | `"acapy-postgres"` | Name override to avoid collision with API database |
| acapy.service.ports.admin | int | `8051` | Admin API port |
| acapy.service.ports.http | int | `8050` | HTTP port for agent endpoints |
| acapy.service.ports.ws | int | `8052` | WebSocket port |
| acapy.websockets.enabled | bool | `true` | Enable WebSocket support |
| affinity | object | `{}` | Affinity rules for API pods |
| api.acapyAdminUrl | string | `"https://endorser-agent-admin.example.com"` | ACA-Py admin URL (external) |
| api.adminUser | string | `"endorser-admin"` | Admin username for endorser API |
| api.autoAcceptAuthors | bool | `false` | Automatically register new connections as authors |
| api.autoAcceptConnections | bool | `false` | Automatically accept connection requests |
| api.autoEndorseRequests | bool | `false` | Automatically endorse all transaction requests |
| api.autoEndorseTxnTypes | string | `""` | Comma-separated list of transaction types to auto-endorse (e.g., "101,102") |
| api.environment | string | `"dev"` | Endorser environment (dev, test, prod) |
| api.jwtAccessTokenExpireMinutes | int | `300` | JWT access token expiration time in minutes |
| api.logLevel | string | `"info"` | Log level (debug, info, warning, error) |
| api.publicDesc | string | `"An endorser service for issuer agents"` | Public description of the endorser service |
| api.publicName | string | `"Endorser Service"` | Public display name for the endorser service |
| api.rejectByDefault | bool | `false` | Reject endorsement requests by default (requires explicit approval) |
| api.webConcurrency | string | `"2"` | Number of Gunicorn worker processes |
| autoscaling.enabled | bool | `false` | Enable horizontal pod autoscaling |
| autoscaling.maxReplicas | int | `100` | Maximum replicas |
| autoscaling.minReplicas | int | `1` | Minimum replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization percentage |
| commonAnnotations | object | `{}` | Common annotations to add to all resources |
| commonLabels | object | `{}` | Common labels to add to all resources |
| externalDatabase.adminUsername | string | `""` | Database admin username (defaults to username if not set; typically 'postgres' for PostgreSQL) |
| externalDatabase.database | string | `""` | Database name (e.g., endorser) |
| externalDatabase.existingSecret | string | `""` | Existing secret containing database credentials. Required when postgres.enabled is false. |
| externalDatabase.host | string | `""` | Database hostname (e.g., postgres.example.com). Required when postgres.enabled is false. |
| externalDatabase.port | int | `5432` | Database port |
| externalDatabase.secretKeys.adminPasswordKey | string | `"postgres-password"` | Key for admin password |
| externalDatabase.secretKeys.userPasswordKey | string | `"password"` | Key for user password |
| externalDatabase.username | string | `""` | Database username (e.g., endorser) |
| fullnameOverride | string | `""` | Override the full release name |
| global.ingressSuffix | string | `".example.com"` | Ingress hostname suffix for generated hostnames |
| global.security | object | `{"allowInsecureImages":true}` | Security settings for subcharts |
| global.security.allowInsecureImages | bool | `true` | Allow non-standard/legacy container images (required for PostgreSQL legacy image) |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/openwallet-foundation/acapy-endorser-service/endorser"` | Container image repository |
| image.tag | string | `""` | Image tag (defaults to chart appVersion) |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name |
| ingress.enabled | bool | `false` | Enable ingress for API |
| ingress.hosts[0].host | string | `"endorser-api.example.com"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` | TLS configuration |
| livenessProbe.httpGet.path | string | `"/"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| migration.initContainer.image | string | `"busybox"` | Image repository for init container (database connectivity check) |
| migration.initContainer.tag | string | `"1.36.1"` | Image tag for init container |
| migration.resources | object | `{}` | Resource limits and requests for migration job container |
| nameOverride | string | `""` | Override the chart name |
| networkPolicy.api.egress | list | `[]` | Egress rules for API pods (defaults to allow all if empty) Use to restrict outbound connections (e.g., only to database and ACA-Py). Note: When non-empty, these rules replace the default allow-all egress. |
| networkPolicy.api.extraIngress | list | `[]` | Additional ingress rules for API pods Proxy and ACA-Py communication is handled by separate network policies (networkpolicy-proxy.yaml and networkpolicy-acapy.yaml). Use this to add additional ingress sources (e.g., monitoring namespace, external services). |
| networkPolicy.enabled | bool | `true` | Enable network policies for all components |
| networkPolicy.postgres.extraIngress | list | `[]` | Additional ingress rules for postgres pods API and migration job access is always allowed. Use this for additional sources (e.g., backup agents, monitoring). |
| networkPolicy.proxy.egress | list | `[]` | Egress rules for proxy pods (defaults to allow all if empty) Use to restrict outbound connections (e.g., only to API and ACA-Py). |
| networkPolicy.proxy.extraIngress | list | `[]` | Additional ingress rules for proxy pods Default allows all cluster traffic; use this to restrict ingress sources. |
| nodeSelector | object | `{}` | Node selector for API pods |
| podAnnotations | object | `{}` | Annotations to add to API pods |
| podLabels | object | `{}` | Labels to add to API pods |
| podSecurityContext | object | `{}` | Security context for API pods |
| postgres.auth.existingSecret | string | `"{{ printf \"%s-postgres\" .Release.Name }}"` | Name of existing secret to use for Postgres admin credentials. Points to chart-managed consolidated secret by default. |
| postgres.auth.secretKeys.adminPasswordKey | string | `"postgres-password"` | Key in the secret containing the admin password |
| postgres.config.postgresql.max_connections | int | `500` | Maximum number of PostgreSQL connections |
| postgres.containerSecurityContext.runAsGroup | int | `999` | Group ID for the container |
| postgres.containerSecurityContext.runAsUser | int | `999` | User ID for the container |
| postgres.customUser.database | string | `"endorser"` | Database for the custom user |
| postgres.customUser.existingSecret | string | `"{{ printf \"%s-postgres\" .Release.Name }}"` | Existing secret for custom user credentials. Points to chart-managed consolidated secret by default. |
| postgres.customUser.name | string | `"endorser"` | Name for a custom application user to create (used by Endorser API) |
| postgres.customUser.secretKeys.database | string | `"database"` | Key in the secret containing the custom database name |
| postgres.customUser.secretKeys.name | string | `"user"` | Key in the secret containing the custom username |
| postgres.customUser.secretKeys.password | string | `"password"` | Key in the secret containing the custom user password |
| postgres.enabled | bool | `true` | Switch to enable or disable the Postgres helm chart |
| postgres.image.registry | string | `"docker.io"` | Postgres image registry |
| postgres.image.repository | string | `"postgres"` | Postgres image repository |
| postgres.image.tag | string | `"18.1"` | Postgres image tag |
| postgres.initdb.scripts."01-init.sh" | string | `"#!/bin/bash\nset -e\necho \"Initializing database permissions for user: $POSTGRES_USER\"\nexport PGPASSWORD=\"$POSTGRES_POSTGRES_PASSWORD\"\npsql -v ON_ERROR_STOP=1 --username \"postgres\" --dbname \"$POSTGRES_DATABASE\" <<-EOSQL\n    CREATE EXTENSION IF NOT EXISTS pgcrypto;\n    ALTER DATABASE $POSTGRES_DATABASE OWNER TO $POSTGRES_USER;\n    REVOKE ALL ON SCHEMA public FROM PUBLIC;\n    GRANT ALL ON SCHEMA public TO $POSTGRES_USER;\n    ALTER DEFAULT PRIVILEGES FOR USER $POSTGRES_USER IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $POSTGRES_USER;\n    ALTER DEFAULT PRIVILEGES FOR USER $POSTGRES_USER IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO $POSTGRES_USER;\n    ALTER DEFAULT PRIVILEGES FOR USER $POSTGRES_USER IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO $POSTGRES_USER;\nEOSQL\necho \"Database initialization complete for user: $POSTGRES_USER\"\n"` |  |
| postgres.persistence.enabled | bool | `true` | Enable PostgreSQL data persistence using PVC |
| postgres.persistence.size | string | `"1Gi"` | PVC Storage Request for PostgreSQL volume |
| postgres.podSecurityContext.fsGroup | int | `999` | Group ID for the pod's volumes |
| postgres.resources | object | `{}` | Resource requests and limits for PostgreSQL |
| postgres.service.port | int | `5432` | PostgreSQL service port |
| postgres.targetPlatform | string | `""` | Target platform for deployment. Set to "openshift" for OpenShift compatibility (auto-detected if not set) |
| proxy.affinity | object | `{}` | Affinity rules for proxy pods |
| proxy.autoscaling.enabled | bool | `false` | Enable autoscaling |
| proxy.autoscaling.maxReplicas | int | `9` | Maximum replicas |
| proxy.autoscaling.minReplicas | int | `3` | Minimum replicas |
| proxy.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization |
| proxy.autoscaling.targetMemoryUtilizationPercentage | int | `75` | Target memory utilization |
| proxy.caddyConfig | object | `{"caddyfile":"# ACA-Py Agent endpoint with WebSocket support\n:{$CADDY_AGENT_PORT} {\n  @websockets {\n    header Connection *Upgrade*\n    header Upgrade websocket\n  }\n\n  handle @websockets {\n    reverse_proxy http://{$ACAPY_AGENT_HOST}:{$ACAPY_WS_PORT}\n  }\n\n  handle {\n    encode gzip\n    reverse_proxy http://{$ACAPY_AGENT_HOST}:{$ACAPY_HTTP_PORT}\n  }\n\n  log {\n    output stdout\n    level INFO\n  }\n}\n\n# ACA-Py Admin endpoint\n:{$CADDY_AGENT_ADMIN_PORT} {\n  encode gzip\n  reverse_proxy http://{$ACAPY_AGENT_HOST}:{$ACAPY_ADMIN_PORT}\n\n  log {\n    output stdout\n    level INFO\n  }\n}\n\n# Endorser Service API endpoint\n:{$CADDY_ENDORSER_SERVICE_PORT} {\n  encode gzip\n  reverse_proxy http://{$ENDORSER_SERVICE_HOST}:{$ENDORSER_SERVICE_PORT}\n\n  log {\n    output stdout\n    level INFO\n  }\n}","existingConfigMap":"","fileName":"Caddyfile","mountPath":"/etc/caddy/"}` | Caddy configuration |
| proxy.caddyConfig.existingConfigMap | string | `""` | Use existing ConfigMap for Caddyfile |
| proxy.caddyConfig.fileName | string | `"Caddyfile"` | Caddyfile filename |
| proxy.caddyConfig.mountPath | string | `"/etc/caddy/"` | Caddy config mount path |
| proxy.enabled | bool | `true` | Enable Caddy proxy deployment |
| proxy.env | object | `{}` | Additional environment variables |
| proxy.envFrom | list | `[]` | Additional envFrom sources |
| proxy.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| proxy.image.repository | string | `"ghcr.io/i5okie/caddy-rootless"` | Image repository |
| proxy.image.tag | string | `"2-alpine"` | Image tag |
| proxy.ingress.annotations | object | `{"route.openshift.io/termination":"edge"}` | Ingress annotations |
| proxy.ingress.className | string | `""` | Ingress class name |
| proxy.ingress.enabled | bool | `true` | Enable ingress for proxy |
| proxy.ingress.hosts[0].host | string | `"endorser-agent.example.com"` |  |
| proxy.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| proxy.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| proxy.ingress.hosts[0].paths[0].servicePort | string | `"agent"` |  |
| proxy.ingress.hosts[1].host | string | `"endorser-agent-admin.example.com"` |  |
| proxy.ingress.hosts[1].paths[0].path | string | `"/"` |  |
| proxy.ingress.hosts[1].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| proxy.ingress.hosts[1].paths[0].servicePort | string | `"admin"` |  |
| proxy.ingress.hosts[2].host | string | `"endorser.example.com"` |  |
| proxy.ingress.hosts[2].paths[0].path | string | `"/"` |  |
| proxy.ingress.hosts[2].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| proxy.ingress.hosts[2].paths[0].servicePort | string | `"endorser"` |  |
| proxy.ingress.tls | list | `[]` | TLS configuration |
| proxy.livenessProbe.failureThreshold | int | `5` |  |
| proxy.livenessProbe.httpGet.path | string | `"/status/live"` |  |
| proxy.livenessProbe.httpGet.port | string | `"admin"` |  |
| proxy.livenessProbe.initialDelaySeconds | int | `30` |  |
| proxy.livenessProbe.periodSeconds | int | `60` |  |
| proxy.livenessProbe.timeoutSeconds | int | `40` |  |
| proxy.nodeSelector | object | `{}` | Node selector for proxy pods |
| proxy.podAnnotations | object | `{}` | Annotations to add to proxy pods |
| proxy.podLabels | object | `{}` | Labels to add to proxy pods |
| proxy.podSecurityContext | object | `{}` | Security context for proxy pods |
| proxy.readinessProbe.failureThreshold | int | `5` |  |
| proxy.readinessProbe.httpGet.path | string | `"/status/ready"` |  |
| proxy.readinessProbe.httpGet.port | string | `"admin"` |  |
| proxy.readinessProbe.initialDelaySeconds | int | `3` |  |
| proxy.readinessProbe.periodSeconds | int | `30` |  |
| proxy.readinessProbe.timeoutSeconds | int | `40` |  |
| proxy.replicaCount | int | `1` | Number of proxy replicas |
| proxy.resources.limits.cpu | string | `"300m"` |  |
| proxy.resources.limits.memory | string | `"128Mi"` |  |
| proxy.resources.requests.cpu | string | `"10m"` |  |
| proxy.resources.requests.memory | string | `"64Mi"` |  |
| proxy.securityContext | object | `{}` | Security context for proxy containers |
| proxy.service.ports.admin | int | `8051` | Port for ACA-Py admin API |
| proxy.service.ports.agent | int | `8050` | Port for ACA-Py agent (HTTP/WebSocket) |
| proxy.service.ports.endorser | int | `5000` | Port for endorser service API |
| proxy.service.type | string | `"ClusterIP"` | Service type |
| proxy.tolerations | list | `[]` | Tolerations for proxy pods |
| readinessProbe.httpGet.path | string | `"/"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| replicaCount | int | `1` | Number of API deployment replicas |
| resources | object | `{}` | Resource limits and requests for API containers |
| secrets.api.existingSecret | string | `""` | Use existing secret instead of creating one (must contain keys specified below) |
| secrets.api.keys.endorserAdminApiKey | string | `"endorser-admin-api-key"` | Key name for endorser admin API key (used to authenticate admin operations) |
| secrets.api.keys.webhookApiKey | string | `"webhook-api-key"` | Key name for webhook API key (used by ACA-Py to authenticate webhook calls) |
| secrets.api.retainOnUninstall | bool | `true` | Retain API secret on chart uninstall |
| secrets.database.retainOnUninstall | bool | `true` | Retain database secret on chart uninstall |
| secrets.jwt.existingSecret | string | `""` | Use existing secret for JWT secret key; must contain `jwt-secret-key` key |
| secrets.jwt.retainOnUninstall | bool | `true` | Retain JWT secret on chart uninstall |
| securityContext | object | `{}` | Security context for API containers |
| service.port | int | `5000` | Service port for endorser API |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP, NodePort, LoadBalancer) |
| serviceAccount.annotations | object | `{}` | Annotations for the service account |
| serviceAccount.automountServiceAccountToken | bool | `true` | Automatically mount service account credentials |
| serviceAccount.create | bool | `false` | Create a service account |
| serviceAccount.name | string | `""` | Service account name (generated if empty and create is true) |
| tolerations | list | `[]` | Tolerations for API pods |
| volumeMounts | list | `[]` | Additional volume mounts for API containers |
| volumes | list | `[]` | Additional volumes for API deployment |

## Upgrading

<details>
<summary><strong>0.x &rarr; 1.0.0 (breaking: PostgreSQL subchart + ACA-Py subchart + NetworkPolicy)</strong></summary>

This release contains three breaking changes:

1. **PostgreSQL subchart** switched from Bitnami `postgresql` to CloudPirates `postgres`
2. **ACA-Py subchart** upgraded from `0.2.3` to `1.0.0` (which also migrated its own PostgreSQL)
3. **NetworkPolicy values** restructured under `networkPolicy.{api,proxy,postgres}`

### Values migration

| Old path | New path |
|----------|----------|
| `postgresql.enabled` | `postgres.enabled` |
| `postgresql.auth.username` | `postgres.customUser.name` |
| `postgresql.auth.database` | `postgres.customUser.database` |
| `postgresql.auth.enablePostgresUser` | _(removed, always enabled)_ |
| `postgresql.primary.persistence.enabled` | `postgres.persistence.enabled` |
| `postgresql.primary.persistence.size` | `postgres.persistence.size` |
| `postgresql.image.*` | `postgres.image.*` |
| `acapy.postgresql.enabled` | `acapy.postgres.enabled` |
| `acapy.postgresql.nameOverride` | `acapy.postgres.nameOverride` |
| `networkPolicy.extraIngress` | `networkPolicy.api.extraIngress` |
| `networkPolicy.egress` | `networkPolicy.api.egress` |
| `proxy.networkPolicy.enabled` | `networkPolicy.enabled` _(single toggle)_ |
| `proxy.networkPolicy.extraIngress` | `networkPolicy.proxy.extraIngress` |
| `proxy.networkPolicy.egress` | `networkPolicy.proxy.egress` |

### Database migration steps (existing installations)

Both PostgreSQL instances (endorser API and ACA-Py wallet) need to be migrated via **backup + restore**. In-place reuse of the old Bitnami data directory is not supported.

1) Freeze writes by scaling the API and ACA-Py to 0:

```bash
kubectl -n <namespace> scale deploy -l app.kubernetes.io/instance=<release> --replicas=0
```

2) Dump both databases from the old Bitnami PostgreSQL pods:

```bash
# Endorser API database
export OLD_DB_POD=$(kubectl -n <namespace> get pod -l app.kubernetes.io/instance=<release>,app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')
export PGPASSWORD="$(kubectl -n <namespace> get secret <release>-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl -n <namespace> exec -i "$OLD_DB_POD" -- sh -lc 'pg_dumpall -U postgres' > endorser-api.dump.sql

# ACA-Py wallet database
export OLD_WALLET_POD=$(kubectl -n <namespace> get pod -l app.kubernetes.io/instance=<release>,app.kubernetes.io/name=acapy-postgresql -o jsonpath='{.items[0].metadata.name}')
export PGPASSWORD="$(kubectl -n <namespace> get secret <release>-acapy-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)"
kubectl -n <namespace> exec -i "$OLD_WALLET_POD" -- sh -lc 'pg_dumpall -U postgres' > acapy-wallet.dump.sql
```

3) Upgrade your Helm release with the new values structure:

```yaml
# values.migration.yaml
postgres:
  enabled: true
  customUser:
    name: endorser
    database: endorser

acapy:
  postgres:
    enabled: true
    nameOverride: acapy-postgres
```

```bash
helm get values <release> -n <namespace> -o yaml > values.before.yaml
# Review values.before.yaml and update paths per the migration table above
helm upgrade <release> owf/endorser-service -n <namespace> -f values.before.yaml -f values.migration.yaml
```

4) Restore into the new Postgres instances:

```bash
# Endorser API database
export NEW_DB_POD=$(kubectl -n <namespace> get pod -l app.kubernetes.io/instance=<release>,app.kubernetes.io/name=postgres -o jsonpath='{.items[0].metadata.name}')
export PGPASSWORD="$(kubectl -n <namespace> get secret <release>-postgres -o jsonpath='{.data.postgres-password}' | base64 -d)"
cat endorser-api.dump.sql | kubectl -n <namespace> exec -i "$NEW_DB_POD" -- sh -lc 'psql -U postgres -f -'

# ACA-Py wallet database
export NEW_WALLET_POD=$(kubectl -n <namespace> get pod -l app.kubernetes.io/instance=<release>,app.kubernetes.io/name=acapy-postgres -o jsonpath='{.items[0].metadata.name}')
export PGPASSWORD="$(kubectl -n <namespace> get secret <release>-acapy-postgres -o jsonpath='{.data.postgres-password}' | base64 -d)"
cat acapy-wallet.dump.sql | kubectl -n <namespace> exec -i "$NEW_WALLET_POD" -- sh -lc 'psql -U postgres -f -'
```

5) Scale back up and verify:

```bash
kubectl -n <namespace> scale deploy -l app.kubernetes.io/instance=<release> --replicas=1
kubectl -n <namespace> get pods -l app.kubernetes.io/instance=<release> -w
```

### GitOps note (Argo CD / Flux)

If your GitOps renderer can't perform `lookup` during dry-runs, generated secrets may drift on every sync.
In that case, pre-create your secrets and reference them via:
- `secrets.api.existingSecret`
- `secrets.jwt.existingSecret`
- `postgres.auth.existingSecret` (bundled Postgres admin credentials)
- `postgres.customUser.existingSecret` (bundled Postgres application user credentials)
- `externalDatabase.existingSecret` (when using an external database with `postgres.enabled=false`)

</details>

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
