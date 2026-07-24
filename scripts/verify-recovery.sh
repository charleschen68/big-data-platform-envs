#!/bin/bash
# verify-recovery.sh — Verify full system recovery after VM restart

set -euo pipefail

echo "=== VM Restart Recovery Verification ==="

# Check k3s is running
echo "Checking k3s service..."
kubectl get nodes

# Check ArgoCD is synced
echo "Checking ArgoCD sync..."
kubectl get applications -n gitops

# Check all namespaces
echo "Checking namespaces..."
kubectl get namespaces

# Check all pods
echo "Checking pods..."
kubectl get pods -A

# Check Kafka connectivity
echo "Checking Kafka connectivity..."
kubectl run kafka-test --image=strimzi/kafka:latest --rm -it --restart=Never -- \
  kafka-consumer-groups.sh --bootstrap-server kafka-kafka-bootstrap.data.svc.cluster.local:9092 --list

# Check Flink jobs
echo "Checking Flink jobs..."
kubectl get flinkdeployment -n flink

# Check collectors
echo "Checking collectors..."
kubectl get pods -n collectors

# Check observability
echo "Checking observability..."
kubectl get pods -n observability

echo "=== Recovery verification complete ==="
