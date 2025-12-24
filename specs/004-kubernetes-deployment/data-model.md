# Data Model: Kubernetes Deployment

**Feature**: 004-kubernetes-deployment
**Phase**: 1 (Design)
**Date**: 2025-12-24

## Overview

This document defines the data structures and configuration models for Phase 4 Kubernetes deployment. Unlike typical application data models (which Phase 3 already defined for tasks/conversations/messages), this focuses on infrastructure and deployment configuration data.

## 1. Docker Image Metadata

### Entity: DockerImage

**Purpose**: Represents a containerized service ready for Kubernetes deployment

**Attributes**:
- `name`: Image name (e.g., `ai-todo-backend`)
- `tag`: Version tag (e.g., `latest`, `v1.0.0`)
- `registry`: Image registry location (e.g., Minikube local registry)
- `size`: Image size in MB
- `baseImage`: Base image used (e.g., `python:3.13-slim`)
- `exposedPorts`: List of ports exposed (e.g., `[8000]` for backend)
- `buildContext`: Directory context for build (e.g., `./backend`)
- `dockerfile`: Path to Dockerfile (e.g., `dockerfiles/backend.Dockerfile`)

**Validation Rules**:
- `size` MUST be < 250MB per image (combined < 500MB per SC-006)
- `tag` MUST follow semantic versioning or be `latest`
- `exposedPorts` MUST match application port configuration

**State Transitions**:
1. Built → Tagged → Loaded (into Minikube) → Running (in pod)

**Example**:
```yaml
name: ai-todo-backend
tag: latest
registry: minikube.local
size: 180MB
baseImage: python:3.13-slim
exposedPorts: [8000]
buildContext: ./backend
dockerfile: dockerfiles/backend.Dockerfile
```

---

## 2. Helm Chart Metadata

### Entity: HelmChart

**Purpose**: Represents a Helm package containing Kubernetes resource templates

**Attributes**:
- `name`: Chart name (e.g., `ai-todo-backend`)
- `version`: Chart version (semantic versioning, tracks infrastructure changes)
- `appVersion`: Application version (tracks Docker image version)
- `description`: Brief description of what the chart deploys
- `dependencies`: List of dependent charts (empty for Phase 4)
- `values`: Default configuration values from `values.yaml`
- `templates`: List of Kubernetes resource templates

**Validation Rules**:
- `version` MUST follow semantic versioning (MAJOR.MINOR.PATCH)
- `appVersion` MUST match Docker image tag
- Chart MUST pass `helm lint` with zero errors (FR-020)

**Templates Included**:
- `deployment.yaml`: Pod template
- `service.yaml`: Network access
- `configmap.yaml`: Non-sensitive config (optional)
- `secret.yaml`: Sensitive config (optional)

**Example**:
```yaml
name: ai-todo-backend
version: 1.0.0
appVersion: latest
description: "AI Todo FastAPI Backend with MCP integration"
dependencies: []
values:
  replicaCount: 1
  image:
    repository: ai-todo-backend
    tag: latest
  service:
    type: NodePort
    port: 8000
    nodePort: 30081
```

---

## 3. Kubernetes Deployment Configuration

### Entity: DeploymentSpec

**Purpose**: Defines how pods are created and managed

**Attributes**:
- `name`: Deployment name (e.g., `ai-todo-backend-deployment`)
- `replicas`: Number of pod replicas (1-3 for Minikube)
- `image`: Docker image reference (name:tag)
- `ports`: Container ports to expose
- `env`: Environment variables (from ConfigMap/Secret)
- `resources`: CPU and memory limits/requests
- `livenessProbe`: Health check for pod restart
- `readinessProbe`: Health check for traffic routing
- `strategy`: Update strategy (RollingUpdate)

**Resource Limits** (per pod):
```yaml
resources:
  limits:
    cpu: 500m      # 0.5 CPU cores max
    memory: 512Mi  # 512 MB max
  requests:
    cpu: 250m      # 0.25 CPU cores guaranteed
    memory: 256Mi  # 256 MB guaranteed
```

**Health Probes**:
```yaml
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

**Update Strategy**:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Max 1 extra pod during update
    maxUnavailable: 0    # Always keep at least 1 pod running
```

---

## 4. Kubernetes Service Configuration

### Entity: ServiceSpec

**Purpose**: Defines network access to pods

**Attributes**:
- `name`: Service name (e.g., `ai-todo-backend-service`)
- `type`: Service type (`NodePort` for external, `ClusterIP` for internal)
- `selector`: Pod labels to route traffic to
- `ports`: Port mappings (port, targetPort, nodePort)

**Service Types**:

**Backend (NodePort)**:
```yaml
name: ai-todo-backend-service
type: NodePort
ports:
  - port: 8000          # Service port
    targetPort: 8000    # Container port
    nodePort: 30081     # External access port
selector:
  app: ai-todo-backend
```

**MCP Server (ClusterIP)**:
```yaml
name: ai-todo-mcp-service
type: ClusterIP
ports:
  - port: 8001
    targetPort: 8001
selector:
  app: ai-todo-mcp
```

**Internal DNS**:
- Services accessible via: `<service-name>.<namespace>.svc.cluster.local`
- Short form: `<service-name>` (within same namespace)
- Example: `http://ai-todo-mcp-service:8001`

---

## 5. Configuration Data (ConfigMap/Secret)

### Entity: ConfigMapSpec

**Purpose**: Store non-sensitive configuration

**Attributes**:
- `name`: ConfigMap name
- `data`: Key-value pairs of configuration

**Example**:
```yaml
name: ai-todo-backend-config
data:
  MCP_SERVER_URL: "http://ai-todo-mcp-service:8001"
  BETTER_AUTH_ISSUER: "http://ai-todo-frontend-service:3000"
  BETTER_AUTH_JWKS_URL: "http://ai-todo-frontend-service:3000/api/auth/jwks"
  LOG_LEVEL: "info"
```

### Entity: SecretSpec

**Purpose**: Store sensitive configuration (base64-encoded)

**Attributes**:
- `name`: Secret name
- `type`: Secret type (Opaque)
- `data`: Base64-encoded key-value pairs

**Example** (not base64-encoded for clarity):
```yaml
name: ai-todo-backend-secrets
type: Opaque
data:
  DATABASE_URL: "postgresql://user:password@neon-host/dbname"
  OPENAI_API_KEY: "sk-..."
  BETTER_AUTH_SECRET: "shared-secret-key"
```

**Security Rules**:
- Secrets NEVER committed to Git
- Injected via `helm install --set` or external secret file
- Mounted as environment variables, not files

---

## 6. Deployment Workflow State

### Entity: DeploymentState

**Purpose**: Track deployment lifecycle

**States**:
1. **Building**: Docker images being built
2. **Loading**: Images being loaded into Minikube
3. **Installing**: Helm charts being installed
4. **Pending**: Pods created but not ready
5. **Running**: Pods running and healthy
6. **Ready**: Pods passing readiness probes, receiving traffic
7. **Failed**: Deployment failed (e.g., image pull error, crash loop)
8. **Upgrading**: Helm upgrade in progress (rolling update)

**State Transitions**:
```
Building → Loading → Installing → Pending → Running → Ready
                                     ↓
                                  Failed (restart or rollback)
```

**Validation Points**:
- **After Building**: Verify image size < 250MB
- **After Loading**: `minikube image ls` shows images
- **After Installing**: `helm list` shows releases
- **After Pending**: `kubectl get pods` shows Running status
- **After Ready**: Health checks pass, service endpoints populated

---

## 7. Minikube Cluster Configuration

### Entity: MinikubeCluster

**Purpose**: Represents local Kubernetes cluster state

**Attributes**:
- `cpus`: Allocated CPU cores (default: 2)
- `memory`: Allocated RAM in MB (default: 4096)
- `driver`: Virtualization driver (docker, virtualbox, kvm2)
- `kubernetesVersion`: K8s version (e.g., v1.28.3)
- `status`: Cluster status (Running, Stopped, Paused)
- `ip`: Cluster IP address (for NodePort access)
- `addons`: Enabled addons (e.g., metrics-server)

**Example**:
```yaml
cpus: 2
memory: 4096
driver: docker
kubernetesVersion: v1.28.3
status: Running
ip: 192.168.49.2
addons:
  - metrics-server
```

---

## Entity Relationships

```
MinikubeCluster
    ↓ (contains)
[Kubernetes Resources]
    ↓
HelmChart ---(installs)---> DeploymentSpec ---(manages)---> Pods
                                ↓
                          ServiceSpec ---(routes traffic to)---> Pods
                                ↓
                          ConfigMapSpec/SecretSpec ---(provides config to)---> Pods
                                ↓
                          DockerImage ---(runs in)---> Pods
```

---

## Data Persistence

**Phase 3 Database Schema** (unchanged):
- `tasks` table
- `conversations` table
- `messages` table
- `users` table (Better Auth)
- `sessions` table (Better Auth)

**Phase 4 Infrastructure Data** (not persisted in database):
- Docker images: Stored in Minikube's container runtime
- Helm releases: Stored in Kubernetes (Helm metadata in Secrets)
- ConfigMaps/Secrets: Stored in Kubernetes etcd

**No new database tables required for Phase 4.**

---

## Summary

Phase 4 introduces **infrastructure entities** (Docker images, Helm charts, Kubernetes resources) but **no application data model changes**. All Phase 3 data (tasks, conversations, messages) remains unchanged and continues to be stored in the external Neon PostgreSQL database.

**Key Entities**:
1. **DockerImage**: Containerized service
2. **HelmChart**: Kubernetes package
3. **DeploymentSpec**: Pod management configuration
4. **ServiceSpec**: Network access configuration
5. **ConfigMapSpec/SecretSpec**: Application configuration
6. **DeploymentState**: Lifecycle tracking
7. **MinikubeCluster**: Local Kubernetes environment

**Data Flow**: User → NodePort → Service → Pod (with DockerImage) → External Database
