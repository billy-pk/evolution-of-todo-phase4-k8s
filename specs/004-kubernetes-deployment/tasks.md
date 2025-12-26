---

description: "Task list for Kubernetes Deployment with Minikube and Helm"
---

# Tasks: Kubernetes Deployment with Minikube and Helm

**Input**: Design documents from `/specs/004-kubernetes-deployment/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: No dedicated test tasks - validation through deployment scripts and Helm linting

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each deployment capability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Infrastructure**: `dockerfiles/`, `charts/`, `deployment/` at repository root
- **Application code**: `backend/`, `frontend/` (unchanged from Phase 3)

---

## Phase 1: Setup (Infrastructure Foundation)

**Purpose**: Create directory structure and deployment scripts framework

- [x] T001 Create dockerfiles directory at repository root
- [x] T002 Create charts directory at repository root
- [x] T003 Create deployment directory at repository root
- [x] T004 [P] Create deployment/README.md with deployment guide structure
- [x] T005 [P] Create deployment/minikube-setup.sh script for cluster initialization

---

## Phase 2: Foundational (Health Endpoints - Blocks All User Stories)

**Purpose**: Add health check endpoints required by all Kubernetes deployments

**⚠️ CRITICAL**: All services need health endpoints before containerization

- [x] T006 Add /health endpoint to backend/main.py returning {"status": "healthy"}
- [x] T007 Add /ready endpoint to backend/main.py with database connectivity check
- [x] T008 [P] Add health check endpoint to backend/tools/server.py for MCP Server
- [x] T009 Test health endpoints locally before containerization

**Checkpoint**: Health endpoints ready - containerization can now begin

---

## Phase 3: User Story 1 - Deploy AI Todo System to Local Kubernetes Cluster (Priority: P1) 🎯 MVP

**Goal**: Deploy Phase 3 AI Todo application to Minikube with 100% feature parity

**Independent Test**: Run `helm install` on Minikube and verify chat functionality works identically to Phase 3 local setup

### Backend Containerization (User Story 1)

- [x] T010 [P] [US1] Create multi-stage Dockerfile for backend in dockerfiles/backend.Dockerfile
- [x] T011 [US1] Configure backend Dockerfile with Python 3.13-slim base image
- [x] T012 [US1] Add builder stage with uv dependency installation in dockerfiles/backend.Dockerfile
- [x] T013 [US1] Add runtime stage copying .venv and application code in dockerfiles/backend.Dockerfile
- [x] T014 [US1] Set CMD to uvicorn main:app --host 0.0.0.0 --port 8000 in dockerfiles/backend.Dockerfile
- [x] T015 [US1] Build backend image and validate size < 200MB

### Backend Helm Chart (User Story 1)

- [x] T016 [P] [US1] Create charts/ai-todo-backend directory structure
- [x] T017 [P] [US1] Create charts/ai-todo-backend/Chart.yaml with version 1.0.0
- [x] T018 [P] [US1] Create charts/ai-todo-backend/values.yaml per contracts/helm-charts.md
- [x] T019 [P] [US1] Create charts/ai-todo-backend/templates/deployment.yaml per contracts/kubernetes-resources.md
- [x] T020 [P] [US1] Create charts/ai-todo-backend/templates/service.yaml for NodePort 30081
- [x] T021 [P] [US1] Create charts/ai-todo-backend/templates/configmap.yaml for non-sensitive config
- [x] T022 [P] [US1] Create charts/ai-todo-backend/templates/secret.yaml template for sensitive config
- [x] T023 [US1] Add liveness probe configuration (GET /health) in charts/ai-todo-backend/templates/deployment.yaml
- [x] T024 [US1] Add readiness probe configuration (GET /ready) in charts/ai-todo-backend/templates/deployment.yaml
- [x] T025 [US1] Add resource limits (500m CPU, 512Mi memory) in charts/ai-todo-backend/templates/deployment.yaml
- [x] T026 [US1] Add RollingUpdate strategy with maxSurge=1, maxUnavailable=0 in charts/ai-todo-backend/templates/deployment.yaml
- [x] T027 [US1] Create charts/ai-todo-backend/README.md with installation instructions
- [x] T028 [US1] Run helm lint ./charts/ai-todo-backend and fix all errors

### Frontend Containerization (User Story 1)

- [x] T029 [P] [US1] Create multi-stage Dockerfile for frontend in dockerfiles/frontend.Dockerfile
- [x] T030 [US1] Add dependencies stage with npm ci in dockerfiles/frontend.Dockerfile
- [x] T031 [US1] Add builder stage with npm run build in dockerfiles/frontend.Dockerfile
- [x] T032 [US1] Add runtime stage copying .next and node_modules in dockerfiles/frontend.Dockerfile
- [x] T033 [US1] Set CMD to npm start in dockerfiles/frontend.Dockerfile
- [x] T034 [US1] Build frontend image and validate size < 200MB

### Frontend Helm Chart (User Story 1)

- [x] T035 [P] [US1] Create charts/ai-todo-frontend directory structure
- [x] T036 [P] [US1] Create charts/ai-todo-frontend/Chart.yaml with version 1.0.0
- [x] T037 [P] [US1] Create charts/ai-todo-frontend/values.yaml per contracts/helm-charts.md
- [x] T038 [P] [US1] Create charts/ai-todo-frontend/templates/deployment.yaml per contracts/kubernetes-resources.md
- [x] T039 [P] [US1] Create charts/ai-todo-frontend/templates/service.yaml for NodePort 30080
- [x] T040 [P] [US1] Create charts/ai-todo-frontend/templates/configmap.yaml for frontend config
- [x] T041 [P] [US1] Create charts/ai-todo-frontend/templates/secret.yaml template for Better Auth secret
- [x] T042 [US1] Add resource limits (500m CPU, 512Mi memory) in charts/ai-todo-frontend/templates/deployment.yaml
- [x] T043 [US1] Create charts/ai-todo-frontend/README.md with installation instructions
- [x] T044 [US1] Run helm lint ./charts/ai-todo-frontend and fix all errors

### Deployment Automation (User Story 1)

- [x] T045 [P] [US1] Create deployment/build-images.sh to build all Docker images
- [x] T046 [P] [US1] Create deployment/load-images.sh to load images into Minikube
- [x] T047 [P] [US1] Create deployment/deploy.sh with helm install commands for backend and frontend
- [x] T048 [P] [US1] Create deployment/validate.sh to check pod status and run helm lint
- [x] T049 [US1] Make all deployment scripts executable (chmod +x)
- [x] T050 [US1] Test full deployment workflow: minikube-setup.sh → build-images.sh → load-images.sh → deploy.sh
- [x] T051 [US1] Verify backend accessible at http://$(minikube ip):30081/health
- [x] T052 [US1] Verify frontend accessible at http://$(minikube ip):30080
- [x] T053 [US1] Test AI Todo chat functionality in Kubernetes environment
- [x] T054 [US1] Verify pod restart preserves conversation history (statelessness validation)

**Checkpoint**: Backend and Frontend deployed to Minikube with full Phase 3 feature parity

---

## Phase 4: User Story 2 - Deploy MCP Server as Independent Kubernetes Service (Priority: P2)

**Goal**: Decouple MCP Server for independent scaling and management

**Independent Test**: Deploy only MCP Server, verify it responds to tool invocations, and confirm AI Todo backend can communicate via internal Kubernetes DNS

### MCP Server Containerization (User Story 2)

- [x] T055 [P] [US2] Create multi-stage Dockerfile for MCP Server in dockerfiles/mcp.Dockerfile
- [x] T056 [US2] Configure MCP Dockerfile with Python 3.13-slim base image
- [x] T057 [US2] Add builder stage with FastMCP dependency installation in dockerfiles/mcp.Dockerfile
- [x] T058 [US2] Add runtime stage copying .venv and tools/server.py in dockerfiles/mcp.Dockerfile
- [x] T059 [US2] Set CMD to python tools/server.py in dockerfiles/mcp.Dockerfile
- [x] T060 [US2] Build MCP image and validate size < 150MB

### MCP Server Helm Chart (User Story 2)

- [x] T061 [P] [US2] Create charts/ai-todo-mcp directory structure
- [x] T062 [P] [US2] Create charts/ai-todo-mcp/Chart.yaml with version 1.0.0
- [x] T063 [P] [US2] Create charts/ai-todo-mcp/values.yaml per contracts/helm-charts.md
- [x] T064 [P] [US2] Create charts/ai-todo-mcp/templates/deployment.yaml per contracts/kubernetes-resources.md
- [x] T065 [P] [US2] Create charts/ai-todo-mcp/templates/service.yaml for ClusterIP port 8001
- [x] T066 [P] [US2] Create charts/ai-todo-mcp/templates/secret.yaml template for DATABASE_URL
- [x] T067 [US2] Add resource limits (250m CPU, 256Mi memory) in charts/ai-todo-mcp/templates/deployment.yaml
- [x] T068 [US2] Create charts/ai-todo-mcp/README.md with installation instructions
- [x] T069 [US2] Run helm lint ./charts/ai-todo-mcp and fix all errors

### MCP Integration (User Story 2)

- [x] T070 [US2] Update deployment/build-images.sh to include MCP Server image build
- [x] T071 [US2] Update deployment/load-images.sh to load MCP Server image into Minikube
- [x] T072 [US2] Update deployment/deploy.sh to install ai-todo-mcp chart before backend
- [x] T073 [US2] Update backend Helm values to use internal DNS: http://ai-todo-mcp-service:8001
- [x] T074 [US2] Deploy MCP Server to Minikube
- [x] T075 [US2] Verify MCP Server service has ClusterIP (not NodePort)
- [x] T076 [US2] Test backend can communicate with MCP Server via internal Kubernetes DNS
- [x] T077 [US2] Test tool invocation through AI chat interface in Kubernetes
- [x] T078 [US2] Scale MCP Server to 2 replicas and verify both serve requests without state conflicts

**Checkpoint**: MCP Server independently deployed and integrated with backend via Kubernetes networking

---

## Phase 5: User Story 3 - Manage Deployment Configuration via Helm Values (Priority: P3)

**Goal**: Parameterize all configurations for different environments via Helm values

**Independent Test**: Create custom values files and verify `helm upgrade` reconfigures deployment without manual manifest edits

### Helm Values Parameterization (User Story 3)

- [ ] T079 [P] [US3] Parameterize image tags in all charts (backend, MCP, frontend)
- [ ] T080 [P] [US3] Parameterize replica counts in all deployment templates
- [ ] T081 [P] [US3] Parameterize resource limits in all deployment templates
- [ ] T082 [P] [US3] Parameterize environment variables in all charts
- [ ] T083 [US3] Document all values in charts/*/values.yaml with inline comments
- [ ] T084 [US3] Create example values override file deployment/values-dev.yaml
- [ ] T085 [US3] Create example values override file deployment/values-prod.yaml
- [ ] T086 [US3] Update deployment/deploy.sh to support --values flag for custom values files
- [ ] T087 [US3] Test helm upgrade with modified replica count in values file
- [ ] T088 [US3] Test helm upgrade with modified image tag in values file
- [ ] T089 [US3] Test helm upgrade with --set flag for environment variable override
- [ ] T090 [US3] Verify configuration changes take effect without redeploying entire chart

**Checkpoint**: All deployment configurations managed via Helm values with no hard-coded values in templates

---

## Phase 6: User Story 4 - Validate Stateless Behavior via Pod Restarts (Priority: P2)

**Goal**: Prove system is truly cloud-native by validating no local state persists across restarts

**Independent Test**: Create conversation, delete pod, verify conversation history intact after rescheduling

### Statelessness Validation (User Story 4)

- [ ] T091 [P] [US4] Create deployment/test-statelessness.sh script for automated validation
- [ ] T092 [US4] Add test case: Create conversation via chat, delete backend pod, verify conversation persists
- [ ] T093 [US4] Add test case: Create tasks via chat, delete all pods simultaneously, verify tasks remain
- [ ] T094 [US4] Add test case: Delete MCP Server pod during tool invocation, verify new pod handles subsequent calls
- [ ] T095 [US4] Verify pod recovery time < 10 seconds after deletion
- [ ] T096 [US4] Verify no data loss after pod restarts
- [ ] T097 [US4] Document statelessness validation in deployment/README.md

**Checkpoint**: Statelessness validated - system ready for horizontal scaling

---

## Phase 7: User Story 5 - Access Deployed Application via Port Forwarding (Priority: P3)

**Goal**: Provide simple local access pattern without external load balancers

**Independent Test**: Run kubectl port-forward and verify application accessible at localhost

### Port Forwarding and Access (User Story 5)

- [ ] T098 [P] [US5] Document kubectl port-forward usage in deployment/README.md
- [ ] T099 [P] [US5] Create deployment/port-forward.sh script to automate port forwarding
- [ ] T100 [US5] Test backend access via kubectl port-forward svc/ai-todo-backend-service 8000:8000
- [ ] T101 [US5] Test frontend access via kubectl port-forward svc/ai-todo-frontend-service 3000:3000
- [ ] T102 [US5] Verify chat requests to localhost:8000/api/{user_id}/chat work identically to NodePort access
- [ ] T103 [US5] Verify terminating port-forward does not affect running pods in cluster
- [ ] T104 [US5] Document minikube service command as alternative access method in deployment/README.md

**Checkpoint**: Multiple access methods documented and validated

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and deployment refinement

- [ ] T105 [P] Add deployment architecture diagram to deployment/README.md
- [ ] T106 [P] Document troubleshooting common issues in deployment/README.md
- [ ] T107 [P] Add cleanup instructions (helm uninstall, minikube delete) to deployment/README.md
- [ ] T108 [P] Document development workflow for code changes in deployment/README.md
- [ ] T109 Validate all Docker images combined size < 500MB (SC-006)
- [ ] T110 Validate Helm deployment completes in < 5 minutes (SC-001)
- [ ] T111 Validate pods reach Ready state in < 60 seconds (SC-009)
- [ ] T112 Validate MCP Server response time < 200ms (SC-010)
- [ ] T113 Run deployment/validate.sh and verify all checks pass
- [ ] T114 Test deployment on fresh Minikube cluster from scratch
- [ ] T115 Verify all Helm charts pass helm lint with zero errors/warnings (SC-011)
- [ ] T116 Update quickstart.md with any deployment workflow improvements discovered
- [ ] T117 Run through quickstart.md end-to-end validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User Story 1 (P1) - MVP: Can start after Foundational
  - User Story 2 (P2): Depends on User Story 1 (needs backend deployed first)
  - User Story 3 (P3): Can start after User Story 1 (needs charts to exist)
  - User Story 4 (P2): Depends on User Stories 1 and 2 (needs full deployment)
  - User Story 5 (P3): Can start after User Story 1 (needs services deployed)
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 completion (backend must exist to integrate MCP)
- **User Story 3 (P3)**: Depends on User Story 1 completion (charts must exist to parameterize)
- **User Story 4 (P2)**: Depends on User Stories 1 and 2 completion (full system needed for statelessness tests)
- **User Story 5 (P3)**: Depends on User Story 1 completion (services must exist for port forwarding)

### Within Each User Story

- Dockerfiles before Helm charts (charts reference images)
- Helm templates before helm lint validation
- Build and load images before deployment
- MCP Server deployment before backend deployment (backend depends on MCP service DNS)
- Deployment before validation tests

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- Health endpoints for backend and MCP server can be implemented in parallel (T006-T008)
- Within User Story 1:
  - Backend Dockerfile tasks (T010-T015) parallel with Frontend Dockerfile tasks (T029-T034)
  - Backend Helm template creation (T016-T022) parallel with Frontend Helm template creation (T035-T041)
  - Deployment script creation (T045-T048) can run in parallel
- Within User Story 2:
  - MCP Dockerfile tasks (T055-T060) parallel with MCP Helm template tasks (T061-T069)
- Within User Story 3:
  - Parameterization of backend, MCP, and frontend values can run in parallel (T079-T082)
  - Example values files can be created in parallel (T084-T085)
- Within User Story 5:
  - Documentation and script creation can run in parallel (T098-T099)
- Polish phase documentation tasks can run in parallel (T105-T108)

---

## Parallel Example: User Story 1 Backend Setup

```bash
# Launch backend containerization and Helm chart creation together:
Task: "Create multi-stage Dockerfile for backend in dockerfiles/backend.Dockerfile"
Task: "Create charts/ai-todo-backend directory structure"
Task: "Create charts/ai-todo-backend/Chart.yaml with version 1.0.0"

# Launch all Helm template creation together (after directory structure exists):
Task: "Create charts/ai-todo-backend/templates/deployment.yaml"
Task: "Create charts/ai-todo-backend/templates/service.yaml"
Task: "Create charts/ai-todo-backend/templates/configmap.yaml"
Task: "Create charts/ai-todo-backend/templates/secret.yaml template"
```

---

## Implementation Strategy

### MVP First (User Stories 1 Only - Backend + Frontend)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (health endpoints)
3. Complete Phase 3: User Story 1 (Backend + Frontend to Minikube)
4. **STOP and VALIDATE**: Test full AI Todo functionality in Kubernetes
5. Deploy/demo Phase 4 MVP with 100% Phase 3 feature parity

### Incremental Delivery

1. Complete Setup + Foundational → Health endpoints ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! Backend + Frontend in K8s)
3. Add User Story 2 → Test independently → Deploy/Demo (MCP Server decoupled)
4. Add User Story 3 → Test independently → Deploy/Demo (Configuration management)
5. Add User Story 4 → Test independently → Validate statelessness
6. Add User Story 5 → Test independently → Document access methods
7. Polish → Complete documentation and validation

### Critical Path (Minimum for Working Deployment)

1. Phase 1: Setup (T001-T005)
2. Phase 2: Foundational (T006-T009) - Health endpoints
3. Phase 3: User Story 1 (T010-T054) - Full deployment to Minikube
4. Phase 4: User Story 2 (T055-T078) - MCP Server independence
5. Phase 8: Polish validation (T113-T117) - Verify success criteria

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- No test tasks included - infrastructure validated through deployment and linting
- MCP Server must deploy before backend (backend depends on MCP service DNS)
- Health endpoints are foundational - required before containerization
- All Helm charts must pass `helm lint` before deployment
- Validate combined image size < 500MB (SC-006)
- Each user story delivers independently testable deployment capability
- Commit after each task or logical group
