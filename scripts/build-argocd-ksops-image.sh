#!/usr/bin/env bash
set -euo pipefail

readonly sops_version="v3.10.2"
readonly sops_asset="sops-${sops_version}.linux.arm64"
readonly sops_sha256="e91ddc04e6a78f5aed9e4fc347a279b539c43b74d99e6b8078e2f2f6f5b309f5"
readonly image="${1:-big-data-platform/argocd-ksops-sops:v4.5.1-sops-v3.10.2}"
readonly repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly build_dir="$(mktemp -d)"

cleanup() {
  rm -rf "${build_dir}"
}
trap cleanup EXIT

curl --fail --silent --show-error --location \
  "https://github.com/getsops/sops/releases/download/${sops_version}/${sops_asset}" \
  --output "${build_dir}/sops"

actual_sha256="$(shasum -a 256 "${build_dir}/sops" | awk '{print $1}')"
if [[ "${actual_sha256}" != "${sops_sha256}" ]]; then
  echo "SOPS SHA-256 verification failed" >&2
  exit 1
fi

chmod 0755 "${build_dir}/sops"
docker build \
  --platform linux/arm64 \
  --file "${repo_root}/bootstrap/ksops/Dockerfile" \
  --tag "${image}" \
  "${build_dir}"

echo "Built ${image}"
