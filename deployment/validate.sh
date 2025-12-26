#!/bin/bash
# Validate AI Todo Kubernetes deployment
# This script checks pod status, services, and runs Helm lint

set -e  # Exit on error

echo "=========================================="
echo "Validating AI Todo Deployment"
echo "=========================================="
echo ""

# Get the repository root directory (parent of deployment/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if Minikube is running
if ! minikube status &> /dev/null; then
  echo "✗ Minikube is not running"
  exit 1
fi

echo "✓ Minikube is running"
echo ""

# Validate Helm charts
echo "=========================================="
echo "Helm Chart Validation"
echo "=========================================="
echo ""

echo "Linting backend chart..."
helm lint "$REPO_ROOT/charts/ai-todo-backend"
echo ""

echo "Linting frontend chart..."
helm lint "$REPO_ROOT/charts/ai-todo-frontend"
echo ""

# Check Helm releases
echo "=========================================="
echo "Helm Releases"
echo "=========================================="
helm list
echo ""

# Check pods
echo "=========================================="
echo "Pod Status"
echo "=========================================="
kubectl get pods
echo ""

# Check if all pods are running
BACKEND_POD=$(kubectl get pods -l app=ai-todo-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
FRONTEND_POD=$(kubectl get pods -l app=ai-todo-frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$BACKEND_POD" ]; then
  echo "⚠ Backend pod not found"
else
  BACKEND_STATUS=$(kubectl get pod "$BACKEND_POD" -o jsonpath='{.status.phase}')
  echo "Backend pod: $BACKEND_POD - Status: $BACKEND_STATUS"
fi

if [ -z "$FRONTEND_POD" ]; then
  echo "⚠ Frontend pod not found"
else
  FRONTEND_STATUS=$(kubectl get pod "$FRONTEND_POD" -o jsonpath='{.status.phase}')
  echo "Frontend pod: $FRONTEND_POD - Status: $FRONTEND_STATUS"
fi
echo ""

# Check services
echo "=========================================="
echo "Services"
echo "=========================================="
kubectl get services
echo ""

# Check ConfigMaps
echo "=========================================="
echo "ConfigMaps"
echo "=========================================="
kubectl get configmaps | grep -E "NAME|ai-todo" || echo "No AI Todo ConfigMaps found"
echo ""

# Check Secrets
echo "=========================================="
echo "Secrets"
echo "=========================================="
kubectl get secrets | grep -E "NAME|ai-todo" || echo "No AI Todo Secrets found"
echo ""

# Test health endpoints
echo "=========================================="
echo "Health Endpoint Tests"
echo "=========================================="
echo ""

MINIKUBE_IP=$(minikube ip)

echo "Testing backend /health endpoint..."
if curl -s -f "http://${MINIKUBE_IP}:30081/health" > /dev/null 2>&1; then
  echo "✓ Backend /health endpoint responding"
  curl -s "http://${MINIKUBE_IP}:30081/health"
  echo ""
else
  echo "✗ Backend /health endpoint not responding"
fi
echo ""

echo "Testing backend /ready endpoint..."
if curl -s -f "http://${MINIKUBE_IP}:30081/ready" > /dev/null 2>&1; then
  echo "✓ Backend /ready endpoint responding"
  curl -s "http://${MINIKUBE_IP}:30081/ready"
  echo ""
else
  echo "✗ Backend /ready endpoint not responding"
fi
echo ""

echo "Testing frontend..."
if curl -s -f "http://${MINIKUBE_IP}:30080" > /dev/null 2>&1; then
  echo "✓ Frontend responding"
else
  echo "✗ Frontend not responding"
fi
echo ""

# Summary
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo ""
echo "Minikube IP: $MINIKUBE_IP"
echo "Frontend URL: http://${MINIKUBE_IP}:30080"
echo "Backend API: http://${MINIKUBE_IP}:30081"
echo ""
echo "To view logs:"
if [ -n "$BACKEND_POD" ]; then
  echo "  Backend:  kubectl logs $BACKEND_POD"
fi
if [ -n "$FRONTEND_POD" ]; then
  echo "  Frontend: kubectl logs $FRONTEND_POD"
fi
echo ""
echo "To debug pods:"
if [ -n "$BACKEND_POD" ]; then
  echo "  kubectl describe pod $BACKEND_POD"
fi
if [ -n "$FRONTEND_POD" ]; then
  echo "  kubectl describe pod $FRONTEND_POD"
fi
echo ""
