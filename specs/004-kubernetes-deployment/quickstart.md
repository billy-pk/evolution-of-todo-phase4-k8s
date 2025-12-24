# Quickstart: Kubernetes Deployment

**Feature**: 004-kubernetes-deployment
**Date**: 2025-12-24
**Target Audience**: Developers deploying to local Minikube

## Prerequisites

- Minikube installed (`minikube version` >= 1.32)
- kubectl installed (`kubectl version --client`)
- Helm installed (`helm version` >= 3.x)
- Docker installed (`docker --version`)
- Phase 3 AI Todo application working locally
- Database credentials (Neon PostgreSQL)
- OpenAI API key

## Quick Deploy (5 Steps)

### 1. Start Minikube

```bash
# Initialize Minikube cluster
minikube start --cpus=2 --memory=4096

# Enable metrics (optional)
minikube addons enable metrics-server

# Verify cluster
kubectl cluster-info
```

### 2. Build Docker Images

```bash
# Build all images
docker build -t ai-todo-backend:latest -f dockerfiles/backend.Dockerfile ./backend
docker build -t ai-todo-mcp:latest -f dockerfiles/mcp.Dockerfile ./backend
docker build -t ai-todo-frontend:latest -f dockerfiles/frontend.Dockerfile ./frontend

# Verify images
docker images | grep ai-todo
```

### 3. Load Images into Minikube

```bash
# Load images into Minikube's registry
minikube image load ai-todo-backend:latest
minikube image load ai-todo-mcp:latest
minikube image load ai-todo-frontend:latest

# Verify loaded images
minikube image ls | grep ai-todo
```

### 4. Deploy with Helm

```bash
# Set your environment variables
export DATABASE_URL="postgresql://user:password@neon-host/dbname"
export OPENAI_API_KEY="sk-..."
export BETTER_AUTH_SECRET="your-shared-secret"

# Deploy MCP Server (no external dependencies)
helm install ai-todo-mcp ./charts/ai-todo-mcp \
  --set env.DATABASE_URL="$DATABASE_URL"

# Deploy Backend
helm install ai-todo-backend ./charts/ai-todo-backend \
  --set env.DATABASE_URL="$DATABASE_URL" \
  --set env.OPENAI_API_KEY="$OPENAI_API_KEY" \
  --set env.BETTER_AUTH_SECRET="$BETTER_AUTH_SECRET"

# Deploy Frontend
helm install ai-todo-frontend ./charts/ai-todo-frontend \
  --set env.NEXT_PUBLIC_API_URL="http://$(minikube ip):30081" \
  --set env.BETTER_AUTH_SECRET="$BETTER_AUTH_SECRET" \
  --set env.DATABASE_URL="$DATABASE_URL"
```

### 5. Access the Application

```bash
# Get Minikube IP
minikube ip

# Access frontend in browser
echo "Frontend: http://$(minikube ip):30080"

# Test backend API
curl http://$(minikube ip):30081/health

# Alternative: Use port forwarding
kubectl port-forward svc/ai-todo-backend-service 8000:8000
kubectl port-forward svc/ai-todo-frontend-service 3000:3000
```

---

## Verify Deployment

```bash
# Check all pods are running
kubectl get pods

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# ai-todo-backend-xxxxx             1/1     Running   0          1m
# ai-todo-mcp-xxxxx                 1/1     Running   0          1m
# ai-todo-frontend-xxxxx            1/1     Running   0          1m

# Check services
kubectl get services

# View logs
kubectl logs -f <pod-name>
```

---

## Common Operations

### Update Configuration

```bash
# Upgrade with new environment variable
helm upgrade ai-todo-backend ./charts/ai-todo-backend \
  --set env.LOG_LEVEL="debug"
```

### Restart a Service

```bash
# Delete pod (Kubernetes will recreate it)
kubectl delete pod <pod-name>
```

### Scale Replicas

```bash
# Scale backend to 2 replicas
helm upgrade ai-todo-backend ./charts/ai-todo-backend \
  --set replicaCount=2
```

### View Logs

```bash
# Follow logs
kubectl logs -f <pod-name>

# View previous crashed pod logs
kubectl logs <pod-name> --previous
```

### Rollback Deployment

```bash
# View release history
helm history ai-todo-backend

# Rollback to previous revision
helm rollback ai-todo-backend
```

---

## Troubleshooting

### Pods stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name>

# Common causes:
# - Insufficient Minikube resources (increase cpus/memory)
# - Image not loaded into Minikube (run minikube image load)
```

### Pods stuck in ImagePullBackOff

```bash
# Verify image loaded
minikube image ls | grep ai-todo

# Re-load image
minikube image load ai-todo-backend:latest
```

### Pods CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name>

# Common causes:
# - Missing environment variables
# - Database connection failure
# - Application startup error
```

### Service not accessible

```bash
# Check service endpoints
kubectl get endpoints

# Verify pods are ready
kubectl get pods

# Check readiness probe
kubectl describe pod <pod-name>
```

---

## Cleanup

```bash
# Uninstall all releases
helm uninstall ai-todo-backend
helm uninstall ai-todo-mcp
helm uninstall ai-todo-frontend

# Delete Minikube cluster
minikube delete
```

---

## Development Workflow

### Make Code Changes

```bash
# 1. Update code in backend/frontend/tools

# 2. Rebuild image
docker build -t ai-todo-backend:latest -f dockerfiles/backend.Dockerfile ./backend

# 3. Reload into Minikube
minikube image load ai-todo-backend:latest

# 4. Restart pods
kubectl delete pod -l app=ai-todo-backend

# Or use Helm upgrade (slower but safer)
helm upgrade ai-todo-backend ./charts/ai-todo-backend
```

### Test Statelessness

```bash
# 1. Create a conversation via chat UI

# 2. Delete backend pod
kubectl delete pod -l app=ai-todo-backend

# 3. Wait for new pod
kubectl get pods --watch

# 4. Verify conversation still accessible
# (should reload from database)
```

---

## Performance Monitoring

```bash
# View resource usage
kubectl top pods

# View cluster resources
kubectl top nodes

# Minikube dashboard (GUI)
minikube dashboard
```

---

## Next Steps

- Run `/sp.tasks` to generate implementation tasks
- Review [data-model.md](./data-model.md) for infrastructure entities
- Review [contracts/](./contracts/) for detailed specifications
- Read [research.md](./research.md) for architectural decisions

---

## Support

- **Helm issues**: `helm lint ./charts/<chart-name>`
- **Kubernetes issues**: `kubectl describe pod <pod-name>`
- **Minikube issues**: `minikube logs`
- **Application logs**: `kubectl logs <pod-name>`
