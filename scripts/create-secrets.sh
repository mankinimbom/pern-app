#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating Kubernetes secrets...${NC}"

# Create namespace if it doesn't exist
kubectl create namespace pern-app --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# PostgreSQL credentials
echo -e "${YELLOW}Creating PostgreSQL secret...${NC}"
kubectl create secret generic postgresql-secret \
    --from-literal=username=postgres \
    --from-literal=password=$(openssl rand -base64 32) \
    --from-literal=database=pern_db \
    --namespace=pern-app \
    --dry-run=client -o yaml | kubectl apply -f -

# Backend database URL secret
DB_PASSWORD=$(kubectl get secret postgresql-secret -n pern-app -o jsonpath="{.data.password}" | base64 -d)
DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@postgresql-service:5432/pern_db"

kubectl create secret generic backend-secret \
    --from-literal=database-url="$DATABASE_URL" \
    --namespace=pern-app \
    --dry-run=client -o yaml | kubectl apply -f -

# GitHub Container Registry secret for ArgoCD Image Updater
echo -e "${YELLOW}Creating GitHub Container Registry secret...${NC}"
echo "Please enter your GitHub Personal Access Token with packages:read permission:"
read -s GITHUB_TOKEN

kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=mankinimbom \
    --docker-password="$GITHUB_TOKEN" \
    --namespace=argocd \
    --dry-run=client -o yaml | kubectl apply -f -

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
    email: your-email@ankinimbom.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOL

echo -e "${GREEN}All secrets created successfully!${NC}"
echo -e "${YELLOW}Make sure to update your-email@ankinimbom.com in the ClusterIssuer${NC}"
