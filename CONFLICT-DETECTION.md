# Conflict Detection Guide

## Quick Check

Run the conflict detection script:

```bash
./detect-conflicts.sh
```

Or use the Taskfile:

```bash
task conflicts
```

## What It Checks

The script detects the following potential conflicts:

1. **Kubernetes Cluster Connection** - Verifies cluster is accessible
2. **Port 8080 Conflicts** - Checks if port is already in use
3. **Duplicate Helm Releases** - Multiple releases of the same chart
4. **Multiple Pods** - Duplicate or stuck pods
5. **Multiple Services** - Duplicate service definitions
6. **Multiple PVCs** - Duplicate persistent volume claims
7. **k3d Proxy Conflicts** - Port mapping conflicts with k3d
8. **Multiple ReplicaSets** - Incomplete upgrades or stuck deployments
9. **Ingress Conflicts** - Multiple ingress resources

## Common Conflicts and Solutions

### Port 8080 Already in Use

**Symptom:** Port forwarding fails or connection refused

**Solution:**
```bash
# Find what's using the port
lsof -i :8080

# Kill the process
kill $(lsof -ti:8080)
```

### Multiple Pods Running

**Symptom:** Multiple pods with same labels, some may be stuck

**Solution:**
```bash
# List all pods
kubectl get pods -l "app.kubernetes.io/name=open-webui"

# Delete old/stuck pods
kubectl delete pod <old-pod-name>
```

### Multiple ReplicaSets

**Symptom:** Old ReplicaSets still present after upgrade

**Solution:**
```bash
# List ReplicaSets
kubectl get replicasets -l "app.kubernetes.io/name=open-webui"

# Scale down old ReplicaSets
kubectl scale rs <old-rs-name> --replicas=0
```

### Cluster Not Connected

**Symptom:** All checks show "Cannot check (cluster not connected)"

**Solution:**
```bash
# Check Docker
docker ps

# Check k3d clusters
k3d cluster list

# If Docker is not running, start it
open -a Docker

# Wait for cluster to be ready
kubectl get nodes
```

### k3d Proxy Port Conflict

**Symptom:** Port 8080 mapped by k3d proxy interfering with port-forward

**Solution:**
```bash
# Check k3d proxy mappings
docker ps --filter "name=k3d.*serverlb" --filter "publish=8080"

# Option 1: Use a different port for port-forward
kubectl port-forward <pod> 8081:8080

# Option 2: Access via k3d proxy (if configured)
# Check k3d cluster port mappings
k3d cluster list
```

## Manual Conflict Resolution

If the script detects conflicts, follow these steps:

1. **Review the output** - Identify which conflicts were found
2. **Check resource status** - Use `kubectl get` commands to see current state
3. **Clean up duplicates** - Remove old/stuck resources
4. **Restart services** - Restart deployments if needed
5. **Re-run detection** - Verify conflicts are resolved

## Prevention

To avoid conflicts:

1. **Always uninstall before reinstalling:**
   ```bash
   helm uninstall openwebui
   ```

2. **Clean up before upgrades:**
   ```bash
   task conflicts  # Check for issues first
   task upgrade    # Then upgrade
   ```

3. **Use consistent release names:**
   - Don't install multiple releases with different names
   - Use the same release name across environments

4. **Monitor port usage:**
   - Check port availability before port-forwarding
   - Use different ports for multiple instances

