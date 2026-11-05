{{/*
Expand the name of the chart.
*/}}
{{- define "global.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "global.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "global.fullname" -}}
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
Common labels
*/}}
{{- define "common.labels" -}}
app: {{ include "global.name" . }}
helm.sh/chart: {{ include "global.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Selector common labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "mediator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mediator.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "mediator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mediator.labels" -}}
helm.sh/chart: {{ include "mediator.chart" . }}
{{ include "mediator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mediator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mediator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mediator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mediator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Returns a secret if it already in Kubernetes, otherwise it creates
it randomly.

Usage:
{{ include "getOrGeneratePass" (dict "Namespace" .Release.Namespace "Kind" "Secret" "Name" secretName "Key" "secret-key" "Length" 32) }}

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
Returns a secret if it already in Kubernetes, otherwise it creates
it with the given value.

Usage:
{{ include "getOrCreateSecret" (dict "Namespace" .Release.Namespace "Kind" "Secret" "Name" secretName "Key" "secret-key" "DefaultValue" "default-value") }}

*/}}
{{- define "getOrCreateSecret" }}
{{- $default := .DefaultValue -}}
{{- $obj := (lookup "v1" .Kind .Namespace .Name).data -}}
{{- if $obj }}
{{- index $obj .Key -}}
{{- else -}}
{{- $default | b64enc -}}
{{- end -}}
{{- end }}

{{/*
Returns the literal value of a variable in .Values.environment, empty if unset or set with valueFrom.
*/}}
{{- define "mediator.environmentValue" -}}
{{- $name := .name -}}
{{- range .context.Values.environment -}}
{{- if and (eq .name $name) (not (kindIs "invalid" .value)) -}}
{{- .value -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Resolve the wallet backend without treating externally supplied configuration as SQLite.
*/}}
{{- define "mediator.walletDatabaseType" -}}
{{- $declared := .Values.walletDatabaseType | default "auto" -}}
{{- if not (has $declared (list "auto" "sqlite" "postgres")) -}}
{{- fail "walletDatabaseType must be auto, sqlite or postgres" -}}
{{- end -}}
{{- $literal := include "mediator.environmentValue" (dict "name" "ASKAR__DATABASE__TYPE" "context" .) -}}
{{- $external := false -}}
{{- range .Values.environment -}}
{{- if or (eq .name "CONFIG") (and (eq .name "ASKAR__DATABASE__TYPE") .valueFrom) -}}
{{- $external = true -}}
{{- end -}}
{{- end -}}
{{- if and $literal (not (has $literal (list "sqlite" "postgres"))) -}}
{{- fail "ASKAR__DATABASE__TYPE must be sqlite or postgres" -}}
{{- end -}}
{{- if and (ne $declared "auto") $literal (ne $declared $literal) -}}
{{- fail "walletDatabaseType conflicts with literal ASKAR__DATABASE__TYPE" -}}
{{- end -}}
{{- if $literal -}}
{{- $literal -}}
{{- else if ne $declared "auto" -}}
{{- $declared -}}
{{- else if $external -}}
unknown
{{- else -}}
sqlite
{{- end -}}
{{- end }}

{{/*
Fails rendering for configurations the mediator would reject or silently ignore.
*/}}
{{- define "mediator.validateEnvironment" -}}
{{- $legacy := list "WALLET_NAME" "WALLET_KEY" "POSTGRES_HOST" "POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_ADMIN_USER" "POSTGRES_ADMIN_PASSWORD" "PICKUP_TYPE" "PICKUP_STRATEGY" "PICKUP_SETTINGS" "USE_PUSH_NOTIFICATIONS" "PUSH_NOTIFICATION_TITLE" "PUSH_NOTIFICATION_BODY" "FIREBASE_APPS" "GOAL_CODE" "NOTIFICATION_WEBHOOK_URL" -}}
{{- $names := list -}}
{{- range .Values.environment -}}
{{- if has .name $legacy -}}
{{- fail (printf "environment variable %s is not read by the mediator since chart 1.0; see 'Upgrading from chart 0.6.x' in the chart README" .name) -}}
{{- end -}}
{{- $names = append $names .name -}}
{{- end -}}
{{- if regexMatch "^[0-9]+$" (include "mediator.environmentValue" (dict "name" "LOG_LEVEL" "context" .)) -}}
{{- fail "LOG_LEVEL must be one of trace, debug, info, warn, error, fatal or off" -}}
{{- end -}}
{{- $backend := include "mediator.walletDatabaseType" . -}}
{{- if and (eq $backend "unknown") (or .Values.autoscaling.enabled (gt (int .Values.replicaCount) 1)) -}}
{{- fail "externally configured wallets require walletDatabaseType=postgres for multiple replicas; this declaration does not configure the application backend" -}}
{{- end -}}
{{- if eq $backend "unknown" -}}
{{- fail "externally configured wallets require walletDatabaseType=sqlite or postgres to select a safe rollout strategy; this declaration does not configure the application backend" -}}
{{- end -}}
{{- if and (eq $backend "postgres") .Values.persistence.enabled -}}
{{- fail "PostgreSQL wallets require persistence.enabled=false: the chart PVC is for SQLite home-directory data and can stall rolling updates" -}}
{{- end -}}
{{- if and (eq $backend "sqlite") (or .Values.autoscaling.enabled (gt (int .Values.replicaCount) 1)) -}}
{{- fail "a SQLite wallet can't be shared between replicas: set ASKAR__DATABASE__TYPE=postgres in environment, or run a single replica without autoscaling" -}}
{{- end -}}
{{- if .Values.pushNotifications.firebase.enabled -}}
{{- range list "PUSH_NOTIFICATIONS__FIREBASE__NOTIFICATION_TITLE" "PUSH_NOTIFICATIONS__FIREBASE__NOTIFICATION_BODY" -}}
{{- if not (has . $names) -}}
{{- fail (printf "pushNotifications.firebase.enabled requires %s in environment" .) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
