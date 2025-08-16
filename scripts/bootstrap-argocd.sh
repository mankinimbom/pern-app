#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting ArgoCD Autopilot Bootstrap...${NC}"

# Check if required tools are installed
command -v argocd-autopilot >/dev/null 2>&1 || { 
    echo -e "${RED}argocd-autopilot is required but not installed. Install it first.${NC}" >&2
    exit 1
}

command -v kubectl >/dev/null 2>&1 || { 
    echo -e "${RED}kubectl is required but not installed. Install it first.${NC}" >&2
    exit 1
}

# Set variables
REPO_URL="https://github.com/mankinimbom/pern-gitops"
CLUSTER_NAME="rancher-cluster"
NAMESPACE="argocd"

echo -e "${YELLOW}Bootstrapping ArgoCD with Autopilot...${NC}"

# Bootstrap ArgoCD
argocd-autopilot repo bootstrap \
    --repo $REPO_URL \
    --cluster $CLUSTER_NAME \
    --namespace $NAMESPACE

echo -e "${GREEN}ArgoCD Autopilot bootstrap completed!${NC}"

# Wait for ArgoCD to be ready
echo -e "${YELLOW}Waiting for ArgoCD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $NAMESPACE

# Get ArgoCD admin password
echo -e "${GREEN}ArgoCD is ready!${NC}"
echo -e "${YELLOW}Admin password:${NC}"
kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

echo -e "${GREEN}Access ArgoCD at: https://argo-ui.ankinimbom.com${NC}"
