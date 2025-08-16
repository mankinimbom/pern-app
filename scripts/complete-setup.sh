#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PERN Stack Production Deployment Setup${NC}"
echo -e "${BLUE}===========================================${NC}"

# Step 1: Create repositories
echo -e "\n${YELLOW}Step 1: Setting up repositories...${NC}"
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/mankinimbom/pern-app.git
fi

# Step 2: Create secrets
echo -e "\n${YELLOW}Step 2: Creating Kubernetes secrets...${NC}"
./scripts/create-secrets.sh

# Step 3: Install ArgoCD with Autopilot
echo -e "\n${YELLOW}Step 3: Installing ArgoCD...${NC}"
if ! command -v argocd-autopilot &> /dev/null; then
    echo -e "${RED}Installing ArgoCD Autopilot...${NC}"
    curl -sSL -o argocd-autopilot https://github.com/argoproj-labs/argocd-autopilot/releases/latest/download/argocd-autopilot-linux-amd64
    chmod +x argocd-autopilot
    sudo mv argocd-autopilot /usr/local/bin/
fi

./scripts/bootstrap-argocd.sh

# Step 4: Install Argo Rollouts
echo -e "\n${YELLOW}Step 4: Installing Argo Rollouts...${NC}"
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Step 5: Install Prometheus (optional)
echo -e "\n${YELLOW}Step 5: Installing Prometheus for monitoring...${NC}"
read -p "Do you want to install Prometheus for monitoring? (y/n): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
fi

# Step 6: Apply ArgoCD configurations
echo -e "\n${YELLOW}Step 6: Applying ArgoCD configurations...${NC}"
kubectl apply -f k8s/argocd/

# Step 7: Create initial commit
echo -e "\n${YELLOW}Step 7: Creating initial commit...${NC}"
git add .
git commit -m "Initial PERN stack setup with GitOps"
git push -u origin main

echo -e "\n${GREEN}✅ Setup completed successfully!${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "1. Access ArgoCD at: ${YELLOW}https://argo-ui.ankinimbom.com${NC}"
echo -e "2. Login with username: ${YELLOW}admin${NC}"
echo -e "3. Get password with: ${YELLOW}kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d${NC}"
echo -e "4. Create GitHub Personal Access Token for GitOps repo"
echo -e "5. Update image tags in GitOps repo to trigger first deployment"
echo -e "\n${GREEN}🎉 Your production-grade PERN stack CI/CD is ready!${NC}"
