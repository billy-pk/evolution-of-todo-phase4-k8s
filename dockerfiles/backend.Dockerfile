# Multi-stage Dockerfile for AI Todo Backend (FastAPI + SQLModel)
# Base image: Python 3.13-slim
# Target size: < 200MB

# Stage 1: Builder - Install dependencies with uv
FROM python:3.13-slim AS builder

WORKDIR /build

# Install uv package manager
RUN pip install --no-cache-dir uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies using uv (creates .venv in /build)
RUN uv sync --frozen --no-dev

# Stage 2: Runtime - Minimal production image
FROM python:3.13-slim

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /build/.venv /app/.venv

# Copy application code
COPY . /app

# Set PATH to use virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Expose backend port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Run FastAPI with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
