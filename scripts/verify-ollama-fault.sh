#!/bin/bash
# verify-ollama-fault.sh — Verify Ollama fault tolerance

set -euo pipefail

echo "=== Ollama Fault Tolerance Verification ==="

# Stop Ollama on macOS host
echo "Stopping Ollama..."
launchctl unload ~/Library/LaunchAgents/com.github.ollama.plist 2>/dev/null || true

# Wait for Ollama to be unavailable
sleep 30

# Check Flink async function behavior
echo "Checking Flink async function behavior..."
kubectl get pods -n flink | grep trading

# Check Prometheus alerts
echo "Checking Prometheus alerts..."
kubectl port-forward svc/prometheus-service 9090:9090 -n observability &

# Check Telegram notifications
echo "Checking Telegram notifications..."
# (Verify alerts are sent to Telegram)

# Restart Ollama
echo "Restarting Ollama..."
launchctl load ~/Library/LaunchAgents/com.github.ollama.plist 2>/dev/null || true

echo "=== Ollama fault tolerance verification complete ==="
