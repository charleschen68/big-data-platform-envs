#!/bin/bash
# sops-decrypt.sh — Decrypt a YAML file with SOPS using age

set -euo pipefail

FILE="${1:?Usage: sops-decrypt.sh <file>}"

if [ ! -f "$FILE" ]; then
  echo "Error: File $FILE not found"
  exit 1
fi

# Decrypt with SOPS
sops --decrypt "$FILE"
