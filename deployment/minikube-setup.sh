#!/bin/bash

##############################################################################
# Minikube Cluster Initialization Script
#
# Purpose: Initialize a local Kubernetes cluster via Minikube for AI Todo deployment
# Usage: ./deployment/minikube-setup.sh
# Requirements: Minikube >= 1.32, kubectl
##############################################################################

set -e  # Exit on any error

echo "========================================"
echo " AI Todo - Minikube Cluster Setup"
echo "========================================"
echo ""

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "❌ Error: Minikube is not installed"
    echo "   Install from: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed"
    echo "   Install from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo "✓ Minikube version: $(minikube version --short)"
echo "✓ kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo ""

# Check if Minikube is already running
if minikube status &> /dev/null; then
    echo "ℹ️  Minikube cluster is already running"
    echo ""
    read -p "Do you want to delete and recreate the cluster? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing Minikube cluster..."
        minikube delete
        echo "✓ Cluster deleted"
        echo ""
    else
        echo "✓ Using existing cluster"
        echo ""
        minikube status
        exit 0
    fi
fi

# Start Minikube with recommended resources
echo "🚀 Starting Minikube cluster..."
echo "   CPUs: 2"
echo "   Memory: 4096 MB"
echo "   Driver: docker (auto-detected)"
echo ""

minikube start \
    --cpus=2 \
    --memory=4096 \
    --driver=docker \
    --kubernetes-version=stable

echo ""
echo "✓ Minikube cluster started successfully"
echo ""

# Enable metrics-server addon for resource monitoring
echo "📊 Enabling metrics-server addon..."
minikube addons enable metrics-server

echo ""
echo "✓ metrics-server addon enabled"
echo ""

# Verify cluster is ready
echo "🔍 Verifying cluster status..."
kubectl cluster-info

echo ""
echo "📋 Cluster nodes:"
kubectl get nodes

echo ""
echo "========================================"
echo " ✅ Minikube Setup Complete!"
echo "========================================"
echo ""
echo "Cluster Information:"
echo "  • Minikube IP: $(minikube ip)"
echo "  • Kubernetes version: $(kubectl version --short 2>/dev/null | grep Server || kubectl version -o json | grep gitVersion)"
echo "  • Dashboard: Run 'minikube dashboard' to open"
echo ""
echo "Next Steps:"
echo "  1. Build Docker images: ./deployment/build-images.sh"
echo "  2. Load images: ./deployment/load-images.sh"
echo "  3. Deploy services: ./deployment/deploy.sh"
echo ""
echo "Useful Commands:"
echo "  • Check status: minikube status"
echo "  • Stop cluster: minikube stop"
echo "  • Delete cluster: minikube delete"
echo "  • View dashboard: minikube dashboard"
echo ""
