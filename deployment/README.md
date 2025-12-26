# Kubernetes Deployment Guide

**Project**: AI Todo Application - Phase 4
**Target**: Local Kubernetes cluster via Minikube
**Version**: 1.0.0

## Overview

This guide provides instructions for deploying the AI Todo application (FastAPI backend, MCP Server, Next.js frontend) to a local Kubernetes cluster using Minikube and Helm charts.

## Prerequisites

Before deploying, ensure you have the following installed:

- **Minikube** >= 1.32 (`minikube version`)
- **kubectl** CLI tool (`kubectl version --client`)
- **Helm** >= 3.x (`helm version`)
- **Docker** (`docker --version`)
- **Phase 3 AI Todo** application working locally
- **Database credentials** for Neon PostgreSQL
- **OpenAI API key**

## Quick Start

### 1. Initialize Minikube Cluster

```bash
# Run the setup script
./deployment/minikube-setup.sh

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### 2. Build Docker Images

```bash
# Build all images (backend, MCP, frontend)
./deployment/build-images.sh

# Verify images built successfully
docker images | grep ai-todo
```

### 3. Load Images into Minikube

```bash
# Load images into Minikube's internal registry
./deployment/load-images.sh

# Verify images loaded
minikube image ls | grep ai-todo
```

### 4. Deploy to Kubernetes

```bash
# Set your environment variables
export DATABASE_URL="postgresql://user:password@neon-host/dbname"
export OPENAI_API_KEY="sk-..."
export BETTER_AUTH_SECRET="your-shared-secret"

# Deploy all services
./deployment/deploy.sh
```

### 5. Verify Deployment

```bash
# Check deployment status
./deployment/validate.sh

# Get Minikube IP
minikube ip

# Access services
echo "Frontend: http://$(minikube ip):30080"
echo "Backend: http://$(minikube ip):30081"
```

## Deployment Scripts

### minikube-setup.sh
Initializes Minikube cluster with required resources and addons.

### build-images.sh
Builds Docker images for backend, MCP Server, and frontend.

### load-images.sh
Loads Docker images into Minikube's internal registry.

### deploy.sh
Deploys all Helm charts to Kubernetes cluster.

### validate.sh
Validates deployment status and runs health checks.

## Service Architecture

```
┌─────────────────────────────────────────────┐
│          Minikube Cluster                   │
│                                             │
│  ┌──────────────┐  ┌──────────────┐        │
│  │   Frontend   │  │   Backend    │        │
│  │ (NodePort)   │  │ (NodePort)   │        │
│  │   :30080     │  │   :30081     │        │
│  └──────────────┘  └──────┬───────┘        │
│                           │                 │
│                    ┌──────▼───────┐         │
│                    │  MCP Server  │         │
│                    │ (ClusterIP)  │         │
│                    │    :8001     │         │
│                    └──────────────┘         │
│                                             │
└─────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
  External Access      Neon PostgreSQL
  (NodePort)           (External)
```

## Accessing the Application

### Method 1: NodePort (Recommended for Minikube)

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Access frontend
open http://$MINIKUBE_IP:30080

# Test backend health
curl http://$MINIKUBE_IP:30081/health
```

### Method 2: Port Forwarding

```bash
# Forward backend port
kubectl port-forward svc/ai-todo-backend-service 8000:8000

# Forward frontend port (in another terminal)
kubectl port-forward svc/ai-todo-frontend-service 3000:3000

# Access locally
open http://localhost:3000
curl http://localhost:8000/health
```

### Method 3: Minikube Service

```bash
# Open service in browser
minikube service ai-todo-frontend-service
minikube service ai-todo-backend-service
```

## Common Operations

### Update Configuration

```bash
# Upgrade with new environment variable
helm upgrade ai-todo-backend ./charts/ai-todo-backend \
  --set env.LOG_LEVEL="debug"
```

### Scale Services

```bash
# Scale backend to 2 replicas
helm upgrade ai-todo-backend ./charts/ai-todo-backend \
  --set replicaCount=2

# Verify scaling
kubectl get pods -l app=ai-todo-backend
```

### Restart Services

```bash
# Delete pod (Kubernetes will recreate it)
kubectl delete pod -l app=ai-todo-backend

# Watch pods restart
kubectl get pods --watch
```

### View Logs

```bash
# Follow logs for a service
kubectl logs -f <pod-name>

# View logs from all replicas
kubectl logs -l app=ai-todo-backend --all-containers=true

# View previous crashed pod logs
kubectl logs <pod-name> --previous
```

### Rollback Deployment

```bash
# View release history
helm history ai-todo-backend

# Rollback to previous revision
helm rollback ai-todo-backend

# Rollback to specific revision
helm rollback ai-todo-backend 2
```

## Troubleshooting

### Pods Stuck in Pending

**Symptom**: `kubectl get pods` shows pods in `Pending` state

**Causes**:
- Insufficient Minikube resources
- Images not loaded into Minikube

**Solutions**:
```bash
# Check pod events
kubectl describe pod <pod-name>

# Increase Minikube resources
minikube delete
minikube start --cpus=4 --memory=8192

# Verify images loaded
minikube image ls | grep ai-todo
```

### Pods Stuck in ImagePullBackOff

**Symptom**: `kubectl get pods` shows `ImagePullBackOff` or `ErrImagePull`

**Causes**:
- Images not loaded into Minikube registry
- Wrong image name in Helm values

**Solutions**:
```bash
# Re-load images
./deployment/load-images.sh

# Verify image names match
kubectl describe pod <pod-name> | grep Image
```

### Pods in CrashLoopBackOff

**Symptom**: Pods continuously restart

**Causes**:
- Missing environment variables
- Database connection failure
- Application startup errors

**Solutions**:
```bash
# Check logs
kubectl logs <pod-name>

# Check environment variables
kubectl exec <pod-name> -- env | grep DATABASE_URL

# Verify database connectivity
kubectl exec <pod-name> -- ping <database-host>
```

### Service Not Accessible

**Symptom**: Cannot access service via NodePort

**Causes**:
- Pods not ready
- Service endpoints not populated
- Firewall blocking ports

**Solutions**:
```bash
# Check service endpoints
kubectl get endpoints

# Verify pods are ready
kubectl get pods

# Check service configuration
kubectl describe svc ai-todo-backend-service

# Test from inside cluster
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Then: wget -O- http://ai-todo-backend-service:8000/health
```

## Cleanup

### Uninstall Services

```bash
# Uninstall all Helm releases
helm uninstall ai-todo-backend
helm uninstall ai-todo-mcp
helm uninstall ai-todo-frontend

# Verify cleanup
helm list
kubectl get pods
```

### Delete Minikube Cluster

```bash
# Stop cluster
minikube stop

# Delete cluster (removes all data)
minikube delete

# Remove Docker images (optional)
docker rmi ai-todo-backend:latest
docker rmi ai-todo-mcp:latest
docker rmi ai-todo-frontend:latest
```

## Development Workflow

### Making Code Changes

```bash
# 1. Update code in backend/frontend/tools

# 2. Rebuild affected image
docker build -t ai-todo-backend:latest -f dockerfiles/backend.Dockerfile ./backend

# 3. Reload into Minikube
minikube image load ai-todo-backend:latest

# 4. Restart pods (fast method)
kubectl delete pod -l app=ai-todo-backend

# OR: Helm upgrade (safer, supports rolling updates)
helm upgrade ai-todo-backend ./charts/ai-todo-backend
```

### Testing Statelessness

```bash
# 1. Create conversation via chat UI

# 2. Delete backend pod
kubectl delete pod -l app=ai-todo-backend

# 3. Wait for new pod
kubectl get pods --watch

# 4. Verify conversation still accessible
# (Should reload from database without data loss)
```

## Performance Monitoring

```bash
# View resource usage
kubectl top pods
kubectl top nodes

# Minikube dashboard (GUI)
minikube dashboard

# Check pod resource limits
kubectl describe pod <pod-name> | grep -A 5 Limits
```

## Architecture Diagram

(Diagram will be added in Polish phase)

## Next Steps

- Refer to [../specs/004-kubernetes-deployment/quickstart.md](../specs/004-kubernetes-deployment/quickstart.md) for detailed test scenarios
- Review individual Helm chart READMEs in `charts/*/README.md`
- Check [../specs/004-kubernetes-deployment/data-model.md](../specs/004-kubernetes-deployment/data-model.md) for infrastructure entities

## Support

For issues or questions:
- Check `kubectl describe pod <pod-name>` for detailed error information
- Review logs with `kubectl logs <pod-name>`
- Verify Helm chart syntax with `helm lint ./charts/<chart-name>`
- Check Minikube status with `minikube status` and `minikube logs`
