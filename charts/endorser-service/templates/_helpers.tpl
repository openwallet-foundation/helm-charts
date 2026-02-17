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
helm.sh/chart: {{ include "endorser-service.chart" . }}
{{ include "endorser-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "endorser-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "endorser-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return an existing secret value, or generate a random one if the secret does not yet exist.
Uses lookup to preserve values across upgrades (lookup-then-retain pattern for GitOps idempotency).
For Secrets the returned value is base64-encoded; for other kinds it is plain text.

Usage:
{{ include "getOrGeneratePass" (dict "Namespace" .Release.Namespace "Kind" "Secret" "Name" "my-secret" "Key" "my-key" "Length" 32) }}
*/}}
{{- define "getOrGeneratePass" }}
{{- $len := (default 16 .Length) | int -}}
{{- $obj := (lookup "v1" .Kind .Namespace .Name).data -}}
{{- if $obj }}
{{- index $obj .Key -}}
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
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
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
Return the secret key name for the admin (postgres) password.
*/}}
{{- define "endorser-service.db.adminPasswordKey" -}}
{{- if .Values.postgres.enabled -}}
postgres-password
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
{{- .Values.postgres.customUser.database | default .Values.postgres.customUser.name | default "endorser" -}}
{{- else -}}
{{- .Values.externalDatabase.database | default "endorser" -}}
{{- end -}}
{{- end -}}

{{/*
Return the database application username.
*/}}
{{- define "endorser-service.db.username" -}}
{{- if .Values.postgres.enabled -}}
{{- .Values.postgres.customUser.name | default "endorser" -}}
{{- else -}}
{{- .Values.externalDatabase.username | default "endorser" -}}
{{- end -}}
{{- end -}}

{{/*
Return the database admin username.
For bundled postgres the superuser is always "postgres".
For external databases uses adminUsername, falling back to username.
*/}}
{{- define "endorser-service.db.adminUser" -}}
{{- if .Values.postgres.enabled -}}
postgres
{{- else -}}
  {{- if .Values.externalDatabase.adminUsername -}}
{{- .Values.externalDatabase.adminUsername -}}
  {{- else -}}
{{- .Values.externalDatabase.username | default "postgres" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
