########################################
# Builder stage: install all deps + prisma generate
########################################
FROM node:18-alpine AS builder

ENV NODE_ENV=development
WORKDIR /app

# Install minimal tools for build steps
RUN apk update && apk upgrade && \
    apk add --no-cache curl git python3 make g++ && \
    rm -rf /var/cache/apk/*

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
# Runtime stage: small, production-only
########################################
FROM node:18-alpine AS runner

ENV NODE_ENV=production
WORKDIR /app

# Install runtime packages only (no openssl1.1-compat on Alpine 3.21)
RUN apk add --no-cache dumb-init libc6-compat && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copy built app with production node_modules from builder
COPY --from=builder --chown=nodeuser:nodejs /app /app

# Ensure logs dir exists
RUN mkdir -p logs && chown nodeuser:nodejs logs

USER nodeuser

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/index.js"]
