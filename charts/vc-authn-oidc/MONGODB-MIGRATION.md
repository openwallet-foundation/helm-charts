# MongoDB Migration Guide: Bitnami to CloudPirates

This guide covers migrating vc-authn-oidc deployments from the Bitnami MongoDB subchart to the CloudPirates MongoDB subchart.

## Breaking Changes Summary

| Change | Before (Bitnami) | After (CloudPirates) |
|--------|------------------|----------------------|
| Service name | `{release}-mongodb-headless` | `{release}-mongodb` (standalone) or `{release}-mongodb-headless` (replicaSet) |
| Secret key | `mongodb-passwords` | `mongodb-password` (in `{release}-mongodb`) |
| Database user | `vcauthn` (dedicated) | `vcauthn` (via `customUser.name`) |
| Default architecture | `replicaset` | `standalone` |
| User creation | Automatic via `auth.usernames[]` | Automatic via `mongodb.customUser.*` |

## Migration Paths

Choose the migration path that best fits your deployment:

- **Path A**: [In-place upgrade with data migration](#path-a-in-place-upgrade-with-data-migration) - Recommended for production
- **Path B**: [Fresh install with external MongoDB](#path-b-fresh-install-with-external-mongodb) - For new deployments or when using managed MongoDB
- **Path C**: [Fresh install (data loss acceptable)](#path-c-fresh-install-data-loss-acceptable) - For dev/test environments

---

## Path A: In-place Upgrade with Data Migration

Use this path to preserve your existing data while upgrading to the new chart version.

### Prerequisites

- `kubectl` access to your cluster
- `mongodump` and `mongorestore` tools (or use MongoDB pod)
- Helm 3.x
- Sufficient storage for backup

### Step 1: Document Current Configuration

```bash
# Get current release values
helm get values <release-name> -n <namespace> > current-values.yaml

# Note the current MongoDB credentials
kubectl get secret <release-name>-mongodb -n <namespace> -o jsonpath='{.data.mongodb-passwords}' | base64 -d
kubectl get secret <release-name>-mongodb -n <namespace> -o jsonpath='{.data.mongodb-root-password}' | base64 -d
```

### Step 2: Scale Down vc-authn-oidc

Prevent writes during backup:

```bash
kubectl scale deployment <release-name>-vc-authn-oidc -n <namespace> --replicas=0
```

### Step 3: Backup MongoDB Data

**Option A: Using mongodump from within the cluster**

```bash
# Create a backup job
kubectl run mongodb-backup --rm -it --restart=Never \
  --image=mongo:8.0 \
  -n <namespace> \
  -- mongodump \
    --host=<release-name>-mongodb-headless \
    --username=vcauthn \
    --password=<password-from-step-1> \
    --authenticationDatabase=vcauthn \
    --db=vcauthn \
    --archive=/tmp/vcauthn-backup.archive

# Copy backup locally
kubectl cp <namespace>/mongodb-backup:/tmp/vcauthn-backup.archive ./vcauthn-backup.archive
```

**Option B: Using existing MongoDB pod**

```bash
# Exec into MongoDB pod
kubectl exec -it <release-name>-mongodb-0 -n <namespace> -- bash

# Inside the pod, create backup
mongodump \
  --username=vcauthn \
  --password=<password> \
  --authenticationDatabase=vcauthn \
  --db=vcauthn \
  --archive=/tmp/vcauthn-backup.archive

# Exit and copy backup
kubectl cp <namespace>/<release-name>-mongodb-0:/tmp/vcauthn-backup.archive ./vcauthn-backup.archive
```

### Step 4: Delete Old MongoDB Resources

```bash
# Delete the old MongoDB StatefulSet and PVC (data will be lost - ensure backup is complete!)
kubectl delete statefulset <release-name>-mongodb -n <namespace>
kubectl delete pvc datadir-<release-name>-mongodb-0 -n <namespace>

# Delete old secrets (optional - new secret will be created)
kubectl delete secret <release-name>-mongodb -n <namespace>
```

### Step 5: Prepare New Values File

Create `migration-values.yaml`:

```yaml
mongodb:
  enabled: true

  # Keep the same root password for consistency
  auth:
    enabled: true
    rootUsername: "admin"
    # Use existingSecret to preserve password, or set rootPassword directly
    # existingSecret: "<release-name>-mongodb"
    rootPassword: "<root-password-from-step-1>"

  # Match your previous persistence settings
  persistence:
    enabled: true
    storageClass: "<your-storage-class>"
    size: 8Gi

  # For OpenShift deployments
  # targetPlatform: "openshift"
```

### Step 6: Upgrade the Helm Release

```bash
helm upgrade <release-name> owf/vc-authn-oidc \
  -n <namespace> \
  -f current-values.yaml \
  -f migration-values.yaml \
  --version <new-chart-version>
```

### Step 7: Restore Data

```bash
# Wait for new MongoDB to be ready
kubectl wait --for=condition=ready pod/<release-name>-mongodb-0 -n <namespace> --timeout=300s

# Copy backup to new pod
kubectl cp ./vcauthn-backup.archive <namespace>/<release-name>-mongodb-0:/tmp/vcauthn-backup.archive

# Restore the backup
kubectl exec -it <release-name>-mongodb-0 -n <namespace> -- mongorestore \
  --username=admin \
  --password=<root-password> \
  --authenticationDatabase=admin \
  --nsFrom="vcauthn.*" \
  --nsTo="vcauthn.*" \
  --archive=/tmp/vcauthn-backup.archive
```

### Step 8: Scale Up vc-authn-oidc

```bash
kubectl scale deployment <release-name>-vc-authn-oidc -n <namespace> --replicas=1
```

### Step 9: Verify

```bash
# Check pod status
kubectl get pods -n <namespace> -l app.kubernetes.io/instance=<release-name>

# Check vc-authn-oidc logs for MongoDB connectivity
kubectl logs -l component=controller -n <namespace> | grep -i mongo

# Test the application
curl https://<your-vc-authn-url>/health
```

---

## Path B: Fresh Install with External MongoDB

Use this path when migrating to a managed MongoDB service (Atlas, DocumentDB, etc.) or a separately managed MongoDB instance.

### Step 1: Set Up External MongoDB

Deploy your external MongoDB and create the required database and user:

```javascript
// Connect to MongoDB as admin
use admin

// Create the vcauthn database and user (optional - can use root)
use vcauthn
db.createUser({
  user: "vcauthn",
  pwd: "your-secure-password",
  roles: [{ role: "readWrite", db: "vcauthn" }]
})
```

### Step 2: Migrate Data (if applicable)

Export from old deployment:

```bash
mongodump \
  --host=<old-mongodb-host> \
  --username=vcauthn \
  --password=<old-password> \
  --authenticationDatabase=vcauthn \
  --db=vcauthn \
  --archive=vcauthn-backup.archive
```

Import to new MongoDB:

```bash
mongorestore \
  --uri="mongodb://<new-mongodb-host>:27017" \
  --username=<username> \
  --password=<password> \
  --authenticationDatabase=<auth-db> \
  --nsFrom="vcauthn.*" \
  --nsTo="vcauthn.*" \
  --archive=vcauthn-backup.archive
```

### Step 3: Create Secret for External MongoDB

```bash
kubectl create secret generic external-mongodb-secret \
  -n <namespace> \
  --from-literal=mongodb-password=<your-password>
```

### Step 4: Configure Helm Values

Create `external-mongodb-values.yaml`:

```yaml
# Disable bundled MongoDB
mongodb:
  enabled: false

# Configure external MongoDB
externalMongodb:
  host: "your-mongodb-host.example.com"
  port: 27017
  database: "vcauthn"
  auth:
    enabled: true
    username: "vcauthn"  # or "admin" if using root
    existingSecret: "external-mongodb-secret"
    existingSecretPasswordKey: "mongodb-password"
```

### Step 5: Upgrade/Install

```bash
helm upgrade --install <release-name> owf/vc-authn-oidc \
  -n <namespace> \
  -f external-mongodb-values.yaml \
  --version <new-chart-version>
```

---

## Path C: Fresh Install (Data Loss Acceptable)

Use this path for dev/test environments where data loss is acceptable.

### Step 1: Uninstall Current Release

```bash
# Uninstall the release
helm uninstall <release-name> -n <namespace>

# Delete PVCs to remove old data
kubectl delete pvc -l app.kubernetes.io/instance=<release-name> -n <namespace>
```

### Step 2: Install New Version

```bash
helm install <release-name> owf/vc-authn-oidc \
  -n <namespace> \
  --version <new-chart-version>
```

---

## Troubleshooting

### Authentication Failures

**Symptom**: vc-authn-oidc logs show MongoDB authentication errors.

**Solution**: Verify the credentials match:

```bash
# Check what credentials vc-authn-oidc is using
kubectl get deployment <release-name>-vc-authn-oidc -n <namespace> -o yaml | grep -A5 "OIDC_CONTROLLER_DB_USER"

# Check the secret
kubectl get secret <release-name>-mongodb -n <namespace> -o yaml
```

### Connection Refused

**Symptom**: Connection refused errors to MongoDB.

**Solution**: Verify the service name:

```bash
# Check MongoDB service exists
kubectl get svc -n <namespace> | grep mongodb

# The service should be: <release-name>-mongodb (NOT <release-name>-mongodb-headless)
```

### Network Policy Blocking Traffic

**Symptom**: Timeout connecting to MongoDB.

**Solution**: Verify network policy and pod labels:

```bash
# Check network policy
kubectl get networkpolicy <release-name>-vc-authn-oidc-db -n <namespace> -o yaml

# Verify MongoDB pods have the required label
kubectl get pods -l app.kubernetes.io/role=database -n <namespace>
```

### Data Not Visible After Restore

**Symptom**: Application works but data is missing.

**Solution**: Verify restore used correct namespace mapping:

```bash
# Connect to MongoDB and check collections
kubectl exec -it <release-name>-mongodb-0 -n <namespace> -- mongosh \
  --username admin \
  --password <password> \
  --authenticationDatabase admin \
  --eval "use vcauthn; db.getCollectionNames()"
```

---

## Rollback Procedure

If the migration fails and you need to rollback:

### Step 1: Restore Previous Chart Version

```bash
# Rollback to previous revision
helm rollback <release-name> <previous-revision> -n <namespace>

# Or reinstall previous version
helm install <release-name> owf/vc-authn-oidc \
  -n <namespace> \
  --version <previous-chart-version> \
  -f current-values.yaml
```

### Step 2: Restore Data from Backup

Follow the restore steps from Path A, Step 7, but target the old MongoDB instance.

---

## Support

If you encounter issues not covered in this guide:

1. Check the [vc-authn-oidc GitHub issues](https://github.com/openwallet-foundation/vc-authn-oidc/issues)
2. Review the [Helm chart documentation](https://github.com/openwallet-foundation/helm-charts)
3. Open a new issue with:
   - Chart version (before and after)
   - Error messages
   - Relevant logs
   - Steps to reproduce
