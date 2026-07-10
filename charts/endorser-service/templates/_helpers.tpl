{{/*
Expand the name of the chart.
*/}}
{{- define "endorser-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "endorser-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified name for the postgres subchart.
Delegates to the postgres subchart's own fullname template, respecting fullnameOverride.
Produces "<release>-postgres" by default.
*/}}
{{- define "endorser-service.postgres.fullname" -}}
{{- if .Values.postgres.fullnameOverride }}
{{- .Values.postgres.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $postgresContext := dict "Values" .Values.postgres "Release" .Release "Chart" (dict "Name" "postgres") -}}
{{- include "postgres.fullname" $postgresContext | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "endorser-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "endorser-service.labels" -}}
{{- $labels := dict -}}
{{- with .Values.commonLabels }}
{{- $labels = mergeOverwrite $labels . -}}
{{- end }}
{{- $labels = mergeOverwrite $labels (dict "helm.sh/chart" (include "endorser-service.chart" .)) -}}
{{- $labels = mergeOverwrite $labels (fromYaml (include "endorser-service.selectorLabels" .)) -}}
{{- if .Chart.AppVersion }}
{{- $labels = mergeOverwrite $labels (dict "app.kubernetes.io/version" .Chart.AppVersion) -}}
{{- end }}
{{- $labels = mergeOverwrite $labels (dict "app.kubernetes.io/managed-by" .Release.Service) -}}
{{- toYaml $labels -}}
{{- end }}

{{/*
Common annotations merged with resource-specific annotations.
*/}}
{{- define "endorser-service.renderAnnotations" -}}
{{- $annotations := dict -}}
{{- with .context.Values.commonAnnotations }}
{{- $annotations = mergeOverwrite $annotations . -}}
{{- end }}
{{- with .annotations }}
{{- $annotations = mergeOverwrite $annotations . -}}
{{- end }}
{{- if $annotations }}
{{- toYaml $annotations -}}
{{- end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "endorser-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "endorser-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return an existing secret value, or generate a random one if missing.
Uses lookup to preserve values across upgrades (lookup-then-retain).
Critical for postgres: password / postgres-password must stay stable — regenerating
them desyncs from the PVC and forces a destructive wipe. Only generate when the
Secret is absent or the specific key is missing/empty (e.g. adding admin-password
on upgrade). Never delete the chart-managed DB secret to "recreate" keys.
For Secrets the returned value is base64-encoded; for other kinds it is plain text.

Usage:
{{ include "getOrGeneratePass" (dict "Namespace" .Release.Namespace "Kind" "Secret" "Name" "my-secret" "Key" "my-key" "Length" 32) }}
*/}}
{{- define "getOrGeneratePass" }}
{{- $len := (default 16 .Length) | int -}}
{{- $obj := (lookup "v1" .Kind .Namespace .Name).data -}}
{{- $existing := "" -}}
{{- if $obj -}}
{{- $existing = index $obj .Key | default "" -}}
{{- end -}}
{{- if $existing -}}
{{- $existing -}}
{{- else if (eq (lower .Kind) "secret") -}}
{{- randAlphaNum $len | b64enc -}}
{{- else -}}
{{- randAlphaNum $len -}}
{{- end -}}
{{- end }}

{{/*
Return the name of the service account to use.
*/}}
{{- define "endorser-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "endorser-service.fullname" .) .Values.serviceAccount.name }}
{{- else if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Return the name of the API secret.
Uses an existing secret name if provided, otherwise generates "<release>-api".
*/}}
{{- define "endorser-service.apiSecretName" -}}
{{- if (empty .Values.secrets.api.existingSecret) }}
    {{- printf "%s-%s" .Release.Name "api" | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{- .Values.secrets.api.existingSecret }}
{{- end -}}
{{- end }}

{{/*
Return the name of the JWT secret.
Uses an existing secret name if provided, otherwise generates "<release>-jwt".
*/}}
{{- define "endorser-service.jwtSecretName" -}}
{{- if (empty .Values.secrets.jwt.existingSecret) }}
    {{- printf "%s-%s" .Release.Name "jwt" | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{- .Values.secrets.jwt.existingSecret }}
{{- end -}}
{{- end }}

{{/*
Return the name of the webhook secret used by ACA-Py.
Contains the ACAPY_WEBHOOK_URL with embedded API key.
*/}}
{{- define "endorser-service.webhookSecretName" -}}
    {{- printf "%s-acapy-webhook" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the ACA-Py subchart base name.
*/}}
{{- define "endorser-service.acapy.name" -}}
{{- default "acapy" .Values.acapy.nameOverride -}}
{{- end -}}

{{/*
Create a default fully qualified ACA-Py name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "endorser-service.acapy.fullname" -}}
{{- $name := include "endorser-service.acapy.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Return the ACA-Py API secret name.
Uses an existing secret name if provided, otherwise derives from acapy fullname.
*/}}
{{- define "endorser-service.acapy.secretName" -}}
    {{- if .Values.acapy.secrets.api.existingSecret -}}
        {{- .Values.acapy.secrets.api.existingSecret -}}
    {{- else -}}
        {{- printf "%s-api" (include "endorser-service.acapy.fullname" .) | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
{{- end -}}

{{/*
Generate the ACA-Py agent hostname from release name and ingress suffix.
*/}}
{{- define "endorser-service.acapy.host" -}}
    {{- printf "%s%s" (include "endorser-service.acapy.fullname" .) .Values.global.ingressSuffix -}}
{{- end -}}

{{/*
Create the ACA-Py agent URL based on hostname and TLS status.
*/}}
{{- define "endorser-service.acapy.agentUrl" -}}
{{- if .Values.useHTTPS -}}
{{- printf "https://%s" (include "endorser-service.acapy.host" .) }}
{{- else -}}
{{- printf "http://%s" (include "endorser-service.acapy.host" .) }}
{{- end -}}
{{- end }}

{{/*
Return the internal ACA-Py admin API URL (cluster-local).
*/}}
{{- define "endorser-service.acapy.adminUrl" -}}
    http://{{ include "endorser-service.acapy.fullname" . }}:{{ .Values.acapy.service.ports.admin }}
{{- end -}}

{{/*
Generate the ACA-Py admin hostname from release name and ingress suffix.
*/}}
{{- define "endorser-service.acapy.adminHost" -}}
   {{- printf "%s-admin%s" (include "endorser-service.acapy.fullname" .) .Values.global.ingressSuffix -}}
{{- end -}}

{{/*
Return the ACA-Py subchart's PostgreSQL service name.
Uses acapy.postgres.nameOverride if set, otherwise defaults to "postgres".
*/}}
{{- define "endorser-service.acapy.postgresqlServiceName" -}}
{{- $pgName := default "postgres" .Values.acapy.postgres.nameOverride -}}
{{- printf "%s-%s" .Release.Name $pgName -}}
{{- end -}}

{{/*
Return the database hostname.
Uses the postgres subchart service name when bundled postgres is enabled,
or externalDatabase.host when postgres is disabled (external database).
*/}}
{{- define "endorser-service.db.host" -}}
{{- if .Values.postgres.enabled -}}
{{ include "endorser-service.postgres.fullname" . }}
{{- else -}}
{{- required "externalDatabase.host is required when postgres.enabled is false" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing database credentials.
For bundled postgres this is the consolidated secret (created by database-secret.yaml).
For external databases this requires externalDatabase.existingSecret to be set.
*/}}
{{- define "endorser-service.db.secretName" -}}
{{- if .Values.postgres.enabled -}}
  {{- include "endorser-service.postgres.fullname" . -}}
{{- else -}}
  {{- required "externalDatabase.existingSecret is required when postgres.enabled is false" .Values.externalDatabase.existingSecret -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret key name for the application user password.
*/}}
{{- define "endorser-service.db.userPasswordKey" -}}
{{- if .Values.postgres.enabled -}}
password
{{- else -}}
{{- default "password" .Values.externalDatabase.secretKeys.userPasswordKey -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret key name for the admin (owner-role) password.
For bundled postgres this is customAdminUser (Alembic / DB owner), not the
postgres superuser password key.
For external databases this is the configured admin password key.
*/}}
{{- define "endorser-service.db.adminPasswordKey" -}}
{{- if .Values.postgres.enabled -}}
admin-password
{{- else -}}
{{- default "postgres-password" .Values.externalDatabase.secretKeys.adminPasswordKey -}}
{{- end -}}
{{- end -}}

{{/*
Return the database port.
*/}}
{{- define "endorser-service.db.port" -}}
{{- if .Values.postgres.enabled -}}
{{- .Values.postgres.service.port | default 5432 -}}
{{- else -}}
{{- .Values.externalDatabase.port | default 5432 -}}
{{- end -}}
{{- end -}}

{{/*
Return the database name.
*/}}
{{- define "endorser-service.db.database" -}}
{{- if .Values.postgres.enabled -}}
{{- .Values.postgres.customUser.database | default .Values.postgres.customUser.name -}}
{{- else -}}
{{- required "externalDatabase.database is required when postgres.enabled is false" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the database application username.
*/}}
{{- define "endorser-service.db.username" -}}
{{- if .Values.postgres.enabled -}}
{{- .Values.postgres.customUser.name -}}
{{- else -}}
{{- required "externalDatabase.username is required when postgres.enabled is false" .Values.externalDatabase.username -}}
{{- end -}}
{{- end -}}

{{/*
Return the database admin username (Alembic / owner role).
For bundled postgres this is customAdminUser (not the postgres superuser and not
customUser). Migrating as postgres leaves tables owned by superuser and the app
user then hits "permission denied" on fresh installs / PVC recreate.
For external databases uses adminUsername, falling back to username.
*/}}
{{- define "endorser-service.db.adminUser" -}}
{{- if .Values.postgres.enabled -}}
{{- .Values.postgres.customAdminUser.name -}}
{{- else -}}
  {{- if .Values.externalDatabase.adminUsername -}}
{{- .Values.externalDatabase.adminUsername -}}
  {{- else -}}
{{- include "endorser-service.db.username" . -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
SQL body for ensure-db-roles (psql -v APP_USER/ADMIN_USER/ADMIN_PASSWORD).
Creates customAdminUser, sets DB owner, grants DML defaults to the app user,
and reassigns objects left owned by the app user or postgres.
*/}}
{{- define "endorser-service.db.ensureRolesSql" -}}
SELECT quote_ident(:'APP_USER') AS app_user \gset
SELECT quote_ident(:'ADMIN_USER') AS admin_user \gset
SELECT quote_literal(:'ADMIN_PASSWORD') AS admin_password \gset
SELECT quote_ident(current_database()) AS dbname \gset

SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = :'ADMIN_USER') AS admin_exists \gset
\if :admin_exists
  ALTER ROLE :admin_user WITH LOGIN PASSWORD :admin_password;
\else
  CREATE ROLE :admin_user LOGIN PASSWORD :admin_password;
\endif

ALTER DATABASE :dbname OWNER TO :admin_user;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE :dbname TO :app_user;
GRANT ALL ON SCHEMA public TO :admin_user;
GRANT USAGE ON SCHEMA public TO :app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE :admin_user IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE :admin_user IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO :app_user;
ALTER DEFAULT PRIVILEGES FOR ROLE :admin_user IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO :app_user;
-- Repair app-owned objects from CloudPirates 00-init (DB owner was customUser).
REASSIGN OWNED BY :app_user TO :admin_user;
-- Repair tables/sequences left owned by postgres from older Alembic runs.
-- Do not REASSIGN OWNED BY postgres — that fails on system-required objects.
-- Use \gexec (not DO $$) so psql :'ADMIN_USER' substitution works.
SELECT format(
  CASE c.relkind
    WHEN 'S' THEN 'ALTER SEQUENCE public.%I OWNER TO %I'
    ELSE 'ALTER TABLE public.%I OWNER TO %I'
  END,
  c.relname,
  :'ADMIN_USER'
)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_roles r ON r.oid = c.relowner
WHERE n.nspname = 'public'
  AND r.rolname = 'postgres'
  AND c.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
\gexec
-- Existing objects (including those just reassigned) need explicit grants;
-- ALTER DEFAULT PRIVILEGES only covers objects created afterward.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO :app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO :app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO :app_user;
{{- end -}}

{{/*
Init containers: wait for DB, then (bundled postgres only) ensure customAdminUser.
Used by the API Deployment (before Alembic/startup) and the migration Job.
API must not start until endorser-admin exists — post-install hooks race the
Deployment, and CI emptyDir postgres restarts wipe roles created only by the Job.
*/}}
{{- define "endorser-service.db.ensureRolesInitContainers" -}}
- name: wait-for-db
  image: "{{ .Values.migration.initContainer.image }}:{{ .Values.migration.initContainer.tag }}"
  command: ["/bin/sh","-c"]
  args:
    - >-
      until nc -z {{ include "endorser-service.db.host" . }} {{ include "endorser-service.db.port" . }}; do echo waiting for db; sleep 2; done;
{{- if .Values.postgres.enabled }}
- name: ensure-db-roles
  image: "{{ .Values.postgres.image.registry }}/{{ .Values.postgres.image.repository }}:{{ .Values.postgres.image.tag }}"
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  env:
    - name: PGHOST
      value: {{ include "endorser-service.db.host" . | quote }}
    - name: PGPORT
      value: {{ include "endorser-service.db.port" . | quote }}
    - name: PGDATABASE
      value: {{ include "endorser-service.db.database" . | quote }}
    - name: PGUSER
      value: postgres
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "endorser-service.db.secretName" . }}
          key: {{ .Values.postgres.auth.secretKeys.adminPasswordKey | default "postgres-password" | quote }}
    - name: APP_USER
      value: {{ include "endorser-service.db.username" . | quote }}
    - name: ADMIN_USER
      value: {{ include "endorser-service.db.adminUser" . | quote }}
    - name: ADMIN_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "endorser-service.db.secretName" . }}
          key: {{ include "endorser-service.db.adminPasswordKey" . | quote }}
  command: ["/bin/bash", "-c"]
  args:
    - |
      set -euo pipefail
      echo "Ensuring customAdminUser '${ADMIN_USER}' for '${PGDATABASE}'"
      psql -v ON_ERROR_STOP=1 \
        -v APP_USER="${APP_USER}" \
        -v ADMIN_USER="${ADMIN_USER}" \
        -v ADMIN_PASSWORD="${ADMIN_PASSWORD}" <<'EOSQL'
{{ include "endorser-service.db.ensureRolesSql" . | nindent 6 }}
      EOSQL
      echo "Database roles ready"
{{- end }}
{{- end -}}
