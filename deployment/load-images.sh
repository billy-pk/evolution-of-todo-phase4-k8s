#!/bin/bash
# Load Docker images into Minikube
# This script loads locally built images into Minikube's Docker daemon

set -e  # Exit on error

echo "=========================================="
echo "Loading Docker Images into Minikube"
echo "=========================================="
echo ""

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

# Load backend image
echo "[1/3] Loading backend image into Minikube..."
minikube image load ai-todo-backend:latest

if [ $? -eq 0 ]; then
  echo "✓ Backend image loaded successfully"
else
  echo "✗ Backend image load failed"
  exit 1
fi
echo ""

# Load MCP server image
echo "[2/3] Loading MCP server image into Minikube..."
minikube image load ai-todo-mcp:latest

if [ $? -eq 0 ]; then
  echo "✓ MCP server image loaded successfully"
else
  echo "✗ MCP server image load failed"
  exit 1
fi
echo ""

# Load frontend image
echo "[3/3] Loading frontend image into Minikube..."
minikube image load ai-todo-frontend:latest

if [ $? -eq 0 ]; then
  echo "✓ Frontend image loaded successfully"
else
  echo "✗ Frontend image load failed"
  exit 1
fi
echo ""

# Verify images are loaded
echo "=========================================="
echo "Verifying Images in Minikube"
echo "=========================================="
minikube image ls | grep ai-todo
echo ""

echo "=========================================="
echo "Images Loaded Successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Deploy to Kubernetes: ./deployment/deploy.sh"
echo ""
