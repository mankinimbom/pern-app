# GitOps with ArgoCD - Automatic Image Updates

This guide explains how your PERN application is configured for GitOps with ArgoCD to automatically detect and deploy new image updates.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │    │   GitHub Actions │    │  GitHub Container│
│   pushes code   │───▶│   CI/CD Pipeline │───▶│    Registry     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Kubernetes    │◀───│     ArgoCD       │◀───│ ArgoCD Image    │
│    Cluster      │    │   Applications   │    │    Updater      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  GitOps Repo     │◀───│  Detects new    │
                       │  (pern-gitops)   │    │    images       │
                       └──────────────────┘    └─────────────────┘
```

## How It Works

### 1. Image Build & Push
- GitHub Actions builds Docker images with multiple tags:
  - `latest` (main branch only)
  - `main-<sha>` (commit-specific)
  - `YYYYMMDD-HHmmss-<sha>` (timestamp-based)
  - Semantic version tags (if using releases)

### 2. Image Detection
- **ArgoCD Image Updater** polls GitHub Container Registry every 2 minutes
- Configured registries: `ghcr.io/mankinimbom/pern-frontend`, `ghcr.io/mankinimbom/pern-backend`
- Different strategies per environment:
  - **Staging**: `latest` tag updates (immediate deployment)
  - **Production**: `digest` strategy (stable, hash-based updates)

### 3. GitOps Update
- Image Updater detects new images
- Automatically updates `pern-gitops` repository
- Commits changes with structured commit messages
- Updates Kustomization files with new image tags

### 4. Application Sync
- ArgoCD monitors GitOps repository for changes
- Automatically syncs detected changes to Kubernetes
- Performs rolling updates with zero downtime
- Self-healing enabled (reverts manual changes)

## Configuration Files

### ArgoCD Applications
- **Production**: `/pern-gitops/apps/pern-app-production.yaml`
- **Staging**: `/pern-gitops/apps/pern-app-staging.yaml`

Key annotations for automatic updates:
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: |
    pern-backend=ghcr.io/mankinimbom/pern-backend,
    pern-frontend=ghcr.io/mankinimbom/pern-frontend
  argocd-image-updater.argoproj.io/update-strategy: digest
  argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/gitops-secret
```

### Image Updater Configuration
- **Config**: `/k8s/argocd/image-updater.yaml`
- **Deployment**: `/k8s/argocd/image-updater-deployment.yaml`

Key settings:
- Polling interval: 2 minutes
- Registry authentication via `ghcr-secret`
- Git write-back via `gitops-secret`

## Setup Instructions

### 1. Prerequisites
```bash
# Set required environment variables
export GITHUB_TOKEN="your_github_personal_access_token"
export GITHUB_USERNAME="your_github_username"

# Token permissions needed:
# - repo (full repository access)
# - workflow (update workflows)
# - write:packages (push to container registry)
```

### 2. Deploy ArgoCD & Image Updater
```bash
# Automated setup
chmod +x scripts/setup-gitops.sh
./scripts/setup-gitops.sh

# Create Kubernetes secrets
chmod +x scripts/create-secrets.sh
./scripts/create-secrets.sh
```

### 3. Access ArgoCD UI
```bash
# Start port forwarding
./argocd-port-forward.sh

# Open browser to: https://localhost:8080
# Username: admin
# Password: (displayed by setup script)
```

### 4. Verify Setup
```bash
# Check status
./check-argocd-status.sh

# Watch image updater logs
kubectl logs -f -l app.kubernetes.io/name=argocd-image-updater -n argocd
```

## Image Update Strategies

### Staging Environment
- **Strategy**: `latest` tag
- **Behavior**: Immediate deployment of any new push to main
- **Use Case**: Continuous integration testing
- **Risk**: Lower (staging environment)

### Production Environment
- **Strategy**: `digest` (SHA256 hash)
- **Behavior**: Updates when specific image digests change
- **Use Case**: Stable, predictable deployments
- **Risk**: Higher (production safety)

## Monitoring & Troubleshooting

### Check Image Update Status
```bash
# View ArgoCD applications
kubectl get applications -n argocd

# Check image updater logs
kubectl logs -l app.kubernetes.io/name=argocd-image-updater -n argocd --tail=50

# View application sync status
kubectl describe application pern-app-production -n argocd
```

### Common Issues

#### Image Updater Not Detecting Changes
1. Check registry credentials:
   ```bash
   kubectl get secret ghcr-secret -n argocd -o yaml
   ```

2. Verify image names match exactly:
   ```bash
   # Should match: ghcr.io/mankinimbom/pern-frontend
   # Should match: ghcr.io/mankinimbom/pern-backend
   ```

3. Check network connectivity from cluster to registry

#### GitOps Write-Back Failing
1. Verify GitOps secret:
   ```bash
   kubectl get secret gitops-secret -n argocd -o yaml
   ```

2. Check GitHub token permissions (repo, workflow, write:packages)

3. Ensure repository is accessible and not archived

#### Applications Not Syncing
1. Check sync policy:
   ```bash
   kubectl get application pern-app-production -n argocd -o yaml
   ```

2. Manual sync:
   ```bash
   # Via CLI (requires argocd CLI)
   argocd app sync pern-app-production
   ```

3. Check for resource conflicts or validation errors

## Advanced Configuration

### Custom Update Strategies
```yaml
# Update only specific tags
argocd-image-updater.argoproj.io/pern-backend.allow-tags: regexp:^v\d+\.\d+\.\d+$

# Ignore certain tags  
argocd-image-updater.argoproj.io/pern-frontend.ignore-tags: latest,main,dev

# Custom polling intervals
argocd-image-updater.argoproj.io/pern-backend.polling-interval: 5m
```

### Notification Setup
```yaml
# Slack notifications (requires ArgoCD notifications controller)
notifications.argoproj.io/subscribe.on-sync-succeeded.slack: pern-deployments
notifications.argoproj.io/subscribe.on-sync-failed.slack: pern-deployments
```

### Blue-Green Deployments
The backend uses Argo Rollouts for advanced deployment strategies:
- Canary deployments with traffic splitting
- Automatic rollback on failure
- Manual promotion gates

## Security Considerations

1. **Registry Access**: Limited to read-only for image pulling
2. **GitOps Repository**: Separate repository with controlled access
3. **Kubernetes RBAC**: Minimal permissions for image updater
4. **Secret Management**: Kubernetes secrets with proper labeling
5. **Image Verification**: Trivy security scanning in CI pipeline

## Performance Tuning

### Faster Updates
- Reduce polling interval (default: 2 minutes)
- Use webhooks instead of polling (advanced setup)
- Optimize Git operations with shallow clones

### Resource Optimization
- Adjust image updater resource requests/limits
- Configure appropriate sync windows
- Use application projects for multi-tenancy

## Backup & Recovery

### GitOps Repository
- Primary source of truth for deployments
- Regular automated backups recommended
- Version controlled with full history

### ArgoCD Configuration
```bash
# Export application definitions
kubectl get applications -n argocd -o yaml > argocd-applications-backup.yaml

# Export image updater config
kubectl get configmap argocd-image-updater-config -n argocd -o yaml > image-updater-config-backup.yaml
```

This GitOps setup provides:
- ✅ **Automated deployments** on every image update
- ✅ **Environment isolation** with different update strategies  
- ✅ **Audit trail** through Git history
- ✅ **Rollback capabilities** via ArgoCD
- ✅ **Security scanning** integration
- ✅ **Zero-downtime deployments** with Argo Rollouts
