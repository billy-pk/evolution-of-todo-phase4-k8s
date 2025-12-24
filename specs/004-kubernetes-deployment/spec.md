# Feature Specification: Kubernetes Deployment with Minikube and Helm

**Feature Branch**: `004-kubernetes-deployment`
**Created**: 2025-12-24
**Status**: Draft
**Input**: User description: "Phase 4: Kubernetes deployment with Minikube, Helm charts, and MCP server"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy AI Todo System to Local Kubernetes Cluster (Priority: P1)

As a developer, I want to deploy the existing Phase 3 AI Todo application to a local Kubernetes cluster using Minikube so that I can validate the system runs in a containerized, cloud-native environment without modifying the core application logic.

**Why this priority**: This is the foundational deployment capability. Without the ability to deploy the application to Kubernetes, all other cloud-native features cannot be validated. It proves the system is containerizable and can run in an orchestrated environment.

**Independent Test**: Can be fully tested by running `helm install` on Minikube and verifying the AI Todo chat functionality works identically to the Phase 3 local development setup. Delivers a working Kubernetes-deployed application.

**Acceptance Scenarios**:

1. **Given** the Phase 3 AI Todo application is working locally, **When** I build Docker images and deploy via Helm to Minikube, **Then** the application starts successfully and accepts HTTP requests
2. **Given** the application is deployed on Minikube, **When** I access the chat interface via port-forward, **Then** I can create, read, update, and delete todos using natural language exactly as in Phase 3
3. **Given** the application is running in Kubernetes, **When** I restart a pod, **Then** the application recovers without data loss and maintains conversation history from the database

---

### User Story 2 - Deploy MCP Server as Independent Kubernetes Service (Priority: P2)

As a developer, I want the MCP (Model Context Protocol) Server to run as a separate, independently scalable Kubernetes service so that the tool layer is decoupled from the main application and can be managed independently.

**Why this priority**: Decoupling the MCP Server enables independent scaling, updates, and monitoring. This architectural separation is critical for Phase 5 cloud deployment where different services may need different resource allocations.

**Independent Test**: Can be tested by deploying only the MCP Server to Minikube, verifying it responds to tool invocation requests, and confirming the AI Todo service can communicate with it via internal Kubernetes networking.

**Acceptance Scenarios**:

1. **Given** MCP Server Docker image is built, **When** deployed to Minikube as a separate service, **Then** the service is accessible at its internal ClusterIP address
2. **Given** both AI Todo and MCP Server are deployed, **When** the AI agent invokes a tool, **Then** the request is routed to the MCP Server and executes correctly
3. **Given** MCP Server is running, **When** I scale it to multiple replicas, **Then** all replicas serve requests without conflicts or state issues

---

### User Story 3 - Manage Deployment Configuration via Helm Values (Priority: P3)

As a DevOps engineer, I want to manage all deployment configurations (image tags, replicas, ports, environment variables) through Helm values files so that I can parameterize deployments for different environments without modifying Kubernetes manifests.

**Why this priority**: Configuration management is essential for promoting deployments across environments (local → staging → production). Helm values provide a clean separation between infrastructure templates and environment-specific configuration.

**Independent Test**: Can be tested by creating custom values files (e.g., `values-dev.yaml`, `values-prod.yaml`) and verifying that `helm upgrade` with different values files reconfigures the deployment without manual manifest edits.

**Acceptance Scenarios**:

1. **Given** a Helm chart with templated values, **When** I modify replica counts in `values.yaml`, **Then** `helm upgrade` scales the deployment to the new replica count
2. **Given** image tags are defined in values, **When** I change the image tag in `values.yaml` and upgrade, **Then** Kubernetes pulls and deploys the new image version
3. **Given** environment variables are in values, **When** I override them via `--set` flags, **Then** the application receives the updated configuration without redeploying the chart

---

### User Story 4 - Validate Stateless Behavior via Pod Restarts (Priority: P2)

As a platform engineer, I want to verify that the application maintains no local state by intentionally restarting pods and confirming functionality persists so that I can ensure the system is truly cloud-native and horizontally scalable.

**Why this priority**: Statelessness is a core principle for Kubernetes workloads. Without validation, we risk building an application that appears to work but fails under real-world orchestration scenarios (scaling, rolling updates, node failures).

**Independent Test**: Can be tested by creating a conversation with the AI Todo chatbot, deleting the pod, waiting for Kubernetes to reschedule it, and verifying the conversation history is intact.

**Acceptance Scenarios**:

1. **Given** a user has an active conversation with the chatbot, **When** I delete the AI Todo pod, **Then** Kubernetes reschedules it and the user can continue the conversation without re-authentication
2. **Given** tasks have been created via the chat interface, **When** all pods are restarted simultaneously, **Then** all tasks remain in the database and are retrievable
3. **Given** MCP Server is processing tool invocations, **When** the MCP Server pod is deleted, **Then** the new pod handles subsequent tool calls without errors

---

### User Story 5 - Access Deployed Application via Port Forwarding (Priority: P3)

As a developer, I want to access the Kubernetes-deployed application on my local machine using `kubectl port-forward` so that I can interact with the application without requiring external load balancers or ingress controllers.

**Why this priority**: Local development on Minikube doesn't require complex networking. Port forwarding provides the simplest access pattern for testing and validation during Phase 4.

**Independent Test**: Can be tested by running `kubectl port-forward` to the AI Todo service and verifying the application is accessible at `localhost:<port>`.

**Acceptance Scenarios**:

1. **Given** the AI Todo service is running in Minikube, **When** I run `kubectl port-forward svc/ai-todo-service 8000:8000`, **Then** I can access the application at `http://localhost:8000`
2. **Given** port forwarding is active, **When** I send chat requests to `localhost:8000/api/{user_id}/chat`, **Then** the application responds identically to the non-containerized version
3. **Given** the application is accessible via port-forward, **When** I terminate the port-forward process, **Then** the application remains running in the cluster (only local access is interrupted)

---

### Edge Cases

- **What happens when Minikube runs out of resources?** System should gracefully handle pod eviction and reschedule when resources are available
- **How does the system handle simultaneous Helm upgrades?** Helm should block concurrent upgrades and return an error to prevent configuration conflicts
- **What happens when Docker images fail to load into Minikube?** Deployment should remain in pending state with clear error messages indicating image pull failures
- **How does the system handle database connectivity loss?** Pods should crash and restart (fail-fast) rather than serving stale or incomplete data
- **What happens when MCP Server is unavailable?** AI agent tool invocations should timeout gracefully and return error messages to users
- **How does the system handle pod crashes during active user sessions?** Kubernetes should reschedule pods quickly; users should experience brief interruption but no data loss

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST containerize the Phase 3 AI Todo FastAPI application into a Docker image
- **FR-002**: System MUST containerize the MCP Server into a separate Docker image
- **FR-003**: System MUST load Docker images into Minikube's internal registry for deployment
- **FR-004**: System MUST provide a Helm chart that defines Kubernetes Deployment resources for both AI Todo and MCP Server
- **FR-005**: System MUST provide a Helm chart that defines Kubernetes Service resources for both AI Todo (external access) and MCP Server (internal access)
- **FR-006**: System MUST externalize all configuration (database URLs, API keys, MCP endpoints) via Kubernetes ConfigMaps and Secrets
- **FR-007**: System MUST ensure AI Todo application remains stateless with no local file or in-memory session storage
- **FR-008**: System MUST ensure MCP Server remains stateless with no local state persistence
- **FR-009**: System MUST enable communication between AI Todo and MCP Server using internal Kubernetes DNS (ClusterIP service)
- **FR-010**: System MUST preserve all Phase 3 AI chatbot functionality (create/read/update/delete todos via natural language)
- **FR-011**: System MUST support Helm-based deployment with `helm install` and `helm upgrade` commands
- **FR-012**: System MUST support Helm-based configuration updates without manual YAML edits
- **FR-013**: System MUST maintain conversation history in external database accessible from any pod
- **FR-014**: System MUST handle pod restarts without losing user data or conversation state
- **FR-015**: System MUST expose AI Todo service for local access via `kubectl port-forward` or `minikube service`
- **FR-016**: System MUST include health check endpoints for Kubernetes liveness and readiness probes
- **FR-017**: System MUST document Helm values for image tags, replica counts, resource limits, and environment variables
- **FR-018**: System MUST use lightweight base images (Alpine or slim variants) to minimize image size
- **FR-019**: System MUST organize Helm templates with clear separation between Deployments, Services, ConfigMaps, and Secrets
- **FR-020**: System MUST validate that Helm charts pass `helm lint` before deployment

### Key Entities

- **Docker Image (AI Todo)**: Containerized FastAPI application with all dependencies, exposed on port 8000, based on Python 3.13 slim image
- **Docker Image (MCP Server)**: Containerized MCP Server with tool definitions, exposed on port 8001, based on Python 3.13 slim image
- **Helm Chart**: Package containing Kubernetes resource templates (Deployments, Services, ConfigMaps, Secrets) with parameterized values
- **Kubernetes Deployment (AI Todo)**: Manages AI Todo pod replicas, defines container spec, environment variables, and health checks
- **Kubernetes Deployment (MCP Server)**: Manages MCP Server pod replicas, defines container spec and internal networking
- **Kubernetes Service (AI Todo)**: Exposes AI Todo pods via NodePort for external access (port 30080) or ClusterIP for internal access
- **Kubernetes Service (MCP Server)**: Exposes MCP Server pods via ClusterIP for internal-only access by AI Todo service
- **Kubernetes ConfigMap**: Stores non-sensitive configuration (API URLs, feature flags, MCP endpoints)
- **Kubernetes Secret**: Stores sensitive configuration (database passwords, API keys, JWT secrets)
- **Minikube Cluster**: Local single-node Kubernetes cluster running on developer machine, provides container runtime and networking

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can deploy the complete AI Todo system to Minikube using a single `helm install` command in under 5 minutes
- **SC-002**: Application starts and serves requests within 30 seconds of Helm deployment completion
- **SC-003**: AI chatbot functionality works identically to Phase 3 local development (100% feature parity)
- **SC-004**: System survives pod restarts without data loss or conversation interruption (recovery time < 10 seconds)
- **SC-005**: Helm upgrade operations complete without downtime using rolling update strategy
- **SC-006**: Docker images are under 500MB combined (AI Todo + MCP Server)
- **SC-007**: Developer can modify configuration (replicas, image tags, env vars) via Helm values and redeploy in under 2 minutes
- **SC-008**: System handles at least 10 concurrent chat conversations without performance degradation
- **SC-009**: All Kubernetes pods reach Ready state within 60 seconds of deployment
- **SC-010**: MCP Server responds to tool invocations in under 200ms (same as Phase 3 local performance)
- **SC-011**: Helm chart passes `helm lint` with zero errors or warnings
- **SC-012**: Application logs are accessible via `kubectl logs` for debugging and troubleshooting

## Assumptions

1. **Minikube is pre-installed**: Developers have Minikube, kubectl, and Helm installed on their local machines
2. **Docker is available**: Docker or compatible container runtime is available for building images
3. **Database remains external**: Neon PostgreSQL database remains external to the cluster (not deployed in Kubernetes)
4. **No persistent volumes**: Application and MCP Server do not require PersistentVolumeClaims
5. **Single-node cluster**: Minikube runs as a single-node cluster (no multi-node orchestration required)
6. **Local development focus**: Phase 4 targets local Minikube only; cloud Kubernetes providers (GKE, EKS, AKS) are Phase 5
7. **No ingress controller**: Access via `kubectl port-forward` or Minikube NodePort is sufficient
8. **No TLS/SSL**: HTTPS termination is deferred to Phase 5 cloud deployment
9. **Resource limits are generous**: Minikube has at least 4GB RAM and 2 CPUs allocated
10. **Better Auth remains unchanged**: JWT authentication and session management from Phase 3 remain unmodified

## Non-Goals (Out of Scope)

- Cloud-managed Kubernetes deployment (GKE, EKS, AKS)
- Production-grade security hardening (network policies, RBAC, pod security standards)
- Observability stack integration (Prometheus, Grafana, Jaeger)
- CI/CD pipeline automation (GitHub Actions, ArgoCD)
- Multi-environment Helm value management (dev/staging/production)
- Database migration to Kubernetes (PostgreSQL StatefulSet)
- Advanced Kubernetes features (HPA, VPA, PodDisruptionBudgets)
- Ingress controller setup (NGINX, Traefik)
- Service mesh integration (Istio, Linkerd)
- GitOps workflows
- Disaster recovery and backup strategies
- Multi-tenant namespace isolation
- Cost optimization and resource quotas

## Dependencies

- **Phase 3 AI Todo Application**: Must be working with FastAPI, OpenAI Agents SDK, and MCP tools
- **Minikube**: Local Kubernetes cluster runtime
- **Helm 3+**: Package manager for Kubernetes
- **kubectl**: Kubernetes CLI tool
- **Docker**: Container image build tool
- **Neon PostgreSQL**: External database service (existing)
- **OpenAI API**: External LLM service (existing)
- **Better Auth JWKS endpoint**: External authentication service (existing, runs in Next.js frontend)

## Constraints

- **Local development only**: Phase 4 is limited to Minikube; cloud deployment is Phase 5
- **No application logic changes**: Phase 3 code must remain unchanged (only infrastructure and deployment changes)
- **Stateless design**: No PersistentVolumeClaims or local storage allowed
- **Resource limits**: Must run within Minikube's default resource allocation (4GB RAM, 2 CPUs)
- **Single namespace**: All resources deploy to default namespace
- **No custom CRDs**: Standard Kubernetes resources only (Deployment, Service, ConfigMap, Secret)
- **Helm chart compatibility**: Charts must work with Helm 3+ (no Helm 2 support)
- **Image registry**: Images must load into Minikube's internal registry (no external registry push)
