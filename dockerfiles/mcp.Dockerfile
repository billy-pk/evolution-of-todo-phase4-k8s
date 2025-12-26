# Multi-stage Dockerfile for AI Todo MCP Server (FastMCP)
# Base image: Python 3.13-slim
# Target size: < 150MB

# Stage 1: Builder - Install dependencies with uv
FROM python:3.13-slim AS builder

WORKDIR /build

# Install uv package manager
RUN pip install --no-cache-dir uv

# Copy dependency files from backend directory
COPY pyproject.toml uv.lock ./

# Install dependencies using uv (creates .venv in /build)
RUN uv sync --frozen --no-dev

# Stage 2: Runtime - Minimal production image
FROM python:3.13-slim

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /build/.venv /app/.venv

# Copy MCP server code and dependencies
COPY tools/ /app/tools/
COPY models.py db.py config.py /app/

# Set PATH to use virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Expose MCP server port
EXPOSE 8001

# Set environment variable for host binding
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8001

# Run MCP server using Python script that imports and runs uvicorn
CMD ["python", "-c", "from tools.server import mcp; import uvicorn; uvicorn.run(mcp.streamable_http_app(), host='0.0.0.0', port=8001)"]
