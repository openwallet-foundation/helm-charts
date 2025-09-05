{{/*
generate hosts if not overriden
*/}}
{{- define "acapy.host" -}}
{{- if and .Values.agentUrl (not .Values.ingress.agent.enabled) }}
    {{ .Values.agentUrl }}
{{- else -}}
    {{ tpl .Values.ingress.agent.hostname . }}
{{- end -}}
{{- end -}}

{{/*
Create URL based on hostname and TLS status
*/}}
{{- define "acapy.agent.url" -}}
{{- if and .Values.agentUrl (not .Values.ingress.agent.enabled) }}
{{- printf "%s" .Values.agentUrl }}
{{- else if .Values.ingress.agent.enabled -}}
{{- $scheme := (default "https" .Values.ingress.agent.publicScheme) -}}
{{- printf "%s://%s" $scheme (include "acapy.host" .) }}
{{- else -}}
{{- $scheme := (default "https" .Values.service.publicScheme) -}}
{{- printf "%s://%s" $scheme (include "acapy.host" .) }}
{{- end -}}
{{- end }}

{{/*
Create Websockets URL based on hostname and TLS status
*/}}
{{- define "acapy.agent.wsUrl" -}}
{{- if .Values.websockets.publicUrl -}}
{{- printf "%s" .Values.websockets.publicUrl }}
{{- else if and .Values.agentUrl (not .Values.ingress.agent.enabled) -}}
{{- /* Map http->ws and https->wss */ -}}
{{- regexReplaceAll "^http" .Values.agentUrl "ws" | trim -}}
{{- else if .Values.ingress.agent.enabled -}}
{{- $scheme := (default "https" .Values.ingress.agent.publicScheme) -}}
{{- if eq $scheme "https" -}}
{{- printf "wss://%s" (include "acapy.host" .) }}
{{- else -}}
{{- printf "ws://%s" (include "acapy.host" .) }}
{{- end -}}
{{- else -}}
{{- $scheme := (default "https" .Values.service.publicScheme) -}}
{{- if eq $scheme "https" -}}
{{- printf "wss://%s" (include "acapy.host" .) }}
{{- else -}}
{{- printf "ws://%s" (include "acapy.host" .) }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Return the proper ACA-Py image name
*/}}
{{- define "acapy.image" -}}
{{ include "common.images.image" ( dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart ) }}
{{- end -}}

{{/*
Returns a secret if it already in Kubernetes, otherwise it creates
it randomly.

Usage:
{{ include "getOrGeneratePass" (dict "Namespace" .Release.Namespace "Kind" "Secret" "Name" (include "acapy.databaseSecretName" .) "Key" "postgres-password" "Length" 32) }}

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
Multitenancy config (Legacy support)
*/}}
{{- define "acapy.multitenancyConfiguration" -}}
{{- if .Values.multitenancyConfiguration.json -}}
{{- .Values.multitenancyConfiguration.json -}}
{{- else -}}
'{"wallet_type":"{{ .Values.multitenancyConfiguration.wallet_type | default "single-wallet-askar" }}"}'
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name for the postgres requirement.
*/}}
{{- define "global.postgresql.fullname" -}}
{{- if .Values.postgresql.fullnameOverride }}
{{- .Values.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $postgresContext := dict "Values" .Values.postgresql "Release" .Release "Chart" (dict "Name" "postgresql") -}}
{{ template "postgresql.v1.primary.fullname" $postgresContext }}
{{- end -}}
{{- end -}}

{{/*
Return the Secret that holds the Postgres credentials.

* If the user overrides it with `walletStorageCredentials.existingSecret`,
  evaluate that value with `tpl` so they can embed template expressions.
* Otherwise fall back to whatever **the Postgres sub‑chart** says
  its fullname is – that helper already honours `nameOverride`
  or `fullnameOverride`, so we inherit the correct string automatically.
*/}}
{{- define "acapy.database.secretName" -}}
{{- if .Values.walletStorageCredentials.existingSecret -}}
{{ tpl .Values.walletStorageCredentials.existingSecret . }}
{{- else -}}
{{ include "global.postgresql.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Generate ACA-Py wallet storage config
*/}}
{{- define "acapy.walletStorageConfig" -}}
{{- if .Values.walletStorageConfig.json -}}
    {{- .Values.walletStorageConfig.json -}}
{{- else if .Values.walletStorageConfig.url -}}
    '{"url":"{{ .Values.walletStorageConfig.url }}","max_connections":"{{ .Values.walletStorageConfig.max_connection | default 10 }}", "wallet_scheme":"{{ .Values.walletStorageConfig.wallet_scheme }}"}'
{{- else if .Values.postgresql.enabled -}}
    '{"url":"{{ include "global.postgresql.fullname" . }}:{{ .Values.postgresql.primary.service.ports.postgresql }}","max_connections":"{{ .Values.walletStorageConfig.max_connections }}","wallet_scheme":"{{ .Values.walletStorageConfig.wallet_scheme }}"}'
{{- else -}}
    ''
{{ end }}
{{- end -}}

{{/*
Generate ACA-Py wallet storage credentials
*/}}
{{- define "acapy.walletStorageCredentials" -}}
{{- if .Values.walletStorageCredentials.json -}}
    {{- .Values.walletStorageCredentials.json -}}
{{- else if .Values.postgresql.enabled -}}
    '{"account":"{{ .Values.postgresql.auth.username }}","password":"$(POSTGRES_PASSWORD)","admin_account":"{{ .Values.walletStorageCredentials.admin_account }}","admin_password":"$(POSTGRES_POSTGRES_PASSWORD)"}'
{{- else -}}
    '{"account":"{{ .Values.walletStorageCredentials.account | default "acapy" }}","password":"$(POSTGRES_PASSWORD)","admin_account":"{{ .Values.walletStorageCredentials.admin_account }}","admin_password":"$(POSTGRES_POSTGRES_PASSWORD)"}'
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "acapy.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "acapy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
