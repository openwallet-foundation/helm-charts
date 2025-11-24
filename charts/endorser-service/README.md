# endorser-service

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.1.1](https://img.shields.io/badge/AppVersion-1.1.1-informational?style=flat-square)

A Helm chart for ACA-Py Endorser Service

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| esune | <emiliano.sune@quartech.com> | <https://github.com/esune> |
| i5okie | <ivan.polchenko@quartech.com> | <https://github.com/i5okie> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 16.3.2 |
| https://openwallet-foundation.github.io/helm-charts/ | acapy | 0.2.3 |

## Values

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
| acapy.image.tag | string | `"1.1.1"` | Image tag (defaults to ACA-Py's chart appVersion) |
| acapy.ingress.admin.enabled | bool | `false` | Enable admin ingress |
| acapy.ingress.admin.hostname | string | `""` | Admin hostname |
| acapy.ingress.agent.enabled | bool | `false` | Enable agent ingress |
| acapy.ingress.agent.hostname | string | `""` | Agent hostname |
| acapy.networkPolicy.enabled | bool | `false` | Disable ACA-Py chart's built-in NetworkPolicy (managed by parent chart instead) |
| acapy.persistence.enabled | bool | `false` | Enable persistent volume for ACA-Py |
| acapy.postgresql.enabled | bool | `true` | Enable PostgreSQL for ACA-Py wallet |
| acapy.postgresql.nameOverride | string | `"acapy-postgresql"` | Name override to avoid collision with API database |
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
| externalDatabase.enabled | bool | `false` | Enable external database (disables postgresql subchart) |
| externalDatabase.existingSecret | string | `""` | Existing secret containing database credentials (required when externalDatabase.enabled is true) |
| externalDatabase.host | string | `""` | Database hostname (e.g., postgres.example.com) |
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
| networkPolicy.api.egress | list | `[]` | Egress rules for API (defaults to allow all if empty) Note: There is no "extraEgress" because all egress rules must be specified here; if empty, all outbound traffic is allowed. Use to restrict outbound connections (e.g., only to database and ACA-Py) |
| networkPolicy.api.enabled | bool | `true` | Enable network policy for API pods |
| networkPolicy.api.extraIngress | list | `[]` | Additional ingress rules for API Note: Proxy and ACA-Py communication is handled by separate network policies (networkpolicy-proxy.yaml and networkpolicy-acapy.yaml). Use this to add additional ingress sources (e.g., monitoring namespace, external services). |
| networkPolicy.enabled | bool | `true` | Enable network policies (master switch for both API and proxy) |
| networkPolicy.proxy.egress | list | `[]` | Egress rules for proxy (defaults to allow all if empty) Note: There is no "extraEgress" because all egress rules must be specified here; if empty, all outbound traffic is allowed. Use to restrict outbound connections (e.g., only to API and ACA-Py) |
| networkPolicy.proxy.enabled | bool | `true` | Enable network policy for proxy pods |
| networkPolicy.proxy.extraIngress | list | `[]` | Additional ingress rules for proxy (merged with default allowance) These are "extra" rules because a default ingress rule (allowing all cluster traffic) is always present; use this to add more restrictions. |
| nodeSelector | object | `{}` | Node selector for API pods |
| podAnnotations | object | `{}` | Annotations to add to API pods |
| podLabels | object | `{}` | Labels to add to API pods |
| podSecurityContext | object | `{}` | Security context for API pods |
| postgresql.auth.database | string | `"endorser"` | Database name |
| postgresql.auth.enablePostgresUser | bool | `true` | Enable postgres superuser (required for init scripts) |
| postgresql.auth.username | string | `"endorser"` | Database username |
| postgresql.enabled | bool | `true` | Enable PostgreSQL deployment for API |
| postgresql.image.registry | string | `"docker.io"` | Image registry |
| postgresql.image.repository | string | `"bitnamilegacy/postgresql"` | Image repository, using Bitnami legacy image. |
| postgresql.image.tag | string | `"17.2.0-debian-12-r3"` | Image tag |
| postgresql.primary.initdb.scripts."01-init.sh" | string | `"#!/bin/bash\nset -e\necho \"Initializing database permissions for user: $POSTGRES_USER\"\nexport PGPASSWORD=\"$POSTGRES_POSTGRES_PASSWORD\"\npsql -v ON_ERROR_STOP=1 --username \"postgres\" --dbname \"$POSTGRES_DATABASE\" <<-EOSQL\n    CREATE EXTENSION IF NOT EXISTS pgcrypto;\n    ALTER DATABASE $POSTGRES_DATABASE OWNER TO $POSTGRES_USER;\n    REVOKE ALL ON SCHEMA public FROM PUBLIC;\n    GRANT ALL ON SCHEMA public TO $POSTGRES_USER;\n    ALTER DEFAULT PRIVILEGES FOR USER $POSTGRES_USER IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $POSTGRES_USER;\n    ALTER DEFAULT PRIVILEGES FOR USER $POSTGRES_USER IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO $POSTGRES_USER;\n    ALTER DEFAULT PRIVILEGES FOR USER $POSTGRES_USER IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO $POSTGRES_USER;\nEOSQL\necho \"Database initialization complete for user: $POSTGRES_USER\"\n"` |  |
| postgresql.primary.persistence.enabled | bool | `true` | Enable persistent volume |
| postgresql.primary.persistence.size | string | `"1Gi"` | Volume size |
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
| proxy.networkPolicy.enabled | bool | `false` | Enable network policy for proxy pods |
| proxy.networkPolicy.ingress | list | `[]` | Additional ingress rules for proxy (defaults to allow all if empty) |
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

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
