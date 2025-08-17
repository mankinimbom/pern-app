#!/bin/bash

# Complete GitOps Setup Guide for PERN Application
# Run this script after setting up your Kubernetes cluster

set -e

echo "🚀 PERN GitOps Setup - Complete Guide"
echo "===================================="
echo ""

echo "📋 Prerequisites Checklist:"
echo "▢ Kubernetes cluster running"
echo "▢ kubectl configured and connected"
echo "▢ GitHub Personal Access Token created"
echo "▢ Docker images building successfully in CI/CD"
echo ""

read -p "Have you completed all prerequisites? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please complete prerequisites first"
    exit 1
fi

echo ""
echo "🔧 Required GitHub Repository Secrets:"
echo "======================================="
echo "1. GITOPS_TOKEN - GitHub Personal Access Token with permissions:"
echo "   - repo (Full repository access)"
echo "   - workflow (Update workflows)"
echo "   - write:packages (Push to container registry)"
echo ""
echo "2. CODECOV_TOKEN (Optional) - For test coverage reporting"
echo ""

read -p "Have you added GITOPS_TOKEN to GitHub repository secrets? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please add GITOPS_TOKEN to GitHub repository secrets first"
    echo "Go to: Settings > Secrets and variables > Actions"
    exit 1
fi

echo ""
echo "🌱 Setting up environment variables..."
if [ -z "$GITHUB_TOKEN" ]; then
    read -p "Enter your GitHub Personal Access Token: " -s GITHUB_TOKEN
    echo ""
    export GITHUB_TOKEN
fi

if [ -z "$GITHUB_USERNAME" ]; then
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    export GITHUB_USERNAME
fi

echo ""
echo "🏗️  Setup Steps:"
echo "================"
echo ""

echo "Step 1/4: 🔐 Creating Kubernetes secrets..."
if ./scripts/create-secrets.sh; then
    echo "✅ Kubernetes secrets created successfully"
else
    echo "❌ Failed to create secrets"
    exit 1
fi

echo ""
echo "Step 2/4: 🎯 Setting up ArgoCD and Image Updater..."
if ./scripts/setup-gitops.sh; then
    echo "✅ ArgoCD setup completed successfully"
else
    echo "❌ Failed to setup ArgoCD"
    exit 1
fi

echo ""
echo "Step 3/4: 📁 Committing GitOps repository changes..."
cd ../pern-gitops
git add .
git commit -m "feat: enhance ArgoCD applications with automatic image updates

- Add image updater annotations for staging and production
- Configure digest-based updates for production stability  
- Enable latest tag updates for staging environment
- Add notification subscriptions for deployment events
- Optimize sync policies with server-side apply
- Configure revision history and auto-healing"

if git push origin main; then
    echo "✅ GitOps repository updated successfully"
else
    echo "❌ Failed to push GitOps changes"
    exit 1
fi

cd ../pern-app

echo ""
echo "Step 4/4: 🧪 Testing the setup..."
echo ""
echo "Checking ArgoCD applications..."
kubectl get applications -n argocd

echo ""
echo "Checking ArgoCD Image Updater..."
kubectl get deployment argocd-image-updater -n argocd

echo ""
echo "🎉 GitOps Setup Complete!"
echo "========================="
echo ""
echo "🌟 What happens next:"
echo "1. Push code changes to trigger CI/CD"
echo "2. GitHub Actions builds and pushes new images"
echo "3. ArgoCD Image Updater detects changes (every 2 minutes)"
echo "4. Images are automatically updated in pern-gitops repository"
echo "5. ArgoCD syncs changes to your Kubernetes cluster"
echo ""
echo "📊 Access ArgoCD UI:"
echo "Run: ./argocd-port-forward.sh"
echo "Open: https://localhost:8080"
echo ""
echo "🔍 Monitor deployments:"
echo "Run: ./check-argocd-status.sh"
echo ""
echo "📚 Full documentation: docs/gitops-setup.md"
echo ""
echo "🚀 Your PERN application now has full GitOps automation!"
echo "   Push code → Auto-build → Auto-deploy → Zero downtime! 🎯"
