# Open WebUI Helm Chart for k3d

A complete Helm chart setup for deploying Open WebUI on k3d (Kubernetes) with Ollama bundled, optimized for Mac development.

## Features

- **Open WebUI** with Ollama bundled (using `ollama` image tag)
- **Llama 3** configured as the default model
- **k3d cluster configuration** optimized for Mac
- **Local-path storage** for persistent data
- **Port-forwarding scripts** for easy access
- **Taskfile** for common operations
- **Conflict detection** tools

## Prerequisites

- macOS (tested on Mac)
- Docker Desktop or Docker installed
- k3d installed: `brew install k3d`
- kubectl installed
- Helm 3.0+ installed

## Quick Start

### 1. Create k3d Cluster

```bash
task k3d:create
```

Or manually:
```bash
k3d cluster create --config k3d-config.yaml \
  --k3s-arg "--disable=traefik@server:0" \
  --k3s-arg "--write-kubeconfig-mode=644@server:0" \
  --k3s-arg "--tls-san=localhost@server:0" \
  --k3s-arg "--tls-san=127.0.0.1@server:0" \
  --k3s-arg "--tls-san=k3d-openwebui-server-0@server:0"
```

### 2. Deploy Open WebUI

```bash
task deploy
```

### 3. Access Open WebUI

```bash
task port-forward
```

Then open http://localhost:8080 in your browser.

## Configuration

### Default Model

Llama 3 is configured as the default model via the `DEFAULT_MODEL` environment variable. On first use, you'll need to pull the model through the Open WebUI interface:

1. Go to **Settings** → **Admin Settings** → **Models**
2. Enter `llama3` and click pull
3. The model will be available for use

### Image Configuration

The chart uses the `ollama` image tag which includes Ollama bundled:
- Image: `ghcr.io/open-webui/open-webui:ollama`
- Ollama runs inside the same container

### Storage

- Uses `local-path` storage class (k3d default)
- 10Gi persistent volume
- Data stored at `~/.k3d/openwebui-storage` on the host

## Available Tasks

Use `task` command for common operations:

```bash
# Cluster management
task k3d:create      # Create k3d cluster
task k3d:delete      # Delete k3d cluster
task k3d:list        # List k3d clusters

# Deployment
task deploy          # Full deployment workflow
task install         # Install Helm chart
task upgrade         # Upgrade Helm chart
task uninstall       # Uninstall Helm chart

# Access
task port-forward    # Port forward to service
task logs            # View pod logs
task status          # Check deployment status

# Development
task lint            # Lint Helm chart
task template        # Render templates (dry-run)
task conflicts       # Detect conflicts
```

## Project Structure

```
.
├── chart/                    # Helm chart
│   ├── Chart.yaml           # Wrapper chart
│   ├── values.yaml          # Default values
│   └── charts/
│       └── open-webui/      # Open WebUI subchart
├── k3d-config.yaml          # k3d cluster configuration
├── Taskfile.yml             # Task runner configuration
├── port-forward.sh          # Port forwarding script
├── detect-conflicts.sh      # Conflict detection script
└── README.md                # This file
```

## Mac-Specific Considerations

### Permissions

The configuration includes Mac-specific permission settings:
- `fsGroup: 1000` for volume access
- Volume mounted at `~/.k3d/openwebui-storage`
- Proper file permissions for local-path storage

### Resource Limits

Optimized for Mac development:
- CPU requests: 250m
- Memory requests: 512Mi
- CPU limits: 1000m
- Memory limits: 2Gi

## Troubleshooting

### Port Conflicts

Run the conflict detection script:
```bash
./detect-conflicts.sh
```

Or use:
```bash
task conflicts
```

### Pod Not Starting

Check pod status:
```bash
kubectl get pods -n openwebui
kubectl describe pod -n openwebui <pod-name>
kubectl logs -n openwebui <pod-name>
```

### Model Not Available

1. Ensure you're using the `ollama` image tag
2. Check that Ollama is running inside the container
3. Pull the model through the Open WebUI interface

## Uninstallation

```bash
task uninstall
task k3d:delete
```

## License

This project is provided as-is for development purposes.

