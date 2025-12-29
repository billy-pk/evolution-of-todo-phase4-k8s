# Kubernetes Full-Stack Deployment

Deploy and troubleshoot Next.js + FastAPI + MCP application on Minikube with Better Auth JWT validation.

## When to Use

- Deploying multi-service applications (frontend/backend/MCP) to Kubernetes
- Setting up JWT authentication with JWKS between services
- Configuring port-forwards for WSL2/Windows development
- Troubleshooting 401/421 errors in Kubernetes service mesh
- Hot-reloading code changes in Minikube

## Prerequisites

- Minikube running with Docker driver
- kubectl configured
- Helm 3.x installed
- Docker images built locally

## Quick Start

### 1. Initial Deployment

```bash
# Set environment variables
export DATABASE_URL='postgresql://user:pass@host/db?sslmode=require'
export BETTER_AUTH_SECRET='your-secret-key'
export OPENAI_API_KEY='sk-...'

# Deploy all services
./deployment/deploy.sh
```

### 2. Port-Forward for Development (WSL2/Windows)

```bash
# Must use --address 0.0.0.0 for Windows browser access
kubectl port-forward --address 0.0.0.0 svc/ai-todo-frontend-service 3000:3000 &
kubectl port-forward --address 0.0.0.0 svc/ai-todo-backend-service 8000:8000 &

# Access from Windows browser: http://localhost:3000
```

### 3. Update Code and Reload

```bash
# Rebuild images
./deployment/build-images.sh

# Load into Minikube
minikube image load ai-todo-mcp:latest --overwrite

# Restart pods
kubectl delete pod -l app=ai-todo-mcp
```

## Critical Configuration

### Backend ConfigMap (BETTER_AUTH_URL)

Backend MUST know where to fetch JWKS:

```bash
kubectl create configmap ai-todo-backend-config \
  --from-literal=BETTER_AUTH_URL='http://ai-todo-frontend-service:3000' \
  --from-literal=MCP_SERVER_URL='http://ai-todo-mcp-service:8001'
```

### MCP Allowed Hosts

MCP server must trust Kubernetes DNS:

```python
allowed_hosts_list = [
    "localhost:*",
    "ai-todo-mcp-service:*",  # Critical for K8s
]
```

## Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | JWKS fetch fails | Set `BETTER_AUTH_URL` in backend ConfigMap |
| 421 Misdirected Request | MCP rejects hostname | Add `ai-todo-mcp-service:*` to allowed_hosts |
| Connection refused (3000) | Port-forward stopped | Restart with `--address 0.0.0.0` |
| Database timeout | Old connections | Restart frontend pod |

See [troubleshooting.md](./troubleshooting.md) for detailed solutions.

## Architecture

```
Browser (Windows)
    ↓
localhost:3000 (port-forward)
    ↓
Frontend Pod → Backend Pod → MCP Pod
                    ↓
            Neon PostgreSQL (external)
```

## Deployment Options

- **Local Development:** Minikube (see above)
- **Cloud Production:** Oracle Cloud Always Free tier (see [cloud-deployment.md](./cloud-deployment.md))

## Files

- `SKILL.md` - This file (quick reference)
- `reference.md` - Detailed commands and configurations
- `troubleshooting.md` - Issue diagnosis and solutions
- `workflow.md` - Step-by-step deployment procedures
- `cloud-deployment.md` - Oracle Cloud deployment guide (Always Free tier)
