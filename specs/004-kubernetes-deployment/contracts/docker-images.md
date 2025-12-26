# Docker Images Contract

**Feature**: 004-kubernetes-deployment
**Date**: 2025-12-24

## Overview

This contract defines the Docker image specifications for all three services in the AI Todo application.

## 1. Backend Image (`ai-todo-backend`)

**Base Image**: `python:3.13-slim`
**Exposed Ports**: `8000`
**Working Directory**: `/app`
**Entry Point**: `uvicorn main:app --host 0.0.0.0 --port 8000`

**Build Stages**:
1. **Builder**: Install dependencies via `uv sync`
2. **Runtime**: Copy virtual environment and application code

**Environment Variables Required**:
```bash
DATABASE_URL           # PostgreSQL connection string
OPENAI_API_KEY         # OpenAI API key
MCP_SERVER_URL         # MCP Server endpoint (http://ai-todo-mcp-service:8001)
BETTER_AUTH_SECRET     # Shared secret for JWT validation
BETTER_AUTH_ISSUER     # JWT issuer URL
BETTER_AUTH_JWKS_URL   # JWKS endpoint URL
```

**Health Endpoints**:
- `GET /health` → 200 OK (liveness)
- `GET /ready` → 200 OK if DB connected (readiness)

**Size Target**: < 200MB

---

## 2. MCP Server Image (`ai-todo-mcp`)

**Base Image**: `python:3.13-slim`
**Exposed Ports**: `8001`
**Working Directory**: `/app`
**Entry Point**: `python server.py`

**Build Stages**:
1. **Builder**: Install FastMCP dependencies
2. **Runtime**: Copy virtual environment and tools/server.py

**Environment Variables Required**:
```bash
DATABASE_URL    # PostgreSQL connection string
```

**Health Endpoints**:
- `GET /health` → 200 OK (if MCP server has health endpoint)

**Size Target**: < 150MB

---

## 3. Frontend Image (`ai-todo-frontend`)

**Base Image**: `node:20-alpine`
**Exposed Ports**: `3000`
**Working Directory**: `/app`
**Entry Point**: `npm start`

**Build Stages**:
1. **Dependencies**: `npm ci`
2. **Builder**: `npm run build` (Next.js production build)
3. **Runtime**: Copy `.next`, `public`, `node_modules`

**Environment Variables Required**:
```bash
NEXT_PUBLIC_API_URL         # Backend URL (http://minikube-ip:30081)
BETTER_AUTH_SECRET          # Shared secret
BETTER_AUTH_URL             # Auth base URL
DATABASE_URL                # PostgreSQL (for Better Auth)
```

**Health Endpoints**:
- `GET /` → 200 OK (Next.js root page)

**Size Target**: < 200MB

---

## Build Commands

```bash
# Backend
docker build -t ai-todo-backend:latest -f dockerfiles/backend.Dockerfile ./backend

# MCP Server
docker build -t ai-todo-mcp:latest -f dockerfiles/mcp.Dockerfile ./backend

# Frontend
docker build -t ai-todo-frontend:latest -f dockerfiles/frontend.Dockerfile ./frontend
```

## Image Loading (Minikube)

```bash
minikube image load ai-todo-backend:latest
minikube image load ai-todo-mcp:latest
minikube image load ai-todo-frontend:latest
```

## Validation

```bash
# Check image sizes
docker images | grep ai-todo

# Test image locally
docker run -p 8000:8000 -e DATABASE_URL="..." ai-todo-backend:latest
```
