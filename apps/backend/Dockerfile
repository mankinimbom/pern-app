FROM node:18-alpine AS base

# Install security updates and required tools
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init curl openssl1.1-compat libc6-compat && \
    rm -rf /var/cache/apk/*

# Create app directory and user
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force && \
    npx prisma generate

# Copy source code and set ownership
COPY --chown=nodeuser:nodejs src ./src/
COPY --chown=nodeuser:nodejs healthcheck.js ./

# Create logs directory
RUN mkdir -p logs && chown nodeuser:nodejs logs

# Switch to non-root user
USER nodeuser

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/index.js"]
