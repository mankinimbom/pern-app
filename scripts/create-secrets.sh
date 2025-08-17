#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating Kubernetes secrets with proper security...${NC}"

# Check if required environment variables are set
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}ERROR: GITHUB_TOKEN environment variable is required for GitOps integration${NC}"
    echo -e "${YELLOW}Please set: export GITHUB_TOKEN=your_github_personal_access_token${NC}"
    echo -e "${YELLOW}Token needs permissions: repo, workflow, write:packages${NC}"
    exit 1
fi

if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}ERROR: GITHUB_USERNAME environment variable is required${NC}"
    echo -e "${YELLOW}Please set: export GITHUB_USERNAME=your_github_username${NC}"
    exit 1
fi

# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
REDIS_PASSWORD=$(openssl rand -base64 32)

# Create namespace if it doesn't exist
kubectl create namespace pern-app --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace pern-app-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# PostgreSQL credentials
echo -e "${YELLOW}Creating PostgreSQL secret...${NC}"
kubectl create secret generic postgresql-secret \
    --from-literal=username=postgres \
    --from-literal=password="$POSTGRES_PASSWORD" \
    --from-literal=database=pern_db \
    --namespace=pern-app \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgresql-secret \
    --from-literal=username=postgres \
    --from-literal=password="$POSTGRES_PASSWORD" \
    --from-literal=database=pern_db \
    --namespace=pern-app-staging \
    --dry-run=client -o yaml | kubectl apply -f -

# Backend secrets
DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgresql-service:5432/pern_db"
REDIS_URL="redis://:${REDIS_PASSWORD}@redis-service:6379"

kubectl create secret generic backend-secret \
    --from-literal=database-url="$DATABASE_URL" \
    --from-literal=jwt-secret="$JWT_SECRET" \
    --from-literal=redis-url="$REDIS_URL" \
    --namespace=pern-app \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic backend-secret \
    --from-literal=database-url="$DATABASE_URL" \
    --from-literal=jwt-secret="$JWT_SECRET" \
    --from-literal=redis-url="$REDIS_URL" \
    --namespace=pern-app-staging \
    --dry-run=client -o yaml | kubectl apply -f -

# GitHub Container Registry secret for ArgoCD Image Updater
echo -e "${YELLOW}Creating GitHub Container Registry secret...${NC}"

kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username="$GITHUB_USERNAME" \
    --docker-password="$GITHUB_TOKEN" \
    --namespace=argocd \
    --dry-run=client -o yaml | kubectl apply -f -

# GitOps repository access secret for ArgoCD Image Updater
echo -e "${BLUE}Creating GitOps repository access secret...${NC}"
kubectl create secret generic gitops-secret \
    --from-literal=username="$GITHUB_USERNAME" \
    --from-literal=password="$GITHUB_TOKEN" \
    --from-literal=url="https://github.com/mankinimbom/pern-gitops" \
    --namespace=argocd \
    --dry-run=client -o yaml | kubectl apply -f -

# Add labels to the GitOps secret for ArgoCD recognition
kubectl label secret gitops-secret \
    argocd.argoproj.io/secret-type=repository \
    --namespace=argocd \
    --overwrite=true || true

# TLS certificate secret (using cert-manager)
echo -e "${YELLOW}Creating certificate issuer...${NC}"
cat <<EOL | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@ankinimbom.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOL

# Save credentials to secure file (for reference only)
cat > .secrets-reference.txt << EOF
Generated at: $(date)
PostgreSQL Password: $POSTGRES_PASSWORD
JWT Secret: $JWT_SECRET
Redis Password: $REDIS_PASSWORD
Database URL: $DATABASE_URL

IMPORTANT: Store these securely and delete this file!
EOF

echo -e "${GREEN}All secrets created successfully!${NC}"
echo -e "${YELLOW}Credentials saved to .secrets-reference.txt (delete after storing securely)${NC}"
echo -e "${RED}Remember to add .secrets-reference.txt to .gitignore!${NC}"
