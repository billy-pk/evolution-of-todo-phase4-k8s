# AI Todo Backend Helm Chart

Helm chart for deploying the AI Todo FastAPI backend service with MCP integration to Kubernetes.

## Prerequisites

- Kubernetes cluster (Minikube or production cluster)
- Helm 3.x installed
- Docker image `ai-todo-backend:latest` built and loaded into cluster
- PostgreSQL database (external, e.g., Neon)
- OpenAI API key

## Installation

### Quick Start (Minikube)

```bash
# Install with required environment variables
helm install ai-todo-backend ./charts/ai-todo-backend \
  --set env.DATABASE_URL="postgresql://user:password@host/dbname" \
  --set env.OPENAI_API_KEY="sk-your-api-key" \
  --set env.BETTER_AUTH_SECRET="your-shared-secret"
```

### Using a Values File

Create a custom values file `my-values.yaml`:

```yaml
env:
  DATABASE_URL: "postgresql://user:password@host/dbname"
  OPENAI_API_KEY: "sk-your-api-key"
  BETTER_AUTH_SECRET: "your-shared-secret"
```

Then install:

```bash
helm install ai-todo-backend ./charts/ai-todo-backend -f my-values.yaml
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of backend pods | `1` |
| `image.repository` | Backend Docker image repository | `ai-todo-backend` |
| `image.tag` | Backend Docker image tag | `latest` |
| `service.type` | Kubernetes service type | `NodePort` |
| `service.port` | Backend service port | `8000` |
| `service.nodePort` | NodePort for external access | `30081` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `env.DATABASE_URL` | PostgreSQL connection string | `""` (required) |
| `env.OPENAI_API_KEY` | OpenAI API key | `""` (required) |
| `env.BETTER_AUTH_SECRET` | Shared secret for JWT validation | `""` (required) |
| `env.MCP_SERVER_URL` | MCP Server endpoint | `http://ai-todo-mcp-service:8001` |

### Full values.yaml

See `values.yaml` for all configurable parameters.

## Upgrading

```bash
# Upgrade with new image tag
helm upgrade ai-todo-backend ./charts/ai-todo-backend --set image.tag=v1.1.0

# Upgrade with new values file
helm upgrade ai-todo-backend ./charts/ai-todo-backend -f my-values.yaml
```

## Rollback

```bash
# List release history
helm history ai-todo-backend

# Rollback to previous version
helm rollback ai-todo-backend

# Rollback to specific revision
helm rollback ai-todo-backend 2
```

## Uninstallation

```bash
helm uninstall ai-todo-backend
```

## Health Checks

The backend includes liveness and readiness probes:

- **Liveness**: `GET /health` - Returns 200 if app is running
- **Readiness**: `GET /ready` - Returns 200 if database is connected

## Accessing the Service

### NodePort (Minikube)

```bash
# Get Minikube IP
minikube ip

# Access backend
curl http://$(minikube ip):30081/health
```

### Port Forwarding

```bash
kubectl port-forward svc/ai-todo-backend-service 8000:8000
curl http://localhost:8000/health
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app=ai-todo-backend
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Service

```bash
kubectl get svc ai-todo-backend-service
kubectl describe svc ai-todo-backend-service
```

### Check ConfigMap and Secrets

```bash
kubectl get configmap ai-todo-backend-config -o yaml
kubectl get secret ai-todo-backend-secrets -o yaml
```

### Common Issues

**Pod not starting:**
- Check environment variables are set correctly
- Verify DATABASE_URL is accessible from cluster
- Check logs: `kubectl logs <pod-name>`

**Readiness probe failing:**
- Database connection issue
- Check DATABASE_URL format and credentials
- Verify network connectivity to PostgreSQL

**Service not accessible:**
- Verify Minikube IP: `minikube ip`
- Check service type and nodePort: `kubectl get svc`
- Use port forwarding as alternative

## Dependencies

This chart depends on:
- External PostgreSQL database (Neon or other)
- MCP Server service (deployed separately): `ai-todo-mcp-service:8001`
- Frontend service (for Better Auth JWKS): `ai-todo-frontend-service:3000`

## Version History

- **1.0.0**: Initial release with FastAPI backend, health checks, and MCP integration
