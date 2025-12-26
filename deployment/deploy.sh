#!/bin/bash
# Deploy AI Todo application to Kubernetes using Helm
# This script installs backend, MCP, and frontend Helm charts
#
# Usage:
#   ./deployment/deploy.sh                          # Deploy with default values
#   ./deployment/deploy.sh -f values-dev.yaml       # Deploy with custom values file
#   ./deployment/deploy.sh --values values-prod.yaml # Deploy with custom values file (long form)

set -e  # Exit on error

# Parse command-line arguments
VALUES_FILE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--values)
      VALUES_FILE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [-f|--values <values-file>]"
      echo ""
      echo "Options:"
      echo "  -f, --values FILE    Use custom Helm values file (e.g., deployment/values-dev.yaml)"
      echo "  -h, --help           Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                                    # Deploy with default values"
      echo "  $0 -f deployment/values-dev.yaml     # Deploy with development values"
      echo "  $0 --values deployment/values-prod.yaml  # Deploy with production values"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

echo "=========================================="
echo "Deploying AI Todo to Kubernetes"
echo "=========================================="
echo ""

# Get the repository root directory (parent of deployment/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Display values file being used
if [ -n "$VALUES_FILE" ]; then
  # Convert to absolute path if relative
  if [[ "$VALUES_FILE" != /* ]]; then
    VALUES_FILE="$REPO_ROOT/$VALUES_FILE"
  fi

  if [ ! -f "$VALUES_FILE" ]; then
    echo "✗ Values file not found: $VALUES_FILE"
    exit 1
  fi

  echo "Using custom values file: $VALUES_FILE"
  echo ""
fi

# Check if Minikube is running
if ! minikube status &> /dev/null; then
  echo "✗ Minikube is not running"
  echo ""
  echo "Please start Minikube first:"
  echo "  ./deployment/minikube-setup.sh"
  echo ""
  exit 1
fi

echo "✓ Minikube is running"
echo ""

# Get Minikube IP for frontend configuration
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"
echo ""

# Check for required environment variables
if [ -z "$DATABASE_URL" ]; then
  echo "⚠ WARNING: DATABASE_URL environment variable not set"
  echo "You can set it with: export DATABASE_URL='postgresql://user:pass@host/db'"
  echo ""
fi

if [ -z "$OPENAI_API_KEY" ]; then
  echo "⚠ WARNING: OPENAI_API_KEY environment variable not set"
  echo "You can set it with: export OPENAI_API_KEY='sk-...'"
  echo ""
fi

if [ -z "$BETTER_AUTH_SECRET" ]; then
  echo "⚠ WARNING: BETTER_AUTH_SECRET environment variable not set"
  echo "You can set it with: export BETTER_AUTH_SECRET='your-secret'"
  echo ""
fi

# Deploy MCP Server (must be deployed first - backend depends on it)
echo "=========================================="
echo "[1/3] Deploying MCP Server"
echo "=========================================="
echo ""

MCP_ARGS=(
  ai-todo-mcp
  "$REPO_ROOT/charts/ai-todo-mcp"
)

# Add custom values file if provided
if [ -n "$VALUES_FILE" ]; then
  MCP_ARGS+=(--values "$VALUES_FILE")
fi

# Add environment variables if set
if [ -n "$DATABASE_URL" ]; then
  MCP_ARGS+=(--set "env.DATABASE_URL=$DATABASE_URL")
fi

helm upgrade --install "${MCP_ARGS[@]}"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ MCP Server deployed successfully"
else
  echo "✗ MCP Server deployment failed"
  exit 1
fi
echo ""

# Wait for MCP Server to be ready
echo "Waiting for MCP Server to be ready..."
kubectl wait --for=condition=ready pod -l app=ai-todo-mcp --timeout=60s
echo ""

# Deploy backend
echo "=========================================="
echo "[2/3] Deploying Backend"
echo "=========================================="
echo ""

BACKEND_ARGS=(
  ai-todo-backend
  "$REPO_ROOT/charts/ai-todo-backend"
  --set "env.MCP_SERVER_URL=http://ai-todo-mcp-service:8001"
)

# Add custom values file if provided
if [ -n "$VALUES_FILE" ]; then
  BACKEND_ARGS+=(--values "$VALUES_FILE")
fi

# Add environment variables if set
if [ -n "$DATABASE_URL" ]; then
  BACKEND_ARGS+=(--set "env.DATABASE_URL=$DATABASE_URL")
fi

if [ -n "$OPENAI_API_KEY" ]; then
  BACKEND_ARGS+=(--set "env.OPENAI_API_KEY=$OPENAI_API_KEY")
fi

if [ -n "$BETTER_AUTH_SECRET" ]; then
  BACKEND_ARGS+=(--set "env.BETTER_AUTH_SECRET=$BETTER_AUTH_SECRET")
fi

helm upgrade --install "${BACKEND_ARGS[@]}"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Backend deployed successfully"
else
  echo "✗ Backend deployment failed"
  exit 1
fi
echo ""

# Deploy frontend
echo "=========================================="
echo "[3/3] Deploying Frontend"
echo "=========================================="
echo ""

FRONTEND_ARGS=(
  ai-todo-frontend
  "$REPO_ROOT/charts/ai-todo-frontend"
  --set "env.NEXT_PUBLIC_API_URL=http://${MINIKUBE_IP}:30081"
)

# Add custom values file if provided
if [ -n "$VALUES_FILE" ]; then
  FRONTEND_ARGS+=(--values "$VALUES_FILE")
fi

# Add environment variables if set
if [ -n "$DATABASE_URL" ]; then
  FRONTEND_ARGS+=(--set "env.DATABASE_URL=$DATABASE_URL")
fi

if [ -n "$BETTER_AUTH_SECRET" ]; then
  FRONTEND_ARGS+=(--set "env.BETTER_AUTH_SECRET=$BETTER_AUTH_SECRET")
fi

helm upgrade --install "${FRONTEND_ARGS[@]}"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Frontend deployed successfully"
else
  echo "✗ Frontend deployment failed"
  exit 1
fi
echo ""

# Show deployment status
echo "=========================================="
echo "Deployment Status"
echo "=========================================="
echo ""
echo "Helm releases:"
helm list
echo ""
echo "Pods:"
kubectl get pods
echo ""
echo "Services:"
kubectl get services
echo ""

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Access the application:"
echo "  Frontend:   http://${MINIKUBE_IP}:30080"
echo "  Backend:    http://${MINIKUBE_IP}:30081/health"
echo "  MCP Server: http://ai-todo-mcp-service:8001 (internal only)"
echo ""
echo "Next steps:"
echo "  1. Validate deployment: ./deployment/validate.sh"
echo "  2. Test health endpoints:"
echo "     curl http://${MINIKUBE_IP}:30081/health"
echo "     curl http://${MINIKUBE_IP}:30081/ready"
echo ""
