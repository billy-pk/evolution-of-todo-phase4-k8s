# AI Todo Frontend Helm Chart

Helm chart for deploying the AI Todo Next.js frontend application with ChatKit to Kubernetes.

## Prerequisites

- Kubernetes cluster (Minikube or production cluster)
- Helm 3.x installed
- Docker image `ai-todo-frontend:latest` built and loaded into cluster
- PostgreSQL database (for Better Auth)
- Backend service deployed (`ai-todo-backend-service`)

## Installation

### Quick Start (Minikube)

```bash
# Get Minikube IP first
MINIKUBE_IP=$(minikube ip)

# Install with required environment variables
helm install ai-todo-frontend ./charts/ai-todo-frontend \
  --set env.NEXT_PUBLIC_API_URL="http://${MINIKUBE_IP}:30081" \
  --set env.BETTER_AUTH_SECRET="your-shared-secret" \
  --set env.DATABASE_URL="postgresql://user:password@host/dbname"
```

### Using a Values File

Create a custom values file `my-values.yaml`:

```yaml
env:
  NEXT_PUBLIC_API_URL: "http://192.168.49.2:30081"
  BETTER_AUTH_SECRET: "your-shared-secret"
  DATABASE_URL: "postgresql://user:password@host/dbname"
```

Then install:

```bash
helm install ai-todo-frontend ./charts/ai-todo-frontend -f my-values.yaml
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of frontend pods | `1` |
| `image.repository` | Frontend Docker image repository | `ai-todo-frontend` |
| `image.tag` | Frontend Docker image tag | `latest` |
| `service.type` | Kubernetes service type | `NodePort` |
| `service.port` | Frontend service port | `3000` |
| `service.nodePort` | NodePort for external access | `30080` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `env.NEXT_PUBLIC_API_URL` | Backend API URL | `http://192.168.49.2:30081` |
| `env.BETTER_AUTH_SECRET` | Shared secret for JWT generation | `""` (required) |
| `env.BETTER_AUTH_URL` | Better Auth base URL | `http://localhost:30080` |
| `env.DATABASE_URL` | PostgreSQL connection string | `""` (required) |

### Full values.yaml

See `values.yaml` for all configurable parameters.

## Upgrading

```bash
# Upgrade with new image tag
helm upgrade ai-todo-frontend ./charts/ai-todo-frontend --set image.tag=v1.1.0

# Upgrade with new values file
helm upgrade ai-todo-frontend ./charts/ai-todo-frontend -f my-values.yaml
```

## Rollback

```bash
# List release history
helm history ai-todo-frontend

# Rollback to previous version
helm rollback ai-todo-frontend

# Rollback to specific revision
helm rollback ai-todo-frontend 2
```

## Uninstallation

```bash
helm uninstall ai-todo-frontend
```

## Accessing the Service

### NodePort (Minikube)

```bash
# Get Minikube IP
minikube ip

# Access frontend in browser
open http://$(minikube ip):30080
```

### Port Forwarding

```bash
kubectl port-forward svc/ai-todo-frontend-service 3000:3000
# Access at http://localhost:3000
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app=ai-todo-frontend
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Service

```bash
kubectl get svc ai-todo-frontend-service
kubectl describe svc ai-todo-frontend-service
```

### Check ConfigMap and Secrets

```bash
kubectl get configmap ai-todo-frontend-config -o yaml
kubectl get secret ai-todo-frontend-secrets -o yaml
```

### Common Issues

**Pod not starting:**
- Check environment variables are set correctly
- Verify DATABASE_URL is accessible from cluster
- Check logs: `kubectl logs <pod-name>`

**Frontend can't connect to backend:**
- Verify `NEXT_PUBLIC_API_URL` matches Minikube IP and backend NodePort
- Check backend service is running: `kubectl get svc ai-todo-backend-service`
- Test backend health: `curl http://$(minikube ip):30081/health`

**Authentication not working:**
- Verify `BETTER_AUTH_SECRET` matches backend configuration
- Check DATABASE_URL is correct for Better Auth
- Review frontend logs for auth errors

**Service not accessible:**
- Verify Minikube IP: `minikube ip`
- Check service type and nodePort: `kubectl get svc`
- Use port forwarding as alternative

## Dependencies

This chart depends on:
- External PostgreSQL database (Neon or other)
- Backend service (must be deployed first): `ai-todo-backend-service:8000`

## Environment Variables

### NEXT_PUBLIC_API_URL

This must point to the backend API accessible from the user's browser. For Minikube:

```bash
# Get Minikube IP dynamically
MINIKUBE_IP=$(minikube ip)
echo "http://${MINIKUBE_IP}:30081"
```

### BETTER_AUTH_SECRET

Shared secret between frontend and backend for JWT signing/validation. Must be the same value in both services.

### DATABASE_URL

PostgreSQL connection string for Better Auth session storage. Should be the same database as the backend.

## Version History

- **1.0.0**: Initial release with Next.js 16, Better Auth, and ChatKit integration
