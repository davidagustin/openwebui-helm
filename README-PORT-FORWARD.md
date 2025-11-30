# Port Forwarding Open WebUI

## Quick Start

Once your Kubernetes cluster is running and the pod is ready:

```bash
./port-forward.sh
```

Or use the Taskfile:

```bash
task port-forward
```

## Manual Port Forward

If the script doesn't work, you can manually set up port forwarding:

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -l "app.kubernetes.io/name=open-webui,app.kubernetes.io/instance=openwebui" -o jsonpath='{.items[0].metadata.name}')

# Port forward
kubectl port-forward $POD_NAME 8080:8080

# In another terminal, open browser
open http://localhost:8080
```

## Troubleshooting

1. **404 Error**: Make sure the pod is ready (1/1 Running)
   ```bash
   kubectl get pods -l "app.kubernetes.io/name=open-webui"
   ```

2. **Connection Refused**: Check if Docker is running
   ```bash
   docker ps
   ```

3. **Port Already in Use**: Kill existing port forwards
   ```bash
   kill $(lsof -ti:8080)
   ```

4. **Cluster Not Available**: Restart k3d cluster
   ```bash
   k3d cluster list
   # If needed, restart Docker Desktop
   ```
