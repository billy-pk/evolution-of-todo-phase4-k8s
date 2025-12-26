#!/bin/bash
# Deploy AI Todo application to Kubernetes using Helm
# This script installs backend and frontend Helm charts

set -e  # Exit on error

echo "=========================================="
echo "Deploying AI Todo to Kubernetes"
echo "=========================================="
echo ""

# Get the repository root directory (parent of deployment/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Deploy backend
echo "=========================================="
echo "[1/2] Deploying Backend"
echo "=========================================="
echo ""

BACKEND_ARGS=(
  ai-todo-backend
  "$REPO_ROOT/charts/ai-todo-backend"
)

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
echo "[2/2] Deploying Frontend"
echo "=========================================="
echo ""

FRONTEND_ARGS=(
  ai-todo-frontend
  "$REPO_ROOT/charts/ai-todo-frontend"
  --set "env.NEXT_PUBLIC_API_URL=http://${MINIKUBE_IP}:30081"
)

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
echo "  Frontend: http://${MINIKUBE_IP}:30080"
echo "  Backend:  http://${MINIKUBE_IP}:30081/health"
echo ""
echo "Next steps:"
echo "  1. Validate deployment: ./deployment/validate.sh"
echo "  2. Test health endpoints:"
echo "     curl http://${MINIKUBE_IP}:30081/health"
echo "     curl http://${MINIKUBE_IP}:30081/ready"
echo ""
