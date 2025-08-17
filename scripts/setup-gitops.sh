#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up GitOps with ArgoCD for automatic image updates...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command_exists kubectl; then
    echo -e "${RED}ERROR: kubectl is not installed${NC}"
    exit 1
fi

if ! command_exists helm; then
    echo -e "${YELLOW}WARNING: helm is not installed. Installing ArgoCD via kubectl...${NC}"
fi

# Check if we're connected to a Kubernetes cluster
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Not connected to a Kubernetes cluster${NC}"
    echo "Please configure kubectl to connect to your cluster"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"

# Create ArgoCD namespace
echo -e "${BLUE}Creating ArgoCD namespace...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo -e "${BLUE}Installing ArgoCD...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo -e "${YELLOW}Waiting for ArgoCD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd

# Apply ArgoCD Image Updater configuration
echo -e "${BLUE}Deploying ArgoCD Image Updater...${NC}"
kubectl apply -f k8s/argocd/image-updater.yaml
kubectl apply -f k8s/argocd/image-updater-deployment.yaml

# Apply ArgoCD applications
echo -e "${BLUE}Applying ArgoCD applications...${NC}"
kubectl apply -f k8s/argocd/appproject.yaml
kubectl apply -f k8s/argocd/pern-app-application.yaml

# Wait for image updater to be ready
echo -e "${YELLOW}Waiting for ArgoCD Image Updater to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-image-updater -n argocd

# Get ArgoCD admin password
echo -e "${BLUE}Getting ArgoCD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}✓ GitOps setup completed successfully!${NC}"
echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}ArgoCD Setup Information:${NC}"
echo -e "${YELLOW}===========================================${NC}"
echo -e "Admin Username: ${GREEN}admin${NC}"
echo -e "Admin Password: ${GREEN}$ARGOCD_PASSWORD${NC}"
echo -e ""
echo -e "${BLUE}To access ArgoCD UI:${NC}"
echo -e "1. Port forward: ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "2. Open: ${YELLOW}https://localhost:8080${NC}"
echo -e "3. Accept the self-signed certificate"
echo -e ""
echo -e "${BLUE}GitOps Flow:${NC}"
echo -e "1. Push code → GitHub Actions builds images"
echo -e "2. ArgoCD Image Updater detects new images (every 2 minutes)"
echo -e "3. Image Updater updates GitOps repository"
echo -e "4. ArgoCD syncs changes to Kubernetes"
echo -e ""
echo -e "${GREEN}Image Update Strategy:${NC}"
echo -e "• ${YELLOW}Staging:${NC} Updates to latest tags automatically"
echo -e "• ${YELLOW}Production:${NC} Updates to digest-based tags (more stable)"
echo -e ""
echo -e "${RED}IMPORTANT: Don't forget to:${NC}"
echo -e "1. Set GITHUB_TOKEN and GITHUB_USERNAME environment variables"
echo -e "2. Run: ${YELLOW}./scripts/create-secrets.sh${NC}"
echo -e "3. Add GITOPS_TOKEN to GitHub repository secrets"

# Create helper scripts
cat > argocd-port-forward.sh << 'EOF'
#!/bin/bash
echo "Starting ArgoCD port forward..."
echo "ArgoCD will be available at: https://localhost:8080"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
kubectl port-forward svc/argocd-server -n argocd 8080:443
EOF

chmod +x argocd-port-forward.sh

cat > check-argocd-status.sh << 'EOF'
#!/bin/bash
echo "Checking ArgoCD status..."
echo ""
echo "ArgoCD Pods:"
kubectl get pods -n argocd
echo ""
echo "ArgoCD Applications:"
kubectl get applications -n argocd
echo ""
echo "ArgoCD Image Updater Status:"
kubectl get deployment argocd-image-updater -n argocd
echo ""
echo "Recent Image Updater Logs:"
kubectl logs -l app.kubernetes.io/name=argocd-image-updater -n argocd --tail=20
EOF

chmod +x check-argocd-status.sh

echo -e "${GREEN}Helper scripts created:${NC}"
echo -e "• ${YELLOW}./argocd-port-forward.sh${NC} - Access ArgoCD UI"
echo -e "• ${YELLOW}./check-argocd-status.sh${NC} - Check deployment status"
