#!/bin/bash

# Conflict Detection Script for Open WebUI Helm Chart
# Detects port conflicts, resource conflicts, and configuration issues

set -e

RELEASE_NAME="openwebui"
NAMESPACE="default"
PORT="8080"

echo "========================================="
echo "Open WebUI Conflict Detection"
echo "========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CONFLICTS_FOUND=0

# 1. Check Kubernetes cluster connection
echo "1. Checking Kubernetes cluster connection..."
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ ERROR: Cannot connect to Kubernetes cluster${NC}"
    echo "   Docker may not be running or k3d cluster is down"
    echo "   Run: docker ps (to check Docker)"
    echo "   Run: k3d cluster list (to check k3d clusters)"
    CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
else
    echo -e "${GREEN}✓ Cluster connection OK${NC}"
fi
echo ""

# 2. Check port 8080 conflicts
echo "2. Checking port ${PORT} conflicts..."
PORT_CONFLICTS=$(lsof -ti:${PORT} 2>/dev/null | wc -l | tr -d ' ')
if [ "$PORT_CONFLICTS" -gt 0 ]; then
    echo -e "${YELLOW}⚠ WARNING: Port ${PORT} is in use by ${PORT_CONFLICTS} process(es)${NC}"
    echo "   Processes using port ${PORT}:"
    lsof -i :${PORT} 2>/dev/null | tail -n +2 | awk '{print "   - PID " $2 ": " $1 " (" $9 ")"}'
    echo "   To free the port: kill \$(lsof -ti:${PORT})"
    CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
else
    echo -e "${GREEN}✓ Port ${PORT} is available${NC}"
fi
echo ""

# 3. Check for multiple Helm releases
echo "3. Checking for duplicate Helm releases..."
if kubectl cluster-info &>/dev/null; then
    RELEASE_COUNT=$(helm list -n ${NAMESPACE} 2>/dev/null | grep -c ${RELEASE_NAME} || echo "0")
    if [ "$RELEASE_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}⚠ WARNING: Multiple releases found${NC}"
        helm list -n ${NAMESPACE} | grep ${RELEASE_NAME}
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    elif [ "$RELEASE_COUNT" -eq 1 ]; then
        echo -e "${GREEN}✓ Single release found${NC}"
    else
        echo -e "${YELLOW}⚠ No release found (may not be installed)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (cluster not connected)${NC}"
fi
echo ""

# 4. Check for multiple pods
echo "4. Checking for duplicate pods..."
if kubectl cluster-info &>/dev/null; then
    POD_COUNT=$(kubectl get pods -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} 2>/dev/null | grep -c "openwebui" || echo "0")
    if [ "$POD_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}⚠ WARNING: Multiple pods found (${POD_COUNT})${NC}"
        kubectl get pods -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE}
        echo "   This may indicate multiple deployments or stuck pods"
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    elif [ "$POD_COUNT" -eq 1 ]; then
        POD_STATUS=$(kubectl get pods -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
        POD_READY=$(kubectl get pods -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
        if [ "$POD_READY" = "true" ]; then
            echo -e "${GREEN}✓ Single pod found and ready${NC}"
        else
            echo -e "${YELLOW}⚠ Pod found but not ready (Status: ${POD_STATUS})${NC}"
            CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
        fi
    else
        echo -e "${YELLOW}⚠ No pods found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (cluster not connected)${NC}"
fi
echo ""

# 5. Check for multiple services
echo "5. Checking for duplicate services..."
if kubectl cluster-info &>/dev/null; then
    SVC_COUNT=$(kubectl get svc -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} 2>/dev/null | grep -c "openwebui" || echo "0")
    if [ "$SVC_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}⚠ WARNING: Multiple services found${NC}"
        kubectl get svc -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE}
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    elif [ "$SVC_COUNT" -eq 1 ]; then
        echo -e "${GREEN}✓ Single service found${NC}"
    else
        echo -e "${YELLOW}⚠ No service found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (cluster not connected)${NC}"
fi
echo ""

# 6. Check for multiple PVCs
echo "6. Checking for duplicate PVCs..."
if kubectl cluster-info &>/dev/null; then
    PVC_COUNT=$(kubectl get pvc -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} 2>/dev/null | grep -c "openwebui" || echo "0")
    if [ "$PVC_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}⚠ WARNING: Multiple PVCs found${NC}"
        kubectl get pvc -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE}
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    elif [ "$PVC_COUNT" -eq 1 ]; then
        PVC_STATUS=$(kubectl get pvc -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
        if [ "$PVC_STATUS" = "Bound" ]; then
            echo -e "${GREEN}✓ Single PVC found and bound${NC}"
        else
            echo -e "${YELLOW}⚠ PVC found but not bound (Status: ${PVC_STATUS})${NC}"
            CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
        fi
    else
        echo -e "${YELLOW}⚠ No PVC found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (cluster not connected)${NC}"
fi
echo ""

# 7. Check for k3d proxy port conflicts
echo "7. Checking k3d proxy port mappings..."
if docker ps &>/dev/null; then
    K3D_PROXY=$(docker ps --filter "name=k3d.*serverlb" --filter "publish=${PORT}" --format "{{.Names}}" 2>/dev/null | head -1)
    if [ -n "$K3D_PROXY" ]; then
        echo -e "${YELLOW}⚠ WARNING: k3d proxy is mapping port ${PORT}${NC}"
        echo "   Proxy container: ${K3D_PROXY}"
        echo "   This may conflict with port forwarding"
        echo "   Check with: docker ps --filter 'publish=${PORT}'"
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    else
        echo -e "${GREEN}✓ No k3d proxy conflict on port ${PORT}${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (Docker not running)${NC}"
fi
echo ""

# 8. Check for multiple ReplicaSets
echo "8. Checking for multiple ReplicaSets..."
if kubectl cluster-info &>/dev/null; then
    RS_COUNT=$(kubectl get replicasets -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} 2>/dev/null | grep -c "openwebui" || echo "0")
    if [ "$RS_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}⚠ WARNING: Multiple ReplicaSets found (${RS_COUNT})${NC}"
        kubectl get replicasets -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE}
        echo "   This may indicate incomplete upgrades or stuck deployments"
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    elif [ "$RS_COUNT" -eq 1 ]; then
        RS_REPLICAS=$(kubectl get replicasets -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} -o jsonpath='{.items[0].status.replicas}' 2>/dev/null || echo "0")
        RS_READY=$(kubectl get replicasets -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} -o jsonpath='{.items[0].status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$RS_REPLICAS" = "$RS_READY" ] && [ "$RS_REPLICAS" -gt 0 ]; then
            echo -e "${GREEN}✓ Single ReplicaSet with ${RS_READY}/${RS_REPLICAS} ready${NC}"
        else
            echo -e "${YELLOW}⚠ ReplicaSet not fully ready (${RS_READY}/${RS_REPLICAS})${NC}"
            CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
        fi
    else
        echo -e "${YELLOW}⚠ No ReplicaSet found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (cluster not connected)${NC}"
fi
echo ""

# 9. Check for ingress conflicts
echo "9. Checking for ingress conflicts..."
if kubectl cluster-info &>/dev/null; then
    INGRESS_COUNT=$(kubectl get ingress -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE} 2>/dev/null | grep -c "openwebui" || echo "0")
    if [ "$INGRESS_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}⚠ WARNING: Multiple ingress resources found${NC}"
        kubectl get ingress -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=${RELEASE_NAME}" -n ${NAMESPACE}
        CONFLICTS_FOUND=$((CONFLICTS_FOUND + 1))
    elif [ "$INGRESS_COUNT" -eq 1 ]; then
        echo -e "${GREEN}✓ Single ingress found${NC}"
    else
        echo -e "${GREEN}✓ No ingress (using port-forward)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot check (cluster not connected)${NC}"
fi
echo ""

# Summary
echo "========================================="
if [ "$CONFLICTS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✓ No conflicts detected!${NC}"
    exit 0
else
    echo -e "${RED}❌ Found ${CONFLICTS_FOUND} potential conflict(s)${NC}"
    echo ""
    echo "Recommended actions:"
    echo "1. If port conflicts: kill \$(lsof -ti:${PORT})"
    echo "2. If multiple pods: kubectl delete pod <old-pod-name>"
    echo "3. If multiple ReplicaSets: kubectl scale rs <old-rs> --replicas=0"
    echo "4. If cluster not connected: Start Docker and ensure k3d cluster is running"
    exit 1
fi

