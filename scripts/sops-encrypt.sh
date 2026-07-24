#!/bin/bash
# sops-encrypt.sh — Encrypt a YAML file with SOPS using age

set -euo pipefail

FILE="${1:?Usage: sops-encrypt.sh <file>}"

if [ ! -f "$FILE" ]; then
  echo "Error: File $FILE not found"
  exit 1
fi

# Encrypt with SOPS
sops --encrypt --in-place "$FILE"

echo "Encrypted: $FILE"
