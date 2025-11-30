# Open WebUI Wrapper Helm Chart

A wrapper Helm chart for deploying Open WebUI on Kubernetes using Helm.

## Description

This chart wraps the Open WebUI application as a subchart, providing a clean way to deploy and manage Open WebUI in Kubernetes clusters.

**Default Configuration:**
- Llama 3 is configured as the default model (`DEFAULT_MODEL=llama3`)
- User agent is set to identify requests
- Persistence is enabled by default (10Gi)
- Ready to use out of the box with sensible defaults

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- k3d or other Kubernetes cluster

## Installation

### Install from local chart

```bash
helm install openwebui ./chart
```

### Install with custom values

```bash
helm install openwebui ./chart -f my-values.yaml
```

## Configuration

The following table lists the configurable parameters for the Open WebUI subchart:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `open-webui.enabled` | Enable the Open WebUI subchart | `true` |
| `open-webui.image.repository` | Open WebUI image repository | `ghcr.io/open-webui/open-webui` |
| `open-webui.image.tag` | Open WebUI image tag | `latest` |
| `open-webui.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `open-webui.service.type` | Service type | `ClusterIP` |
| `open-webui.service.port` | Service port | `8080` |
| `open-webui.ingress.enabled` | Enable ingress | `false` |
| `open-webui.ingress.className` | Ingress class name | `""` |
| `open-webui.ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `open-webui.persistence.enabled` | Enable persistence | `true` |
| `open-webui.persistence.size` | Persistent volume size | `10Gi` |
| `open-webui.persistence.storageClass` | Storage class | `""` |
| `open-webui.resources.limits` | Resource limits | `cpu: 1000m, memory: 2Gi` |
| `open-webui.resources.requests` | Resource requests | `cpu: 500m, memory: 1Gi` |
| `open-webui.replicaCount` | Number of replicas | `1` |
| `open-webui.env` | Environment variables | See values.yaml (includes DEFAULT_MODEL=llama3, USER_AGENT) |

## Examples

### Basic installation

```bash
helm install openwebui ./chart
```

### With ingress enabled

```bash
helm install openwebui ./chart \
  --set open-webui.ingress.enabled=true \
  --set open-webui.ingress.className=nginx \
  --set open-webui.ingress.hosts[0].host=openwebui.example.com
```

### With custom resources

```bash
helm install openwebui ./chart \
  --set open-webui.resources.limits.cpu=2000m \
  --set open-webui.resources.limits.memory=4Gi
```

### With persistence disabled

```bash
helm install openwebui ./chart \
  --set open-webui.persistence.enabled=false
```

## Default Configuration

The chart comes pre-configured with sensible defaults:

- **Default Model**: Llama 3 (`DEFAULT_MODEL=llama3`)
- **User Agent**: Set to `Open-WebUI/0.6.40` to identify requests
- **Persistence**: Enabled with 10Gi storage
- **Resources**: 500m CPU / 1Gi memory requests, 1000m CPU / 2Gi memory limits
- **Service**: ClusterIP on port 8080

**Note**: Make sure you have Ollama running with the Llama 3 model available for the default model to work. You can configure the Ollama connection by setting the `OLLAMA_BASE_URL` environment variable.

## Accessing Open WebUI

After installation, access Open WebUI using one of the following methods:

### Port Forwarding (ClusterIP)

```bash
kubectl port-forward svc/RELEASE-NAME-open-webui 8080:8080
```

Then open http://localhost:8080 in your browser.

### NodePort

If using NodePort service type, get the node port:

```bash
kubectl get svc RELEASE-NAME-open-webui
```

### Ingress

If ingress is enabled, access via the configured hostname.

## Uninstallation

```bash
helm uninstall openwebui
```

## Chart Structure

```
chart/
├── Chart.yaml              # Wrapper chart metadata
├── values.yaml             # Default values for wrapper and subchart
├── templates/
│   ├── _helpers.tpl        # Template helpers
│   └── NOTES.txt           # Installation notes
└── charts/
    └── open-webui/         # Open WebUI subchart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── ingress.yaml
            ├── pvc.yaml
            └── ...
```

## License

[Add your license here]


