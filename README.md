# Phase 4: Kubernetes Deployment of AI Todo Application

A **cloud-native, containerized** deployment of the AI-powered conversational todo application on Kubernetes, with support for both local (Minikube) and production (Oracle Cloud K3s) environments.

## 🌟 Overview

This is **Phase 4** of the Evolution of Todo project - deploying the Phase 3 conversational AI application to Kubernetes:

- ✅ **Containerized Services** - Docker images for frontend, backend, and MCP server
- ✅ **Kubernetes Deployment** - Helm charts for all services
- ✅ **Stateless Pods** - Validated pod restart recovery (< 10s)
- ✅ **Local Development** - Minikube with port-forwarding
- ✅ **Production Ready** - Oracle Cloud K3s deployment guide ($0/month)
- ✅ **Health Probes** - Liveness and readiness checks
- ✅ **Multi-Environment** - Development and production configurations

## ⚡ Key Features

### Cloud-Native Design
- **Stateless Pods**: All application state stored in external Neon PostgreSQL
- **Fast Recovery**: < 10 second pod restart recovery validated by automated tests
- **Health Checks**: Liveness (`/health`) and readiness (`/ready`) probes for all services
- **Service Discovery**: Kubernetes DNS for service-to-service communication

### Multi-Environment Support
- **Local Development**: Minikube cluster with port-forwarding for WSL2/Windows
- **Production Deployment**: Oracle Cloud K3s with Traefik ingress and Let's Encrypt SSL
- **Cost**: $0/month using Oracle Always Free tier + Neon free tier

### Security & Authentication
- **JWT Validation**: Better Auth JWKS endpoint for token verification
- **Kubernetes Secrets**: Sensitive data (DATABASE_URL, API keys) in K8s secrets
- **ConfigMaps**: Non-sensitive configuration (service URLs) in ConfigMaps
- **Network Policies**: Internal MCP server (ClusterIP), external frontend/backend (NodePort)

### Developer Experience
- **Helm Charts**: Declarative deployment with version control
- **Automated Scripts**: Build, deploy, validate, and test statelessness
- **Reusable Skill**: Comprehensive documentation in `.claude/skills/`
- **Hot Reload**: Rebuild image → load into Minikube → restart pod workflow

## 🏗️ Architecture

### Kubernetes Deployment

```
┌──────────────────────────────────────────────────────────────┐
│                         User Browser                         │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTP (NodePort or Port-Forward)
                          ↓
┌──────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Minikube/K3s)               │
│                                                              │
│  ┌────────────────────┐          ┌─────────────────────┐    │
│  │  Frontend Pod      │          │  Backend Pod        │    │
│  │  (Next.js 16)      │◄─────────┤  (FastAPI)          │    │
│  │                    │  K8s DNS │                     │    │
│  │  - ChatKit UI      │          │  - JWT Auth         │    │
│  │  - Better Auth     │          │  - OpenAI Agent     │    │
│  │                    │          │  - Health Probes    │    │
│  │  Service:          │          │                     │    │
│  │  NodePort 30080    │          │  Service:           │    │
│  └────────────────────┘          │  NodePort 30081     │    │
│                                  └──────────┬──────────┘    │
│                                             │               │
│                                  ┌──────────▼──────────┐    │
│                                  │  MCP Server Pod     │    │
│                                  │  (FastMCP)          │    │
│                                  │                     │    │
│                                  │  - Task Tools       │    │
│                                  │  - Stateless        │    │
│                                  │                     │    │
│                                  │  Service:           │    │
│                                  │  ClusterIP 8001     │    │
│                                  └──────────┬──────────┘    │
│                                             │               │
└─────────────────────────────────────────────┼───────────────┘
                                              │
                                  ┌───────────▼──────────┐
                                  │ Neon PostgreSQL      │
                                  │ (External Cloud)     │
                                  │                      │
                                  │ - Tasks              │
                                  │ - Conversations      │
                                  │ - Messages           │
                                  └──────────────────────┘
```

## 🚀 Quick Start

### Deployment Options

- **Option 1: Local Development (Minikube)** - Recommended for development and testing
- **Option 2: Production (Oracle Cloud K3s)** - Free cloud deployment ($0/month)

### Option 1: Local Deployment (Minikube)

#### Prerequisites
- **Minikube** >= 1.32
- **kubectl** CLI tool
- **Helm** >= 3.x
- **Docker** (for building images)
- **Neon PostgreSQL** account with database
- **OpenAI API Key**

#### Steps

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192

# 2. Build Docker images
./deployment/build-images.sh

# 3. Load images into Minikube
docker save ai-todo-backend:latest | minikube image load --overwrite -
docker save ai-todo-frontend:latest | minikube image load --overwrite -
docker save ai-todo-mcp:latest | minikube image load --overwrite -

# 4. Set environment variables
export DATABASE_URL='postgresql://user:pass@host/db?sslmode=require'
export BETTER_AUTH_SECRET='your-base64-secret-key'
export OPENAI_API_KEY='sk-...'

# 5. Deploy all services
./deployment/deploy.sh

# 6. Setup port-forwarding (WSL2/Windows)
kubectl port-forward --address 0.0.0.0 svc/ai-todo-frontend-service 3000:3000 &
kubectl port-forward --address 0.0.0.0 svc/ai-todo-backend-service 8000:8000 &

# 7. Access application
# Frontend: http://localhost:3000
# Backend: http://localhost:8000/docs
```

See [deployment/README.md](deployment/README.md) for detailed instructions and troubleshooting.

### Option 2: Production Deployment (Oracle Cloud)

Deploy to Oracle Cloud Always Free tier with K3s:

```bash
# 1. Create Oracle Compute Instance (1GB RAM, Always Free)
# 2. Install K3s on instance
# 3. Transfer Docker images
# 4. Deploy with Helm

# Full guide:
# See .claude/skills/kubernetes-fullstack-deployment/cloud-deployment.md
```

**Cost**: $0/month (Oracle Always Free tier + Neon Free tier)

See [.claude/skills/kubernetes-fullstack-deployment/cloud-deployment.md](.claude/skills/kubernetes-fullstack-deployment/cloud-deployment.md) for complete production deployment guide.

## 📁 Project Structure

```
phase4-k8s/
├── backend/                    # FastAPI backend
│   ├── main.py                # App entry point
│   ├── routes/
│   │   └── chat.py           # Chat endpoint
│   ├── services/
│   │   └── agent.py          # OpenAI Agent
│   ├── tools/
│   │   ├── server.py         # MCP server
│   │   └── start_server_8001.py
│   ├── models.py             # SQLModel models
│   ├── middleware.py         # JWT auth with JWKS
│   └── README.md
├── frontend/                  # Next.js frontend
│   ├── app/
│   │   ├── (auth)/           # Auth pages
│   │   ├── (dashboard)/
│   │   │   └── chat/         # Chat interface
│   │   └── api/auth/         # Better Auth
│   ├── components/
│   │   └── Navbar.tsx
│   ├── lib/
│   │   ├── api.ts            # API client
│   │   └── auth.ts           # Auth config
│   └── README.md
├── charts/                    # Helm charts (NEW in Phase 4)
│   ├── ai-todo-backend/       # Backend chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/        # K8s manifests
│   ├── ai-todo-frontend/      # Frontend chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── ai-todo-mcp/           # MCP server chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── dockerfiles/               # Docker images (NEW in Phase 4)
│   ├── backend.Dockerfile     # Backend + MCP image
│   └── frontend.Dockerfile    # Frontend image
├── deployment/                # Deployment scripts (NEW in Phase 4)
│   ├── build-images.sh       # Build all Docker images
│   ├── deploy.sh             # Deploy to Kubernetes
│   ├── validate.sh           # Validate deployment
│   ├── test-statelessness.sh # Test pod restarts
│   └── README.md             # Deployment guide
├── .claude/skills/            # Reusable skills (NEW in Phase 4)
│   └── kubernetes-fullstack-deployment/
│       ├── SKILL.md          # Quick reference
│       ├── reference.md      # Command reference
│       ├── troubleshooting.md # Common issues
│       ├── workflow.md       # Step-by-step workflows
│       └── cloud-deployment.md # Oracle Cloud guide
├── specs/                     # Feature specifications
│   ├── 003-remove-legacy-endpoints/  # Phase 3
│   └── 004-kubernetes-deployment/    # Phase 4
├── history/prompts/           # Development history (PHRs)
├── CLAUDE.md                  # AI development guide
└── README.md                  # This file
```

## 💬 Using the Chat Interface

### Example Conversations

**Create tasks**:
```
You: Add a task to buy groceries
AI: I've created a task "buy groceries" for you.

You: Create a task: finish the report by Friday with high priority
AI: Task created: "finish the report by Friday" marked as high priority.
```

**List tasks**:
```
You: Show my tasks
AI: You have 3 tasks:
    1. Buy groceries (pending)
    2. Finish the report by Friday (pending, high priority)
    3. Call dentist (completed)

You: List only pending tasks
AI: Here are your pending tasks:
    1. Buy groceries
    2. Finish the report by Friday
```

**Update tasks**:
```
You: Update the groceries task to include milk and bread
AI: Updated task "buy groceries" with description "milk and bread".

You: Change the deadline for the report to Monday
AI: Updated task deadline to Monday.
```

**Complete tasks**:
```
You: Mark the groceries task as done
AI: Task "buy groceries" marked as complete!

You: Complete the report task
AI: Great! Task "finish the report by Friday" is now complete.
```

**Delete tasks**:
```
You: Delete the dentist task
AI: Task "call dentist" has been deleted.
```

## 🔧 Technology Stack

### Frontend
- **Next.js 16** (App Router)
- **React 19**
- **TypeScript**
- **TailwindCSS**
- **Better Auth** (JWT authentication)
- **OpenAI ChatKit** (conversational UI)

### Backend
- **Python 3.13**
- **FastAPI** (async web framework)
- **SQLModel** (ORM)
- **OpenAI Agents SDK** (agent orchestration)
- **FastMCP** (MCP server implementation)
- **Better Auth JWKS** (JWT validation)

### Database
- **Neon PostgreSQL** (serverless, external)
- **SQLModel Models**: Task, Conversation, Message

### Infrastructure (NEW in Phase 4)
- **Kubernetes**: Container orchestration
- **Minikube**: Local K8s cluster for development
- **K3s**: Lightweight K8s for production (Oracle Cloud)
- **Helm 3**: Package manager for Kubernetes
- **Docker**: Container runtime
- **NodePort/ClusterIP**: Service types for networking
- **Health Probes**: Liveness (`/health`) and Readiness (`/ready`) checks

### Deployment
- **Local**: Minikube with port-forwarding
- **Production**: Oracle Cloud Always Free tier (1GB RAM, K3s)
- **Cost**: $0/month (Oracle + Neon free tiers)
- **Architecture**: 3 containerized services (frontend, backend, MCP)
- **Stateless Pods**: All state in external PostgreSQL
- **Recovery Time**: < 10 seconds pod restart recovery

## 📊 MCP Tools

The MCP server exposes 5 tools to the AI agent:

| Tool | Description | Parameters |
|------|-------------|------------|
| `add_task` | Create new task | `user_id`, `title`, `description` |
| `list_tasks` | List user's tasks | `user_id`, `status` (all/pending/completed) |
| `update_task` | Update task | `user_id`, `task_id`, `title`, `description` |
| `complete_task` | Toggle completion | `user_id`, `task_id` |
| `delete_task` | Delete task | `user_id`, `task_id` |

All tools enforce user isolation and return structured JSON responses.

## 🔒 Security

- **JWT Authentication**: All requests require valid Bearer token
- **JWKS Validation**: Backend validates tokens against Better Auth JWKS endpoint
- **User Isolation**: All database queries filtered by authenticated `user_id`
- **No Token in URL**: User ID in path, not in query parameters
- **Path-Token Matching**: Middleware verifies path `user_id` matches JWT claim

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest                    # All tests
pytest tests/test_chat.py # Chat endpoint tests
pytest tests/test_tools.py # MCP tool tests
pytest --cov=.            # With coverage
```

### Frontend Tests
```bash
cd frontend
npm test                  # All tests
npm test -- chat          # Chat component tests
```

### Manual Testing
1. Sign in at http://localhost:3000/signin
2. Navigate to http://localhost:3000/chat
3. Test all CRUD operations conversationally
4. Verify multi-user isolation (sign in as different users)

## 📚 Documentation

### Phase 4 (Kubernetes Deployment)
- **Deployment Guide**: [deployment/README.md](deployment/README.md)
- **Kubernetes Skill**: [.claude/skills/kubernetes-fullstack-deployment/SKILL.md](.claude/skills/kubernetes-fullstack-deployment/SKILL.md)
- **Command Reference**: [.claude/skills/kubernetes-fullstack-deployment/reference.md](.claude/skills/kubernetes-fullstack-deployment/reference.md)
- **Troubleshooting**: [.claude/skills/kubernetes-fullstack-deployment/troubleshooting.md](.claude/skills/kubernetes-fullstack-deployment/troubleshooting.md)
- **Cloud Deployment**: [.claude/skills/kubernetes-fullstack-deployment/cloud-deployment.md](.claude/skills/kubernetes-fullstack-deployment/cloud-deployment.md)
- **Feature Specs**: [specs/004-kubernetes-deployment/](specs/004-kubernetes-deployment/)

### Application
- **Frontend Setup**: [frontend/README.md](frontend/README.md)
- **Backend Setup**: [backend/README.md](backend/README.md)
- **AI Development Guide**: [CLAUDE.md](CLAUDE.md)
- **Development History**: [history/prompts/](history/prompts/)

## 🎯 Phase 4 Principles

Per [Constitution v3.0.0](.specify/memory/constitution.md):

1. **Cloud-Native Design**: Fully containerized, stateless pods
2. **External State Management**: All state in external Neon PostgreSQL
3. **Health Probes**: Liveness and readiness checks for all services
4. **Pod Restart Resilience**: < 10 second recovery from pod deletion
5. **Multi-Environment Support**: Development (Minikube) and production (K3s)
6. **Zero-Cost Production**: Oracle Always Free tier + Neon free tier

## 🔄 Evolution from Phase 3

Phase 4 adds Kubernetes deployment to Phase 3 conversational app:

**Added**:
- ✅ 3 Helm charts (backend, frontend, MCP)
- ✅ 2 Dockerfiles (backend with MCP, frontend)
- ✅ Deployment scripts (build, deploy, validate, test statelessness)
- ✅ Health endpoints (`/health`, `/ready`)
- ✅ Kubernetes ConfigMaps and Secrets
- ✅ Production deployment guide (Oracle Cloud K3s)
- ✅ Reusable skill documentation

**Configuration Changes**:
- 🔧 Backend: Added `BETTER_AUTH_URL` env var for JWKS fetching
- 🔧 MCP Server: Added Kubernetes DNS to `allowed_hosts`
- 🔧 Secrets management: Moved from `.env` to Kubernetes Secrets

**Infrastructure**:
- 🏗️ Local: Minikube with NodePort services
- 🏗️ Production: K3s with Traefik ingress
- 🏗️ Networking: Service-to-service via Kubernetes DNS

## 🛠️ Development

### Local Development (without Kubernetes)

For quick iteration without containerization:

```bash
# Terminal 1: Backend API
cd backend && source .venv/bin/activate && uvicorn main:app --reload

# Terminal 2: MCP Server
cd backend && source .venv/bin/activate && uv run tools/start_server_8001.py

# Terminal 3: Frontend
cd frontend && npm run dev
```

### Kubernetes Development Workflow

For testing containerized deployment:

```bash
# 1. Make code changes to backend/frontend/tools

# 2. Rebuild affected service image
./deployment/build-images.sh

# 3. Load updated image into Minikube
docker save ai-todo-backend:latest | minikube image load --overwrite -

# 4. Restart pods to use new image
kubectl delete pod -l app=ai-todo-backend

# 5. Verify new pod is running
kubectl get pods --watch

# 6. Check logs for errors
kubectl logs -l app=ai-todo-backend --tail=50
```

### Testing Statelessness

Validate that pods can restart without data loss:

```bash
# Run automated statelessness tests
./deployment/test-statelessness.sh

# Manual test: delete pod during operation
kubectl delete pod -l app=ai-todo-backend
# Conversation should continue after pod recreates
```

### Code Quality
```bash
# Backend
cd backend
black .           # Format
ruff check .      # Lint
mypy .            # Type check

# Frontend
cd frontend
npm run lint      # ESLint
npm run format    # Prettier
```

## 🚧 Troubleshooting

### Kubernetes-Specific Issues

**Pods stuck in Pending/ImagePullBackOff?**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Verify images loaded into Minikube
minikube image ls | grep ai-todo

# Re-load images if missing
docker save ai-todo-backend:latest | minikube image load --overwrite -
```

**Pods in CrashLoopBackOff?**
```bash
# Check logs for error
kubectl logs <pod-name>

# Common causes:
# - Missing DATABASE_URL in secrets
# - Database connection timeout
# - BETTER_AUTH_SECRET mismatch

# Verify secrets exist
kubectl get secrets
```

**401 Unauthorized in chat?**
```bash
# Check backend can reach frontend for JWKS
kubectl logs -l app=ai-todo-backend | grep JWKS

# Verify BETTER_AUTH_URL is set correctly
kubectl describe configmap ai-todo-backend-config

# Should be: http://ai-todo-frontend-service:3000
```

**421 Misdirected Request from MCP?**
```bash
# Check MCP server allowed_hosts includes Kubernetes DNS
kubectl exec -it <mcp-pod> -- cat /app/backend/tools/server.py | grep allowed_hosts

# Should include: ai-todo-mcp-service:*
# If not, rebuild image with updated allowed_hosts
```

**Port-forward not working?**
```bash
# Kill stale port-forwards
pkill -f "kubectl port-forward"

# Restart with --address 0.0.0.0 for WSL2/Windows
kubectl port-forward --address 0.0.0.0 svc/ai-todo-frontend-service 3000:3000 &
kubectl port-forward --address 0.0.0.0 svc/ai-todo-backend-service 8000:8000 &
```

### General Issues

**Chat not responding?**
- Check MCP pod is running: `kubectl get pods -l app=ai-todo-mcp`
- Verify OPENAI_API_KEY in secrets: `kubectl describe secret ai-todo-backend-secrets`
- Check MCP server URL in backend ConfigMap

**Authentication errors?**
- Verify BETTER_AUTH_SECRET matches in frontend and backend secrets
- Check JWKS endpoint is accessible from backend
- Manually delete old JWKS from database if secret changed

**Database errors?**
- Verify DATABASE_URL in all secrets
- Check Neon database is active and accepting connections
- Test connectivity: `kubectl exec <pod> -- ping <neon-host>`

See [.claude/skills/kubernetes-fullstack-deployment/troubleshooting.md](.claude/skills/kubernetes-fullstack-deployment/troubleshooting.md) for comprehensive troubleshooting guide.

## 📝 License

MIT

## 🤝 Contributing

This is an educational project demonstrating cloud-native deployment of conversational AI applications. Contributions welcome!

Areas of interest:
- Additional deployment targets (AWS EKS, GCP GKE, Azure AKS)
- CI/CD pipelines (GitHub Actions, GitLab CI)
- Monitoring and observability (Prometheus, Grafana)
- Auto-scaling configurations
- Multi-region deployments

## 🎓 Learning Resources

### Kubernetes & Deployment
- **Kubernetes Docs**: https://kubernetes.io/docs/home/
- **Minikube**: https://minikube.sigs.k8s.io/docs/
- **Helm Charts**: https://helm.sh/docs/
- **K3s**: https://k3s.io/
- **Docker**: https://docs.docker.com/
- **Oracle Cloud Always Free**: https://www.oracle.com/cloud/free/

### Application Stack
- **OpenAI Agents SDK**: https://github.com/openai/openai-python
- **FastMCP**: https://github.com/jlowin/fastmcp
- **Model Context Protocol**: https://modelcontextprotocol.io
- **Better Auth**: https://www.better-auth.com
- **Next.js App Router**: https://nextjs.org/docs
- **Neon PostgreSQL**: https://neon.tech/docs
