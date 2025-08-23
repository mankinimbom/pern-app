#!/bin/bash

# Manual build and push script for PERN Stack images
# Use this for local testing while GitHub Actions is being configured

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="ghcr.io"
USERNAME="mankinimbom"
BACKEND_IMAGE="$REGISTRY/$USERNAME/pern-backend"
FRONTEND_IMAGE="$REGISTRY/$USERNAME/pern-frontend"
TAG="standard-manual"

show_help() {
    cat << EOF
PERN Stack Manual Build Script

Usage: $0 [OPTIONS]

Options:
    -t, --tag           Image tag [default: standard-manual]
    -u, --username      GitHub username [default: mankinimbom]
    -b, --backend-only  Build only backend image
    -f, --frontend-only Build only frontend image
    --no-push          Build but don't push to registry
    -h, --help         Show this help message

Examples:
    $0                          # Build and push both images
    $0 --no-push               # Build locally only
    $0 -b -t latest            # Build only backend with latest tag
    $0 -f                      # Build only frontend

Note: Make sure you're logged into GitHub Container Registry:
    echo \$CR_PAT | docker login ghcr.io -u $USERNAME --password-stdin

EOF
}

# Parse arguments
BACKEND_ONLY=false
FRONTEND_ONLY=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            BACKEND_IMAGE="$REGISTRY/$USERNAME/pern-backend"
            FRONTEND_IMAGE="$REGISTRY/$USERNAME/pern-frontend"
            shift 2
            ;;
        -b|--backend-only)
            BACKEND_ONLY=true
            shift
            ;;
        -f|--frontend-only)
            FRONTEND_ONLY=true
            shift
            ;;
        --no-push)
            NO_PUSH=true
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

# Validate we're in the right directory
if [[ ! -d "apps/backend" ]] || [[ ! -d "apps/frontend" ]]; then
    echo -e "${RED}Error: Please run this script from the pern-app repository root${NC}"
    exit 1
fi

build_backend() {
    echo -e "${BLUE}🏗️ Building backend image...${NC}"
    docker build -t "${BACKEND_IMAGE}:${TAG}" apps/backend/
    echo -e "${GREEN}✅ Backend image built: ${BACKEND_IMAGE}:${TAG}${NC}"
    
    if [[ "$NO_PUSH" == "false" ]]; then
        echo -e "${BLUE}📤 Pushing backend image...${NC}"
        docker push "${BACKEND_IMAGE}:${TAG}"
        echo -e "${GREEN}✅ Backend image pushed${NC}"
    fi
}

build_frontend() {
    echo -e "${BLUE}🏗️ Building frontend image...${NC}"
    docker build -t "${FRONTEND_IMAGE}:${TAG}" apps/frontend/
    echo -e "${GREEN}✅ Frontend image built: ${FRONTEND_IMAGE}:${TAG}${NC}"
    
    if [[ "$NO_PUSH" == "false" ]]; then
        echo -e "${BLUE}📤 Pushing frontend image...${NC}"
        docker push "${FRONTEND_IMAGE}:${TAG}"
        echo -e "${GREEN}✅ Frontend image pushed${NC}"
    fi
}

# Check Docker login if we need to push
if [[ "$NO_PUSH" == "false" ]]; then
    echo -e "${BLUE}🔐 Checking Docker registry login...${NC}"
    if ! docker info | grep -q "Username.*$USERNAME"; then
        echo -e "${YELLOW}⚠️  Not logged into GitHub Container Registry${NC}"
        echo -e "${BLUE}Please login first:${NC}"
        echo -e "${YELLOW}echo \$CR_PAT | docker login ghcr.io -u $USERNAME --password-stdin${NC}"
        exit 1
    fi
fi

# Build images based on flags
if [[ "$BACKEND_ONLY" == "true" ]]; then
    build_backend
elif [[ "$FRONTEND_ONLY" == "true" ]]; then
    build_frontend
else
    build_backend
    build_frontend
fi

echo -e "${GREEN}🎉 Build complete!${NC}"

if [[ "$NO_PUSH" == "false" ]]; then
    echo -e "${BLUE}📋 Built and pushed images:${NC}"
    if [[ "$FRONTEND_ONLY" == "false" ]]; then
        echo "  - ${BACKEND_IMAGE}:${TAG}"
    fi
    if [[ "$BACKEND_ONLY" == "false" ]]; then
        echo "  - ${FRONTEND_IMAGE}:${TAG}"
    fi
else
    echo -e "${BLUE}📋 Built images locally:${NC}"
    if [[ "$FRONTEND_ONLY" == "false" ]]; then
        echo "  - ${BACKEND_IMAGE}:${TAG}"
    fi
    if [[ "$BACKEND_ONLY" == "false" ]]; then
        echo "  - ${FRONTEND_IMAGE}:${TAG}"
    fi
fi
