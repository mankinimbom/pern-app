########################################
# Builder stage: install all deps + prisma generate (Debian/glibc)
########################################
FROM node:20-bookworm-slim AS builder

ENV NODE_ENV=development
WORKDIR /app

# Install minimal tools for build steps
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
            ca-certificates curl git python3 make g++ build-essential openssl pkg-config \
            libc6 libssl3 wget \
        && \
        rm -rf /var/lib/apt/lists/*

# Copy manifests early to leverage Docker layer caching
COPY package*.json ./
COPY prisma ./prisma/

# Install all dependencies (including dev) for prisma generate
RUN npm ci && \
    npx prisma generate

# Copy application source
COPY src ./src/
COPY healthcheck.js ./

# Prune dev dependencies for production runtime
RUN npm prune --omit=dev && \
    npm cache clean --force

########################################
# Runtime stage: small, production-only (Debian/glibc)
########################################
FROM node:20-bookworm-slim AS runner

ENV NODE_ENV=production
WORKDIR /app

# Install runtime packages (openssl for Prisma, dumb-init)
RUN apt-get update && \
        apt-get install -y --no-install-recommends \
            ca-certificates dumb-init openssl libssl3 \
        && \
        rm -rf /var/lib/apt/lists/*

# Create non-root user
## Debian-based Node images provide a 'node' user already; reuse it

# Copy built app with production node_modules from builder
COPY --from=builder --chown=node:node /app /app

# Ensure logs dir exists
RUN mkdir -p logs && chown node:node logs

USER node

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/index.js"]
