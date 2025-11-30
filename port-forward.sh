#!/bin/bash

# Port forward script for Open WebUI
# This script sets up port forwarding and opens the browser

set -e

RELEASE_NAME="openwebui"
NAMESPACE="default"
PORT="8080"

echo "Checking cluster connection..."
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster"
    echo "Please ensure Docker is running and your k3d cluster is up"
    echo "You can check with: kubectl get nodes"
    exit 1
fi

echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod \
    -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" \
    -n ${NAMESPACE} \
    --timeout=120s || {
    echo "❌ Pod is not ready. Check status with: kubectl get pods"
    exit 1
}

echo "Getting pod name..."
POD_NAME=$(kubectl get pods \
    -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" \
    -n ${NAMESPACE} \
    -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ Error: Could not find pod"
    exit 1
fi

echo "✓ Found pod: $POD_NAME"

# Kill any existing port forward on port 8080
if lsof -ti:${PORT} &>/dev/null; then
    echo "Killing existing port forward on port ${PORT}..."
    kill $(lsof -ti:${PORT}) 2>/dev/null || true
    sleep 2
fi

echo "Setting up port forward..."
echo "Access Open WebUI at: http://localhost:${PORT}"
echo "Press Ctrl+C to stop port forwarding"
echo ""

# Port forward in background and open browser
kubectl port-forward ${POD_NAME} ${PORT}:${PORT} -n ${NAMESPACE} &
PF_PID=$!

# Wait a moment for port forward to establish
sleep 3

# Open browser
if command -v open &>/dev/null; then
    open "http://localhost:${PORT}"
elif command -v xdg-open &>/dev/null; then
    xdg-open "http://localhost:${PORT}"
fi

# Wait for port forward process
wait $PF_PID

