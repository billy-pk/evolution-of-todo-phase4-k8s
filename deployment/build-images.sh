#!/bin/bash
# Build all Docker images for AI Todo application
# This script builds backend and frontend images locally

set -e  # Exit on error

echo "=========================================="
echo "Building AI Todo Docker Images"
echo "=========================================="
echo ""

# Get the repository root directory (parent of deployment/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Repository root: $REPO_ROOT"
echo ""

# Build backend image
echo "[1/3] Building backend image..."
docker build \
  -t ai-todo-backend:latest \
  -f "$REPO_ROOT/dockerfiles/backend.Dockerfile" \
  "$REPO_ROOT/backend"

if [ $? -eq 0 ]; then
  echo "✓ Backend image built successfully"
else
  echo "✗ Backend image build failed"
  exit 1
fi
echo ""

# Build MCP server image
echo "[2/3] Building MCP server image..."
docker build \
  -t ai-todo-mcp:latest \
  -f "$REPO_ROOT/dockerfiles/mcp.Dockerfile" \
  "$REPO_ROOT/backend"

if [ $? -eq 0 ]; then
  echo "✓ MCP server image built successfully"
else
  echo "✗ MCP server image build failed"
  exit 1
fi
echo ""

# Build frontend image
echo "[3/3] Building frontend image..."
docker build \
  -t ai-todo-frontend:latest \
  -f "$REPO_ROOT/dockerfiles/frontend.Dockerfile" \
  "$REPO_ROOT/frontend"

if [ $? -eq 0 ]; then
  echo "✓ Frontend image built successfully"
else
  echo "✗ Frontend image build failed"
  exit 1
fi
echo ""

# Display image sizes
echo "=========================================="
echo "Image Build Summary"
echo "=========================================="
docker images | grep -E "REPOSITORY|ai-todo"
echo ""

# Validate image sizes
BACKEND_SIZE=$(docker images ai-todo-backend:latest --format "{{.Size}}" | sed 's/MB//')
MCP_SIZE=$(docker images ai-todo-mcp:latest --format "{{.Size}}" | sed 's/MB//')
FRONTEND_SIZE=$(docker images ai-todo-frontend:latest --format "{{.Size}}" | sed 's/MB//')

echo "Size validation:"
echo "  Backend: ${BACKEND_SIZE} (target: < 200MB)"
echo "  MCP Server: ${MCP_SIZE} (target: < 150MB)"
echo "  Frontend: ${FRONTEND_SIZE} (target: < 200MB)"
echo ""

echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Load images into Minikube: ./deployment/load-images.sh"
echo "  2. Deploy to Kubernetes: ./deployment/deploy.sh"
echo ""
