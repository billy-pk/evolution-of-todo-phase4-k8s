# Phase 4 Specifications
## Evolution of Todo – Cloud-Native & Kubernetes Deployment (Local with Minikube)

**Project:** Evolution of Todo  
**Phase:** 4 (Kubernetes & Cloud-Native)   
**Environment:** Local machine using **Minikube**  
**Deployment Method:** Kubernetes manifests + **Helm Charts**  
**Purpose:** Deploy and operate the Phase 3 AI Todo system as a cloud-native, Kubernetes-orchestrated application on a local development cluster, including deployment of an MCP (Model Context Protocol) Server, using spec-driven and agentic development principles.

---

## 1. Objective

Phase 4 focuses on **deployment, scalability, and operational readiness** on a **local Kubernetes cluster (Minikube)**.

The objective is to:
- Containerize the existing AI Todo application
- Deploy and manage it on Minikube
- Deploy an MCP Server as a first-class Kubernetes service
- Package Kubernetes resources using Helm charts
- Demonstrate stateless, restart-safe behavior
- Preserve all Phase 3 agentic logic unchanged
- Introduce AI-assisted Kubernetes and agent tooling

---

## 2. Non-Goals

The following are explicitly **out of scope** for Phase 4:

- New Todo or AI features
- Cloud-managed Kubernetes (GKE/EKS/AKS)
- Multi-user authentication
- Advanced observability stacks (Prometheus, Grafana)
- Full CI/CD pipelines
- Production-grade security hardening

---

## 3. Architecture Overview

High-level flow (local machine):

User  
→ kubectl port-forward / Minikube Service  
→ FastAPI AI Todo Service (stateless pod)  
→ MCP Server (context + tool gateway)  
→ External dependencies (DB, Vector Store, LLM APIs)

All Kubernetes components run inside **Minikube** and are installed via **Helm charts**.

---

## 4. Design Principles

### 4.1 Stateless Application
- FastAPI service remains stateless
- MCP Server remains stateless
- No in-memory or local file persistence
- Conversation history and context passed explicitly per request

### 4.2 Externalized State
- Database and vector store run as:
  - Separate services, containers, or external processes
- No persistent volumes required for application or MCP server
- Secrets managed via Kubernetes Secrets

### 4.3 Declarative Infrastructure
- Kubernetes YAML defines desired state
- Helm templates parameterize the infrastructure
- No manual changes inside running pods
- Entire setup is reproducible via Helm install/upgrade

---

## 5. Local Kubernetes Environment (Minikube)

### 5.1 Minikube Responsibilities
- Acts as the local Kubernetes control plane
- Runs all pods, services, and networking
- Enables rapid iteration without cloud cost
- Mirrors real Kubernetes behavior for learning and demos

### 5.2 Access Patterns
- `kubectl port-forward` for local testing
- `minikube service` for browser access (optional)
- No external ingress controller required

---

## 6. Helm Charts Strategy

### 6.1 Purpose of Helm
Helm is used as the **primary packaging and deployment mechanism** for Phase 4.

Helm enables:
- Reusable Kubernetes templates
- Environment-based configuration
- Clean separation between code and infrastructure values
- Easy upgrades and rollbacks

---

### 6.2 Chart Structure

A single parent Helm chart manages the system:

charts/
evolution-of-todo/
Chart.yaml
values.yaml
templates/
app-deployment.yaml
app-service.yaml
mcp-deployment.yaml
mcp-service.yaml
configmap.yaml
secret.yaml


---

### 6.3 Values Management
- `values.yaml` controls:
  - Image names and tags
  - Replica counts
  - Ports
  - Environment variables
  - MCP server endpoints
- Secrets are referenced, not hardcoded

---

## 7. Components

### 7.1 FastAPI AI Todo Service

**Responsibilities**
- Accept chat-based Todo commands
- Invoke agentic reasoning
- Communicate with MCP Server for tools and context
- Perform Todo CRUD operations
- Return structured AI responses

**Constraints**
- Runs inside a container
- No local state
- Configured only via environment variables
- Deployed via Helm-managed Kubernetes resources

---

### 7.2 MCP Server (Model Context Protocol)

**Purpose**
The MCP Server acts as a **standardized context and tool interface** between the AI Todo application and external capabilities.

**Responsibilities**
- Provide tools to the AI agent
- Define context schemas and tool contracts
- Act as a boundary between reasoning and execution
- Enable future extensibility

**Constraints**
- Stateless service
- No business logic duplication
- Deployed independently via Helm

---

### 7.3 Docker

**Requirements**
- Separate Dockerfiles for:
  - FastAPI AI Todo Service
  - MCP Server
- Lightweight base images
- Expose required ports
- Compatible with Minikube image loading

---

## 8. Kubernetes Resources (Helm-Managed)

**Required**
- Deployment (AI Todo Service)
- Deployment (MCP Server)
- Service (AI Todo Service)
- Service (MCP Server)
- ConfigMap
- Secret

**Optional**
- Horizontal Pod Autoscaler (templated but disabled by default)
- Ingress (optional, disabled by default)

---

## 9. AI-Assisted Kubernetes & Agent Tooling

### 9.1 kubectl-ai
- Natural language interface to Kubernetes
- Inspects Helm-managed resources
- Assists with debugging pods, services, and logs

### 9.2 KAgent
- Observes cluster state
- Advises on pod failures or misconfigurations
- Helm-aware (understands releases and labels)

### 9.3 Gordon (or similar AI agents)
- Explains Kubernetes and Helm behavior
- Assists in chart design and values tuning
- Used during development and learning

---

## 10. Agentic Development Model

### 10.1 Agent Roles

- **Architecture Agent**
  - Validates Minikube + Helm architecture
- **Infra Agent**
  - Designs Helm charts and templates
- **MCP Agent**
  - Defines MCP tools and context contracts
- **Kubernetes AI Agent**
  - Uses kubectl-ai / KAgent for insight
- **Runtime Agent**
  - Ensures stateless execution
- **Validation Agent**
  - Confirms correctness after Helm deployment

---

## 11. Operational Flow (Local)

1. Start Minikube
2. Build Docker images (App + MCP)
3. Load images into Minikube
4. Install system using Helm
5. Kubernetes schedules pods
6. App communicates with MCP Server internally
7. Access app via port-forward
8. Test AI Todo functionality
9. Restart pods and verify no data loss
10. Upgrade Helm release to test changes

---

## 12. Definition of Dones

Phase 4 is complete when:

- [ ] Minikube cluster runs successfully
- [ ] Helm chart installs without errors
- [ ] Docker images build and load into Minikube
- [ ] AI Todo Service runs in Kubernetes
- [ ] MCP Server runs as a separate service
- [ ] App communicates with MCP Server
- [ ] AI chat can create/read/update Todos
- [ ] Pod restarts do not lose data
- [ ] Configuration is values-driven
- [ ] Services scale independently
- [ ] Phase 3 logic remains unchanged

---

## 13. Risks and Mitigations

| Risk | Mitigation |
|----|-----------|
| Over-engineering | Keep Helm charts minimal |
| Chart complexity | Single chart, clear values |
| Local resource limits | Single replica by default |
| Tool distraction | Helm complements, not replaces, K8s fundamentals |

---

## 14. Future Evolution (Phase 5 Preview)

- Helm chart promotion to cloud clusters
- Values per environment (dev/stage/prod)
- GitOps workflows
- Secure MCP authentication
- Observability integration

---

## 15. Summary

Phase 4 transitions **Evolution of Todo** from:

“An AI-powered application”

to:

“A Helm-packaged, Kubernetes-native, MCP-enabled, agent-assisted AI system”

Running on **Minikube**, this phase proves the system is:
- Stateless
- Modular
- Declarative
- Agent-ready
- Cloud-portable

---
