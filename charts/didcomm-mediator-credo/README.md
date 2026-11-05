# DIDComm Mediator Credo

![Version: 0.3.2](https://img.shields.io/badge/Version-0.3.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart to deploy the DIDComm Mediator Credo service.

## TL;DR

```console
helm repo add owf	https://openwallet-foundation.github.io/helm-charts/
helm repo update
helm install my-release owf/didcomm-mediator-credo
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm repo add owf	https://openwallet-foundation.github.io/helm-charts/
helm install my-release owf/didcomm-mediator-credo
```

> **Tip**: List all releases using `helm list`


## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm delete my-release
```

The command removes all the Kubernetes components but secrets and PVC's associated with the chart and deletes the release.

To delete the secrets and PVC's associated with `my-release`:

```console
kubectl delete secret,pvc --selector "app.kubernetes.io/instance"=my-release
```

## Persistence

By default the mediator keeps its wallet in a SQLite file under its home directory (`persistence.mountPath`), stored on a PersistentVolumeClaim. This supports a single replica only.

To run several replicas, store the wallet in PostgreSQL: set `ASKAR__DATABASE__TYPE=postgres` and the `ASKAR__DATABASE__*` connection variables in `environment`, set `persistence.enabled=false`, and configure the `networkPolicy` and `postgresql` sections. A shared message queue (`MESSAGE_PICKUP__STORAGE__TYPE=postgres` with `MESSAGE_PICKUP__STORAGE__*`) lets the replicas deliver each other's messages.

The chart defaults `podSecurityContext.fsGroup` to `1001` so supported volume drivers make the wallet volume writable by the mediator. Existing volumes and storage drivers that do not honor filesystem groups may require administrator-managed permissions.

Security contexts use the shared Bitnami OpenShift compatibility helper. With `global.compatibility.openshift.adaptSecurityContext=auto`, detected OpenShift clusters omit fixed user/group IDs so the SCC can assign permitted IDs. For offline or GitOps rendering without OpenShift API discovery, set this option to `force`; use `disabled` to retain explicit IDs.

### Externally configured wallet backends

`walletDatabaseType` defaults to `auto`, inferring a literal `ASKAR__DATABASE__TYPE` or the application's SQLite default. When the backend comes from `valueFrom` or a `CONFIG` JSON file without a literal backend, Helm cannot inspect it: explicitly declare `walletDatabaseType: sqlite` or `postgres`, even for a single replica or an explicit strategy override. Multiple replicas or autoscaling require PostgreSQL and `persistence.enabled: false`. This declaration controls chart validation, rollout defaults and warnings; it does not configure the application. The external application configuration must select the declared backend. Contradictions with a literal `ASKAR__DATABASE__TYPE` are rejected.

For example:

```yaml
walletDatabaseType: postgres
persistence:
  enabled: false
replicaCount: 2
environment:
  - name: ASKAR__DATABASE__TYPE
    valueFrom:
      configMapKeyRef:
        name: mediator-config
        key: wallet-database-type
```

For mounted JSON configuration, replace the environment entry above with `CONFIG` pointing to the mounted file, which must configure `askar.database.type` as `postgres`. Mount it using `volumes` and `volumeMounts`. Preserve any other required environment entries when replacing the `environment` list.

Run the chart's rendering regression checks with `ruby charts/didcomm-mediator-credo/ci/render_test.rb` from the repository root (requires Helm and Ruby with Minitest).

## Rollout strategy

With `strategy: {}`, the chart selects `RollingUpdate` for PostgreSQL and `Recreate` for SQLite, independently of persistence. SQLite uses non-overlapping updates to avoid concurrent access to the same wallet. `ReadWriteOnce` restricts mounts across nodes, not necessarily across pods, and does not provide this protection.

An explicit `strategy` overrides automatic selection, including custom `rollingUpdate.maxSurge` and `rollingUpdate.maxUnavailable` settings. Do not configure overlapping rolling updates for a shared SQLite wallet.

For incompatible wallet/storage upgrades, temporarily set:

```yaml
strategy:
  type: Recreate
```

After the upgrade completes, remove the override to restore backend-aware defaults (rolling updates for PostgreSQL).

## Shutdown

`terminationGracePeriodSeconds` controls how long Kubernetes waits after sending `SIGTERM` before forcefully terminating the pod. The default image (`fc575ad`) does not include the mediator's queue cleanup handler or bounded shutdown watchdog, so this setting alone does not provide application-level graceful cleanup. Increase the grace period only when using an image whose signal-handling behavior requires it.

## Upgrading from chart 0.6.x

Chart 1.0 runs the Credo 0.7 mediator, which reads different environment variables. Rendering fails if `environment` still contains a variable from the table below.

| 0.6.x                                                        | 1.0                                                                                                                                                              |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `LOG_LEVEL` (number, e.g. `"3"`)                              | `LOG_LEVEL`: `trace`, `debug`, `info`, `warn`, `error`, `fatal` or `off` (`"2"` was `debug`, `"3"` was `info`)                                                      |
| `WALLET_NAME`                                                | `ASKAR__STORE_ID`                                                                                                                                                |
| `WALLET_KEY` (chart secret)                                  | `ASKAR__STORE_KEY`, still from the chart secret's `wallet-key`                                                                                                     |
| `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`        | `ASKAR__DATABASE__HOST`, `ASKAR__DATABASE__USER`, `ASKAR__DATABASE__PASSWORD`, plus `ASKAR__DATABASE__TYPE=postgres`, without which the wallet is SQLite              |
| `POSTGRES_ADMIN_USER`, `POSTGRES_ADMIN_PASSWORD`             | `ASKAR__DATABASE__ADMIN_USER`, `ASKAR__DATABASE__ADMIN_PASSWORD`                                                                                                 |
| `PICKUP_TYPE`                                                | `MESSAGE_PICKUP__STORAGE__TYPE`: `credo` (default), `postgres` or `dynamodb`                                                                                      |
| `PICKUP_STRATEGY`                                            | `MESSAGE_PICKUP__FORWARDING_STRATEGY`                                                                                                                            |
| `PICKUP_SETTINGS` (chart secret's `pickup-connection-json`)  | `MESSAGE_PICKUP__STORAGE__HOST`, `__USER`, `__PASSWORD` and `__DATABASE`. For `{"useBaseConnection":true}`, repeat the wallet's database settings and use database `messagepickuprepository` |
| `GOAL_CODE`                                                  | `INVITATION_GOAL_CODE`                                                                                                                                           |
| `USE_PUSH_NOTIFICATIONS`, `FIREBASE_APPS` (chart secret)     | `pushNotifications.firebase.enabled=true`, which passes the chart secret's `firebase-apps` as `PUSH_NOTIFICATIONS__FIREBASE__PROJECTS`                            |
| `PUSH_NOTIFICATION_TITLE`, `PUSH_NOTIFICATION_BODY`          | `PUSH_NOTIFICATIONS__FIREBASE__NOTIFICATION_TITLE`, `PUSH_NOTIFICATIONS__FIREBASE__NOTIFICATION_BODY`                                                            |
| `NOTIFICATION_WEBHOOK_URL`                                   | `PUSH_NOTIFICATIONS__WEBHOOK_URL`                                                                                                                                |

Deployments that kept the wallet in PostgreSQL must also set `persistence.enabled=false`.

The first start of the new version upgrades the wallet's storage, which can't be undone. Back up the database first, and for that rollout set `strategy.type=Recreate` so no 0.6.x pod runs alongside it. Raise `startupProbe.failureThreshold` if the upgrade of a large wallet may take longer than the probe allows. Remove the strategy override after the upgrade to restore backend-aware defaults.

## Parameters

### Mediator Settings

| Name                                         | Description                                                                                                                                                                               | Value                                                           |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `replicaCount`                               | This will set the replicaset count more information can be found here: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/                                              | `1`                                                             |
| `walletDatabaseType`                         | Backend declaration for validation and rollout defaults: auto, sqlite or postgres; required for external backend configuration; does not configure the application | `auto` |
| `global.compatibility.openshift.adaptSecurityContext` | Remove fixed user/group IDs on OpenShift: auto, force or disabled | `auto` |
| `strategy`                                   | Deployment update strategy override. Empty selects RollingUpdate for PostgreSQL (requires `persistence.enabled=false`) or Recreate for SQLite. Use explicit Recreate for incompatible storage upgrades. | `{}` |
| `terminationGracePeriodSeconds`              | Kubernetes pod termination grace period. This does not add application-level SIGTERM cleanup.                                                                                              | `30`                                                            |
| `image.repository`                           |                                                                                                                                                                                           | `ghcr.io/openwallet-foundation/didcomm-mediator-credo/mediator` |
| `image.pullPolicy`                           |                                                                                                                                                                                           | `Always`                                                        |
| `image.tag`                                  | Overrides the image tag which defaults to the chart appVersion.                                                                                                                           | `fc575ad`                                                       |
| `imagePullSecrets`                           |                                                                                                                                                                                           | `[]`                                                            |
| `nameOverride`                               | String to override the helm chart name, second part of the prefix.                                                                                                                        | `""`                                                            |
| `fullnameOverride`                           | String to fully override the helm chart name, full prefix. *Must be provided if using a custom release name that does not include the name of the helm chart (`didcomm-mediator-credo`).* | `""`                                                            |
| `serviceAccount.create`                      | Specifies whether a ServiceAccount should be created                                                                                                                                      | `true`                                                          |
| `serviceAccount.annotations`                 | Annotations for service account. Evaluated as a template. Only used if `create` is `true`.                                                                                                | `{}`                                                            |
| `serviceAccount.automount`                   | Automount service account token for the server service account                                                                                                                            | `true`                                                          |
| `serviceAccount.name`                        | Name of the service account to use. If not set and create is true, a name is generated using the fullname template.                                                                       | `""`                                                            |
| `podAnnotations`                             | Map of annotations to add to the mediator pods                                                                                                                                            | `{}`                                                            |
| `podLabels`                                  | Map of labels to add to the mediator pods                                                                                                                                                 | `{}`                                                            |
| `podSecurityContext`                         | Pod Security Context; defaults to filesystem group 1001 for writable wallet volumes | `{ fsGroup: 1001 }` |
| `securityContext`                            | Container Security Context                                                                                                                                                                | `{}`                                                            |
| `service.type`                               | Kubernetes Service type                                                                                                                                                                   | `ClusterIP`                                                     |
| `service.port`                               |                                                                                                                                                                                           | `3000`                                                          |
| `ingress.enabled`                            | Enable ingress record generation for controller                                                                                                                                           | `false`                                                         |
| `ingress.className`                          | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                                                                                                             | `""`                                                            |
| `ingress.labels`                             | Additional labels for the Ingress resource.                                                                                                                                               | `{}`                                                            |
| `ingress.annotations`                        | Additional annotations for the Ingress resource.                                                                                                                                          | `{}`                                                            |
| `ingress.hosts`                              | List of hosts to be configured for the specified ingress record.                                                                                                                          | `[]`                                                            |
| `ingress.tls`                                | Enable TLS configuration for the host defined at ingress.                                                                                                                                 | `[]`                                                            |
| `networkPolicy.enabled`                      | Enable network policies                                                                                                                                                                   | `true`                                                          |
| `networkPolicy.ingress.enabled`              | Enable ingress rules                                                                                                                                                                      | `false`                                                         |
| `networkPolicy.ingress.namespaceSelector`    | Namespace selector label that is allowed to access the Tenant proxy pods.                                                                                                                 | `{}`                                                            |
| `networkPolicy.ingress.podSelector`          | Pod selector label that is allowed to access the Tenant proxy pods.                                                                                                                       | `{}`                                                            |
| `resources`                                  | CPU/Memory resource requests/limits - unset by default                                                                                                                                    | `{}`                                                            |
| `environment`                                | Variables to be passed to the container. See the mediator's README for every option.                                                                                                      | `[]`                                                            |
| `livenessProbe`                              | Liveness probe configuration                                                                                                                                                              | `{}`                                                            |
| `readinessProbe`                             | Readiness probe configuration                                                                                                                                                             | `{}`                                                            |
| `startupProbe`                               | Startup probe configuration                                                                                                                                                               | `{}`                                                            |
| `autoscaling.enabled`                        | Enable Horizontal POD autoscaling for the Credo Mediator                                                                                                                                  | `false`                                                         |
| `autoscaling.minReplicas`                    | Minimum number of replicas                                                                                                                                                                | `1`                                                             |
| `autoscaling.maxReplicas`                    | Maximum number of replicas                                                                                                                                                                | `100`                                                           |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization percentage                                                                                                                                                         | `80`                                                            |
| `volumes`                                    | Additional volumes for the mediator pod                                                                                                                                                   | `[]`                                                            |
| `volumeMounts`                               | Additional volume mounts for the mediator container                                                                                                                                       | `[]`                                                            |
| `nodeSelector`                               | Node labels for pods assignment                                                                                                                                                           | `{}`                                                            |
| `tolerations`                                | Tolerations for pods assignment                                                                                                                                                           | `[]`                                                            |
| `affinity`                                   | Affinity for pods assignment                                                                                                                                                              | `{}`                                                            |

### PostgreSQL parameters

| Name                        | Description                                                                    | Value   |
| --------------------------- | ------------------------------------------------------------------------------ | ------- |
| `postgresql.enabled`        | Enable network policy for PostgreSQL access                                    | `false` |
| `postgresql.selectorLabels` | Labels selecting the postgresql resources to give the mediator pods access to. | `[]`    |
| `postgresql.servicePort`    | PostgreSQL service port to be used in the network policy                       | `5432`  |

### Persistence

| Name                        | Description                                                                                | Value               |
| --------------------------- | ------------------------------------------------------------------------------------------ | ------------------- |
| `persistence.enabled`       | Store the mediator's home directory on a PersistentVolumeClaim. Requires a single SQLite replica; PostgreSQL wallets require this to be false. | `true`              |
| `persistence.existingClaim` | Name of an existing PersistentVolumeClaim to use instead of creating one                   | `""`                |
| `persistence.storageClass`  | Storage class of the PersistentVolumeClaim, the cluster default when empty                 | `""`                |
| `persistence.accessModes`   | Access modes of the PersistentVolumeClaim                                                  | `["ReadWriteOnce"]` |
| `persistence.size`          | Size of the PersistentVolumeClaim                                                          | `1Gi`               |
| `persistence.annotations`   | Annotations for the PersistentVolumeClaim                                                  | `{}`                |
| `persistence.mountPath`     | Mount path of the home directory, also set as HOME                                         | `/home/mediator`    |

### Push notifications

| Name                                 | Description                                                                                                                                                                                             | Value   |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `pushNotifications.firebase.enabled` | Pass the Firebase projects from the chart secret's `firebase-apps` key. Requires PUSH_NOTIFICATIONS__FIREBASE__NOTIFICATION_TITLE and PUSH_NOTIFICATIONS__FIREBASE__NOTIFICATION_BODY in `environment`. | `false` |
