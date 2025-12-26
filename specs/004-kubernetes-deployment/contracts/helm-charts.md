# Helm Charts Contract

**Feature**: 004-kubernetes-deployment
**Date**: 2025-12-24

## Overview

This contract defines the Helm chart structure and values schema for all three services.

## 1. Backend Helm Chart (`charts/ai-todo-backend`)

**Chart Metadata** (`Chart.yaml`):
```yaml
apiVersion: v2
name: ai-todo-backend
description: AI Todo FastAPI Backend with MCP integration
type: application
version: 1.0.0
appVersion: latest
```

**Default Values** (`values.yaml`):
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
  DATABASE_URL: ""
  OPENAI_API_KEY: ""
  MCP_SERVER_URL: "http://ai-todo-mcp-service:8001"
  BETTER_AUTH_SECRET: ""
  BETTER_AUTH_ISSUER: "http://ai-todo-frontend-service:3000"
  BETTER_AUTH_JWKS_URL: "http://ai-todo-frontend-service:3000/api/auth/jwks"

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

**Installation Command**:
```bash
helm install ai-todo-backend ./charts/ai-todo-backend \
  --set env.DATABASE_URL="postgresql://..." \
  --set env.OPENAI_API_KEY="sk-..." \
  --set env.BETTER_AUTH_SECRET="shared-secret"
```

---

## 2. MCP Server Helm Chart (`charts/ai-todo-mcp`)

**Chart Metadata** (`Chart.yaml`):
```yaml
apiVersion: v2
name: ai-todo-mcp
description: MCP Server for AI Todo task operations
type: application
version: 1.0.0
appVersion: latest
```

**Default Values** (`values.yaml`):
```yaml
replicaCount: 1

image:
  repository: ai-todo-mcp
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8001

resources:
  limits:
    cpu: 250m
    memory: 256Mi
  requests:
    cpu: 125m
    memory: 128Mi

env:
  DATABASE_URL: ""
```

**Installation Command**:
```bash
helm install ai-todo-mcp ./charts/ai-todo-mcp \
  --set env.DATABASE_URL="postgresql://..."
```

---

## 3. Frontend Helm Chart (`charts/ai-todo-frontend`)

**Chart Metadata** (`Chart.yaml`):
```yaml
apiVersion: v2
name: ai-todo-frontend
description: AI Todo Next.js Frontend with ChatKit
type: application
version: 1.0.0
appVersion: latest
```

**Default Values** (`values.yaml`):
```yaml
replicaCount: 1

image:
  repository: ai-todo-frontend
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 3000
  nodePort: 30080

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

env:
  NEXT_PUBLIC_API_URL: "http://192.168.49.2:30081"
  BETTER_AUTH_SECRET: ""
  BETTER_AUTH_URL: "http://localhost:30080"
  DATABASE_URL: ""
```

**Installation Command**:
```bash
helm install ai-todo-frontend ./charts/ai-todo-frontend \
  --set env.NEXT_PUBLIC_API_URL="http://$(minikube ip):30081" \
  --set env.BETTER_AUTH_SECRET="shared-secret" \
  --set env.DATABASE_URL="postgresql://..."
```

---

## Helm Operations

**Install**:
```bash
helm install <release-name> ./charts/<chart-name>
```

**Upgrade**:
```bash
helm upgrade <release-name> ./charts/<chart-name> --set key=value
```

**Rollback**:
```bash
helm rollback <release-name> <revision>
```

**Uninstall**:
```bash
helm uninstall <release-name>
```

**Lint**:
```bash
helm lint ./charts/<chart-name>
```

**List Releases**:
```bash
helm list
```

---

## Template Files

All charts include these templates:

**deployment.yaml**:
- Defines pod template, replicas, image, env vars, probes, resources

**service.yaml**:
- Defines service type, ports, selectors

**configmap.yaml** (optional):
- Non-sensitive configuration

**secret.yaml** (optional):
- Sensitive configuration (recommend external secrets)

---

## Validation Requirements

All Helm charts MUST:
1. Pass `helm lint` with zero errors/warnings (FR-020)
2. Support `--set` overrides for all environment variables
3. Include README.md with deployment instructions
4. Use semantic versioning for chart version
5. Match appVersion with Docker image tag
