#!/bin/bash

# PERN Stack Standard Kubernetes Deployment Script
# This script deploys the PERN application using standard Kubernetes resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="development"
NAMESPACE="pern-standard"
DRY_RUN=false
CLEANUP=false

# Help function
show_help() {
    cat << EOF
PERN Stack Standard K8s Deployment Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment    Environment to deploy (development|staging) [default: development]
    -n, --namespace      Kubernetes namespace [default: pern-standard]
    -d, --dry-run        Show what would be deployed without applying
    -c, --cleanup        Remove the deployment
    -h, --help          Show this help message

Examples:
    $0                                    # Deploy to development
    $0 -e staging                         # Deploy to staging
    $0 -d -e staging                      # Dry run for staging
    $0 -c                                 # Cleanup deployment

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "staging" ]]; then
    echo -e "${RED}Error: Environment must be 'development' or 'staging'${NC}"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if kustomize is available
if ! command -v kustomize &> /dev/null; then
    echo -e "${RED}Error: kustomize is not installed${NC}"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -d "k8s-standard/overlays/$ENVIRONMENT" ]]; then
    echo -e "${RED}Error: k8s-standard/overlays/$ENVIRONMENT directory not found${NC}"
    echo "Please run this script from the root of the pern-app repository"
    exit 1
fi

# Function to cleanup deployment
cleanup_deployment() {
    echo -e "${YELLOW}🧹 Cleaning up PERN Stack Standard deployment...${NC}"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo -e "${BLUE}Deleting resources in namespace $NAMESPACE...${NC}"
        kubectl delete namespace "$NAMESPACE" --timeout=60s
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    else
        echo -e "${YELLOW}Namespace $NAMESPACE does not exist${NC}"
    fi
}

# Function to deploy
deploy_application() {
    echo -e "${BLUE}🚀 Deploying PERN Stack Standard ($ENVIRONMENT)...${NC}"
    
    # Build the manifests
    echo -e "${BLUE}Building Kubernetes manifests...${NC}"
    cd "k8s-standard/overlays/$ENVIRONMENT"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}🔍 Dry run - showing manifests that would be applied:${NC}"
        kustomize build .
        return 0
    fi
    
    # Apply the manifests
    echo -e "${BLUE}Applying manifests...${NC}"
    kustomize build . | kubectl apply -f -
    
    # Wait for deployments to be ready
    echo -e "${BLUE}⏳ Waiting for deployments to be ready...${NC}"
    
    deployments=(
        "${ENVIRONMENT}-backend"
        "${ENVIRONMENT}-frontend" 
        "${ENVIRONMENT}-postgresql"
        "${ENVIRONMENT}-redis"
    )
    
    for deployment in "${deployments[@]}"; do
        echo -e "${BLUE}Waiting for $deployment...${NC}"
        kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $NAMESPACE
    done
    
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    
    # Show deployment status
    echo -e "${BLUE}📊 Deployment Status:${NC}"
    kubectl get pods -n $NAMESPACE -l environment=$ENVIRONMENT
    echo ""
    kubectl get services -n $NAMESPACE -l environment=$ENVIRONMENT  
    echo ""
    kubectl get ingress -n $NAMESPACE
}

# Main execution
if [[ "$CLEANUP" == "true" ]]; then
    cleanup_deployment
else
    deploy_application
fi

echo -e "${GREEN}🎉 Operation completed!${NC}"
