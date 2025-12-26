# AI Todo MCP Server Helm Chart

This Helm chart deploys the AI Todo MCP (Model Context Protocol) Server to Kubernetes.

## Prerequisites

- Kubernetes cluster (Minikube or production)
- Helm 3.x
- Docker image: `ai-todo-mcp:latest`

## Installation

### Install with default values

```bash
helm install ai-todo-mcp ./charts/ai-todo-mcp
```

### Install with custom database URL

```bash
helm install ai-todo-mcp ./charts/ai-todo-mcp \
  --set env.DATABASE_URL="postgresql://user:pass@host:5432/db"
```

### Upgrade existing release

```bash
helm upgrade ai-todo-mcp ./charts/ai-todo-mcp \
  --set env.DATABASE_URL="postgresql://user:pass@host:5432/db"
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of MCP server replicas | `1` |
| `image.repository` | Image repository | `ai-todo-mcp` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8001` |
| `resources.limits.cpu` | CPU limit | `250m` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `resources.requests.cpu` | CPU request | `125m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `env.DATABASE_URL` | PostgreSQL connection string | `""` |

## Uninstall

```bash
helm uninstall ai-todo-mcp
```

## Troubleshooting

### Check pod status

```bash
kubectl get pods -l app=ai-todo-mcp
```

### View logs

```bash
kubectl logs -l app=ai-todo-mcp --tail=100
```

### Check service

```bash
kubectl get svc ai-todo-mcp-service
```

### Test internal connectivity

```bash
kubectl run test-curl --rm -it --image=curlimages/curl -- \
  curl http://ai-todo-mcp-service:8001/
```
