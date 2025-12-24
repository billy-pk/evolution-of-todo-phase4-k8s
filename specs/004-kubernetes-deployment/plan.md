# Implementation Plan: Kubernetes Deployment with Minikube and Helm

**Branch**: `004-kubernetes-deployment` | **Date**: 2025-12-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-kubernetes-deployment/spec.md`

**Note**: This template is filled in by the `/sp.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Deploy the existing Phase 3 AI Todo application (FastAPI backend + MCP Server) to a local Kubernetes cluster using Minikube and Helm charts. The implementation focuses on containerization, declarative infrastructure-as-code, and stateless cloud-native design while preserving 100% of Phase 3 chatbot functionality. The deployment will use multi-stage Docker builds for lightweight images, Helm for parameterized Kubernetes resource management, and external Neon PostgreSQL for data persistence. All three services (Backend API, MCP Server, Frontend) will be deployed as separate pods with internal ClusterIP networking for MCP and NodePort exposure for external access.

## Technical Context

**Language/Version**: Python 3.13 (backend, MCP server), Node.js 20+ (frontend), Bash (deployment scripts)
**Primary Dependencies**:
  - Backend: FastAPI, Uvicorn, SQLModel, OpenAI Agents SDK, FastMCP, Better Auth (JWT validation)
  - Frontend: Next.js 16, React, TailwindCSS, OpenAI ChatKit
  - Infrastructure: Docker, Kubernetes 1.28+, Helm 3.x, Minikube 1.32+
**Storage**: Neon PostgreSQL (external, not containerized), No persistent volumes required
**Testing**: pytest (backend), Jest + React Testing Library (frontend), helm lint (charts), kubectl validate (manifests)
**Target Platform**: Local Kubernetes via Minikube (single-node cluster), Linux/macOS/WSL2 host OS
**Project Type**: Web application with 3 containerized services (frontend, backend, MCP server)
**Performance Goals**:
  - Image build time < 5 minutes
  - Helm deployment time < 5 minutes
  - Pod startup time < 30 seconds
  - Application response time same as Phase 3 (MCP < 200ms)
  - Combined image size < 500MB
**Constraints**:
  - Minikube resource limits: 4GB RAM, 2 CPUs
  - No PersistentVolumeClaims (stateless design)
  - Local development only (no cloud deployment)
  - Single namespace (default)
  - NodePort access only (no Ingress)
  - External database (Neon PostgreSQL)
**Scale/Scope**:
  - 3 Docker images (frontend, backend, MCP server)
  - 3 Helm deployments
  - 3 Kubernetes services
  - 10+ concurrent chat conversations
  - 1-3 pod replicas per service

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Conversational Interface Primary ✅ PASS
- **Rule**: All task management operations MUST be accessible through conversational interface
- **Compliance**: Phase 4 preserves Phase 3 chatbot unchanged. No modifications to conversational AI logic. Deployment is infrastructure-only.
- **Verification**: FR-010 requires 100% Phase 3 feature parity

### Principle II: Stateless Server Design ✅ PASS
- **Rule**: All chat endpoints, MCP tools, and Kubernetes pods MUST be fully stateless
- **Compliance**:
  - FR-007: AI Todo application stateless (no local storage)
  - FR-008: MCP Server stateless
  - FR-013: Conversation history in external database
  - FR-014: Pod restarts without data loss
  - User Story 4 validates statelessness via pod restart tests
- **Verification**: SC-004 measures pod recovery time < 10 seconds

### Principle III: Security First ✅ PASS
- **Rule**: User isolation and authentication enforced at every boundary, Kubernetes secrets for sensitive data
- **Compliance**:
  - FR-006: Externalize config via Kubernetes ConfigMaps and Secrets
  - JWT authentication from Phase 3 unchanged
  - Database passwords, API keys in Kubernetes Secrets (not in images)
- **Verification**: No hard-coded secrets in Dockerfiles or Helm templates

### Principle IV: Single Source of Truth ✅ PASS
- **Rule**: All task data in single database with consistent access patterns
- **Compliance**:
  - External Neon PostgreSQL database (Assumption #3)
  - FR-013: Conversation history accessible from any pod
  - No data duplication across pods
- **Verification**: Phase 3 database schema unchanged

### Principle V: Test-Driven Development ⚠️ ADAPTED
- **Rule**: Tests MUST be written before implementation
- **Compliance**: Phase 4 is infrastructure-focused. TDD adapted:
  - Write deployment validation tests (helm lint, kubectl dry-run)
  - Test pod health checks before Helm deployment
  - Validate statelessness via integration tests (pod restart scenarios)
- **Note**: Infrastructure-as-code allows validation without traditional unit tests

### Principle VI: Extensibility and Modularity ✅ PASS
- **Rule**: Components containerized and independently deployable
- **Compliance**:
  - FR-001, FR-002: Separate Docker images for Backend and MCP Server
  - FR-004, FR-005: Independent Helm Deployments and Services
  - User Story 2: MCP Server independently scalable
  - Configuration externalized (FR-006)
- **Verification**: Each service has own Dockerfile and can be deployed separately

### Principle VII: Infrastructure as Code ✅ PASS (PRIMARY FOCUS)
- **Rule**: All deployment configurations version-controlled and declarative
- **Compliance**:
  - FR-004, FR-005: Helm charts define all Kubernetes resources
  - FR-011: Deployment via `helm install`/`helm upgrade` only
  - FR-019: Helm templates organized clearly
  - FR-020: Charts pass `helm lint`
- **Verification**: User Story 3 tests configuration via values files, SC-011 validates linting

### Principle VIII: AI-Assisted DevOps ✅ PASS (RECOMMENDED)
- **Rule**: SHOULD use Gordon, kubectl-ai, kagent for operations
- **Compliance**: Phase 4 spec encourages AI-assisted tools but does not mandate them
- **Note**: Implementation may use Gordon for Dockerfile optimization, kubectl-ai for troubleshooting
- **Verification**: Not enforced (RECOMMENDED, not NON-NEGOTIABLE)

### Principle IX: Local-First Cloud Development ✅ PASS (PRIMARY FOCUS)
- **Rule**: All deployments MUST work on local Minikube before cloud
- **Compliance**:
  - Assumption #6: Phase 4 targets Minikube only
  - FR-003: Images load into Minikube registry
  - User Story 1: Deploy to Minikube
  - NodePort access (FR-015, User Story 5)
  - Constraint: No cloud-specific dependencies
- **Verification**: SC-001 measures Minikube deployment time

### Constitution Compliance Summary

**Status**: ✅ **ALL GATES PASS**

**Violations**: None

**Adaptations**:
- Principle V (TDD) adapted for infrastructure context - deployment validation tests replace traditional unit tests

**Next Steps**: Proceed to Phase 0 Research

## Project Structure

### Documentation (this feature)

```text
specs/004-kubernetes-deployment/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/sp.plan command output)
├── research.md          # Phase 0 output (/sp.plan command)
├── data-model.md        # Phase 1 output (/sp.plan command)
├── quickstart.md        # Phase 1 output (/sp.plan command)
├── contracts/           # Phase 1 output (/sp.plan command)
│   ├── docker-images.md
│   ├── helm-charts.md
│   └── kubernetes-resources.md
├── checklists/
│   └── requirements.md  # Specification quality checklist (completed)
└── tasks.md             # Phase 2 output (/sp.tasks command - NOT created by /sp.plan)
```

### Source Code (repository root)

**Project Type**: Web application with infrastructure additions

```text
# Existing Phase 3 Structure (unchanged)
backend/
├── main.py
├── models.py
├── schemas.py
├── config.py
├── middleware.py
├── db.py
├── routes/
│   └── chat.py
├── services/
│   └── agent.py
├── tools/
│   └── server.py        # MCP Server
└── tests/

frontend/
├── app/
│   ├── (auth)/
│   ├── (dashboard)/
│   └── api/auth/
├── components/
├── lib/
└── tests/

# NEW Phase 4 Infrastructure (to be added)
charts/                   # NEW: Helm charts root
├── ai-todo-backend/      # NEW: Backend Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       └── secret.yaml
├── ai-todo-mcp/          # NEW: MCP Server Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── README.md
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
└── ai-todo-frontend/     # NEW: Frontend Helm chart
    ├── Chart.yaml
    ├── values.yaml
    ├── README.md
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        └── configmap.yaml

dockerfiles/              # NEW: Dockerfile directory
├── backend.Dockerfile    # NEW: Multi-stage FastAPI build
├── mcp.Dockerfile        # NEW: Multi-stage MCP Server build
└── frontend.Dockerfile   # NEW: Multi-stage Next.js build

deployment/               # NEW: Deployment scripts and documentation
├── README.md             # NEW: Deployment guide
├── minikube-setup.sh     # NEW: Minikube initialization script
├── build-images.sh       # NEW: Build all Docker images
├── load-images.sh        # NEW: Load images into Minikube
├── deploy.sh             # NEW: Helm install/upgrade script
└── validate.sh           # NEW: Deployment validation script
```

**Structure Decision**:
- **Existing codebase preserved**: Backend and frontend code from Phase 3 remain unchanged
- **Infrastructure additions**: New top-level directories for Docker, Helm, and deployment scripts
- **Separation of concerns**: Infrastructure separated from application code for clarity
- **Helm chart per service**: Each service (backend, MCP, frontend) has independent Helm chart for modularity

## Complexity Tracking

**No violations** - Constitution Check passed all gates. This section is not required.
