# Research: Kubernetes Deployment with Minikube and Helm

**Feature**: 004-kubernetes-deployment
**Phase**: 0 (Research)
**Date**: 2025-12-24

## Overview

This document captures research findings for deploying the AI Todo application to Kubernetes using Minikube and Helm. The research focuses on Docker multi-stage builds, Helm chart best practices, Kubernetes resource configuration, and stateless application patterns.

## 1. Docker Multi-Stage Builds for Python and Node.js

### Decision: Use multi-stage builds for all images

**Rationale**:
- Reduces final image size by excluding build dependencies
- Separates build environment from runtime environment
- Improves security by minimizing attack surface
- Meets SC-006 requirement (< 500MB combined)

**Implementation Pattern**:

**Backend (FastAPI):**
```dockerfile
# Stage 1: Build dependencies
FROM python:3.13-slim as builder
WORKDIR /build
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen

# Stage 2: Runtime
FROM python:3.13-slim
WORKDIR /app
COPY --from=builder /build/.venv /app/.venv
COPY . /app
ENV PATH="/app/.venv/bin:$PATH"
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**MCP Server (Python):**
- Similar pattern to backend
- Separate image for independent scaling
- Expose port 8001

**Frontend (Next.js):**
```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine as deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Build
FROM node:20-alpine as builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Runtime
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
CMD ["npm", "start"]
```

**Alternatives Considered**:
- Single-stage builds: Rejected due to large image size (> 1GB)
- Alpine-based images throughout: Selected for slim variant to balance size and compatibility
- Distroless images: Deferred to Phase 5 (adds complexity for local debugging)

---

## 2. Helm Chart Organization and Best Practices

### Decision: Three independent Helm charts (backend, MCP, frontend)

**Rationale**:
- Each service can version and deploy independently
- Simplifies values files (no monolithic configuration)
- Aligns with Principle VI (Modularity)
- Enables selective upgrades (`helm upgrade ai-todo-backend` only)

**Helm Chart Structure (per service)**:
```
charts/ai-todo-backend/
├── Chart.yaml          # Chart metadata (name, version, appVersion)
├── values.yaml         # Default configuration values
├── README.md           # Deployment instructions
└── templates/
    ├── deployment.yaml # Pod template, replicas, resources
    ├── service.yaml    # ClusterIP or NodePort
    ├── configmap.yaml  # Non-sensitive config
    └── secret.yaml     # Sensitive config (optional, can use external secrets)
```

**values.yaml Template**:
```yaml
replicaCount: 1

image:
  repository: ai-todo-backend
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 8000
  nodePort: 30081

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

env:
  DATABASE_URL: ""  # Injected via --set or values file
  OPENAI_API_KEY: ""
  MCP_SERVER_URL: "http://ai-todo-mcp-service:8001"

livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
```

**Best Practices Applied**:
1. **Separate Helm charts per service**: Enables independent lifecycle management
2. **Parameterize via values.yaml**: No hard-coded config in templates
3. **Health checks**: Liveness (restart unhealthy pods) and readiness (remove from service until ready)
4. **Resource limits**: Prevent resource exhaustion (CPU, memory)
5. **Semantic versioning**: Chart version tracks infrastructure changes, appVersion tracks image version
6. **README.md**: Document installation, upgrade, and rollback procedures

**Alternatives Considered**:
- Umbrella chart with subcharts: Rejected (adds complexity for local dev)
- Kustomize instead of Helm: Rejected (Helm provides better parameterization and release management)

---

## 3. Kubernetes Resource Configuration

### Decision: Minimal Kubernetes resources (Deployment, Service, ConfigMap, Secret)

**Rationale**:
- Meets requirements with standard Kubernetes primitives
- No custom CRDs (Constraint from spec)
- Simple enough for local Minikube environment

**Resource Types Used**:

**Deployment**:
- Manages pod replicas
- Handles rolling updates
- Restarts failed pods automatically
- Configuration:
  - `replicas: 1` (default for Minikube)
  - `strategy.type: RollingUpdate`
  - `maxSurge: 1, maxUnavailable: 0` (zero-downtime updates)

**Service**:
- **Backend**: NodePort 30081 (external access for API)
- **MCP Server**: ClusterIP (internal-only, accessed by backend)
- **Frontend**: NodePort 30080 (external access for web UI)

**ConfigMap**:
- Non-sensitive configuration (API URLs, feature flags)
- Mounted as environment variables or volume files
- Example: `MCP_SERVER_URL=http://ai-todo-mcp-service:8001`

**Secret**:
- Sensitive configuration (DATABASE_URL, API keys)
- Base64-encoded in Kubernetes
- Injected as environment variables
- **Important**: Never commit secrets to Git; use `--set` or external secret management

**Health Probes**:
- **Liveness**: `/health` endpoint (is app alive?)
  - Failure → Kubernetes restarts pod
- **Readiness**: `/ready` endpoint (is app ready to serve traffic?)
  - Failure → Kubernetes removes pod from service endpoints

**Alternatives Considered**:
- StatefulSet: Not needed (app is stateless, no persistent identity required)
- DaemonSet: Not applicable (no need for pod-per-node pattern)
- PersistentVolume: Explicitly forbidden by stateless requirement

---

## 4. Stateless Application Patterns for Kubernetes

### Decision: Externalize all state to Neon PostgreSQL

**Rationale**:
- Enables horizontal scaling (add more replicas)
- Pod restarts don't lose data
- Simplifies disaster recovery
- Aligns with Principle II (Stateless Server Design)

**Statelessness Validation**:

1. **No local file storage**: All data in external database
2. **No in-memory sessions**: JWT tokens validate each request independently
3. **Configuration via environment**: No config files in container
4. **Conversation history in DB**: Reconstructed from database on every chat request

**Minikube-Specific Considerations**:

**Image Loading**:
```bash
# Build images locally
docker build -t ai-todo-backend:latest -f dockerfiles/backend.Dockerfile .

# Load into Minikube
minikube image load ai-todo-backend:latest
```

**NodePort Access**:
```bash
# Get Minikube IP
minikube ip  # e.g., 192.168.49.2

# Access services
curl http://192.168.49.2:30081/health  # Backend
curl http://192.168.49.2:30080          # Frontend
```

**Debugging**:
```bash
# View pods
kubectl get pods

# Check logs
kubectl logs <pod-name>

# Exec into pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forward (alternative to NodePort)
kubectl port-forward svc/ai-todo-backend 8000:8000
```

**Alternatives Considered**:
- PersistentVolume for state: Rejected (violates statelessness principle)
- In-cluster PostgreSQL: Rejected (external Neon database simplifies local dev)

---

## 5. Helm Deployment Workflow

### Decision: Script-based deployment with validation steps

**Deployment Scripts**:

**minikube-setup.sh**:
```bash
#!/bin/bash
# Initialize Minikube cluster
minikube start --cpus=2 --memory=4096
minikube addons enable metrics-server
```

**build-images.sh**:
```bash
#!/bin/bash
# Build all Docker images
docker build -t ai-todo-backend:latest -f dockerfiles/backend.Dockerfile ./backend
docker build -t ai-todo-mcp:latest -f dockerfiles/mcp.Dockerfile ./backend
docker build -t ai-todo-frontend:latest -f dockerfiles/frontend.Dockerfile ./frontend
```

**load-images.sh**:
```bash
#!/bin/bash
# Load images into Minikube
minikube image load ai-todo-backend:latest
minikube image load ai-todo-mcp:latest
minikube image load ai-todo-frontend:latest
```

**deploy.sh**:
```bash
#!/bin/bash
# Deploy via Helm
helm upgrade --install ai-todo-backend ./charts/ai-todo-backend \
  --set env.DATABASE_URL="$DATABASE_URL" \
  --set env.OPENAI_API_KEY="$OPENAI_API_KEY"

helm upgrade --install ai-todo-mcp ./charts/ai-todo-mcp

helm upgrade --install ai-todo-frontend ./charts/ai-todo-frontend
```

**validate.sh**:
```bash
#!/bin/bash
# Validate deployment
helm list
kubectl get pods
kubectl get services
helm lint ./charts/ai-todo-backend
helm lint ./charts/ai-todo-mcp
helm lint ./charts/ai-todo-frontend
```

**Alternatives Considered**:
- Manual `kubectl apply -f`: Rejected (Helm provides better release management)
- GitOps (ArgoCD, Flux): Deferred to Phase 5 (out of scope for local dev)

---

## 6. External Database Connection

### Decision: Neon PostgreSQL remains external (not deployed in Kubernetes)

**Rationale**:
- Simplifies local development (no database pod management)
- Neon already configured and working from Phase 3
- Database migration to K8s is explicitly out of scope (spec)

**Connection Pattern**:
```yaml
# In values.yaml (or via --set)
env:
  DATABASE_URL: "postgresql://user:password@neon-host/dbname"
```

**Secret Management**:
- Store `DATABASE_URL` in Kubernetes Secret (not ConfigMap)
- Inject as environment variable in pod
- Never commit database credentials to Git

---

## 7. Port Configuration and Service Discovery

### Decision: Internal ClusterIP for MCP, NodePort for Backend/Frontend

**Service Types**:

**Backend Service** (NodePort):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ai-todo-backend-service
spec:
  type: NodePort
  ports:
    - port: 8000
      targetPort: 8000
      nodePort: 30081
  selector:
    app: ai-todo-backend
```

**MCP Service** (ClusterIP):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ai-todo-mcp-service
spec:
  type: ClusterIP
  ports:
    - port: 8001
      targetPort: 8001
  selector:
    app: ai-todo-mcp
```

**Internal DNS**:
- MCP Server accessible at: `http://ai-todo-mcp-service:8001`
- Backend uses this URL in `MCP_SERVER_URL` environment variable

**Alternatives Considered**:
- Ingress controller: Deferred to Phase 5 (not needed for local dev)
- LoadBalancer: Not supported in Minikube without MetalLB

---

## 8. Health Check Implementation

### Decision: Add `/health` and `/ready` endpoints to FastAPI backend

**Implementation** (in FastAPI `main.py`):
```python
@app.get("/health")
async def health_check():
    """Liveness probe - is app running?"""
    return {"status": "healthy"}

@app.get("/ready")
async def readiness_check():
    """Readiness probe - is app ready to serve?"""
    # Check database connectivity
    try:
        async with Session(engine) as session:
            await session.exec(select(1))
        return {"status": "ready"}
    except Exception as e:
        raise HTTPException(status_code=503, detail="Database not ready")
```

**Rationale**:
- Liveness: Simple response (app is alive)
- Readiness: Validates database connectivity before serving traffic
- Kubernetes uses these to manage pod lifecycle

---

## Summary of Research Findings

| Decision Area | Chosen Approach | Key Rationale |
|---------------|-----------------|---------------|
| Docker Builds | Multi-stage builds | Reduces image size, improves security |
| Helm Organization | 3 independent charts | Enables independent deployment, aligns with modularity |
| Kubernetes Resources | Deployment, Service, ConfigMap, Secret | Meets requirements with standard primitives |
| Statelessness | External PostgreSQL, no local storage | Enables horizontal scaling, pod restart safety |
| Service Types | NodePort (external), ClusterIP (internal) | Simple local access, internal service discovery |
| Health Checks | `/health` (liveness), `/ready` (readiness) | Kubernetes pod lifecycle management |
| Image Registry | Minikube local registry | No external registry needed for local dev |
| Deployment Method | Helm scripts with validation | Declarative, reproducible, versioned |

**All "NEEDS CLARIFICATION" items from Technical Context resolved via research.**

**Next Phase**: Phase 1 (Design & Contracts)
