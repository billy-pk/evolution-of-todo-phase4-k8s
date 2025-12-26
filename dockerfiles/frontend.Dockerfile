# Multi-stage Dockerfile for AI Todo Frontend (Next.js 16)
# Base image: Node.js 20-alpine
# Target size: < 200MB

# Stage 1: Dependencies - Install node_modules
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies with clean install
RUN npm ci --omit=dev

# Stage 2: Builder - Build Next.js application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application code
COPY . .

# Build Next.js application for production
RUN npm run build

# Stage 3: Runtime - Minimal production image
FROM node:20-alpine

WORKDIR /app

# Set Node environment to production
ENV NODE_ENV=production

# Copy built application from builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

# Expose frontend port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Run Next.js production server
CMD ["npm", "start"]
