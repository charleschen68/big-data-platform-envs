#!/usr/bin/env bash
set -euo pipefail

context="${KUBE_CONTEXT:-orbstack}"
age_key_file="${SOPS_AGE_KEY_FILE:?set SOPS_AGE_KEY_FILE to an age identity file}"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

test -r "${age_key_file}" || { echo "age identity is unreadable" >&2; exit 1; }
kubectl --context "${context}" get node >/dev/null

for namespace in ingress gitops; do
  kubectl --context "${context}" get namespace "${namespace}" >/dev/null 2>&1 || \
    kubectl --context "${context}" create namespace "${namespace}"
done

kubectl --context "${context}" -n gitops create secret generic argocd-sops-age \
  --from-file=keys.txt="${age_key_file}" \
  --dry-run=client -o yaml | kubectl --context "${context}" apply -f -

kubectl --context "${context}" -n gitops create configmap argocd-cmp-ksops \
  --from-file=plugin.yaml="${repo_root}/bootstrap/ksops/plugin.yaml" \
  --dry-run=client -o yaml | kubectl --context "${context}" apply -f -

helm upgrade --install traefik traefik/traefik \
  --namespace ingress --version 41.1.1 \
  --values "${repo_root}/bootstrap/traefik/values.yaml" \
  --atomic --wait --timeout 10m

helm upgrade --install argocd argo/argo-cd \
  --namespace gitops --version 10.2.3 \
  --values "${repo_root}/bootstrap/argocd/values.yaml" \
  --atomic --wait --timeout 10m

kubectl --context "${context}" wait --for=condition=Established \
  crd/applications.argoproj.io --timeout=5m
kubectl --context "${context}" apply -f "${repo_root}/environments/current/applications/gitops.yaml"
