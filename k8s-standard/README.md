# PERN Stack - Standard Kubernetes Deployment

This directory contains standard Kubernetes manifests for deploying the PERN (PostgreSQL, Express.js, React, Node.js) stack application without advanced deployment strategies like Argo Rollouts.

## 🏗️ Architecture

This deployment uses **standard Kubernetes resources**:
- **Deployments**: Regular Kubernetes Deployments for all components
- **Services**: ClusterIP services for internal communication  
- **PersistentVolumeClaims**: For database and cache persistence
- **Ingress**: For external access routing
- **Kustomize**: For environment-specific configurations

### Comparison with GitOps (Rollouts) Version

| Feature | Standard K8s (This) | GitOps Rollouts |
|---------|-------------------|-----------------|
| Deployment Strategy | Rolling Update | Canary/Blue-Green |
| Complexity | Simple | Advanced |
| Rollback | Manual/kubectl | Automated |
| Traffic Management | Basic | Advanced |
| Observability | Basic | Advanced |
| Learning Curve | Easy | Moderate |

## 📁 Structure

```
k8s-standard/
├── base/                           # Base Kubernetes manifests
│   ├── namespace.yaml             # Namespace definition
│   ├── backend-deployment.yaml    # Backend Deployment
│   ├── backend-service.yaml       # Backend Service  
│   ├── frontend-deployment.yaml   # Frontend Deployment
│   ├── frontend-service.yaml      # Frontend Service
│   ├── postgresql-deployment.yaml # Database Deployment
│   ├── postgresql-service.yaml    # Database Service + PVC
│   ├── redis-deployment.yaml      # Cache Deployment
│   ├── redis-service.yaml         # Cache Service + PVC
│   ├── ingress.yaml               # Ingress configuration
│   └── kustomization.yaml         # Base kustomization
│
├── overlays/                      # Environment-specific configs
│   ├── development/               # Development environment
│   │   ├── kustomization.yaml     # Dev kustomization
│   │   ├── replica-patch.yaml     # Replica overrides
│   │   └── env-patch.yaml         # Environment variables
│   └── staging/                   # Staging environment
│       ├── kustomization.yaml     # Staging kustomization
│       ├── replica-patch.yaml     # Replica overrides
│       └── env-patch.yaml         # Environment variables
```

## 🚀 Quick Deploy

### Using the Deploy Script

```bash
# Deploy to development (default)
./deploy-standard.sh

# Deploy to staging
./deploy-standard.sh -e staging

# Dry run (see what would be deployed)
./deploy-standard.sh -d -e staging

# Cleanup deployment
./deploy-standard.sh -c
```

### Manual Deployment with Kustomize

```bash
# Deploy to development
cd k8s-standard/overlays/development
kustomize build . | kubectl apply -f -

# Deploy to staging  
cd k8s-standard/overlays/staging
kustomize build . | kubectl apply -f -
```

### Manual Deployment with kubectl

```bash
# Apply base manifests
kubectl apply -k k8s-standard/overlays/development

# Or for staging
kubectl apply -k k8s-standard/overlays/staging
```

## 🔧 Configuration

### Environment Variables

**Development:**
- `NODE_ENV=development`
- `LOG_LEVEL=debug`
- Lower resource limits
- Single replicas

**Staging:**
- `NODE_ENV=staging`  
- `LOG_LEVEL=info`
- Higher resource limits
- Multiple replicas

### Resource Limits

| Component | Development | Staging |
|-----------|-------------|---------|
| Backend | 200m CPU, 256Mi RAM | 400m CPU, 512Mi RAM |
| Frontend | 100m CPU, 128Mi RAM | 200m CPU, 256Mi RAM |
| PostgreSQL | 500m CPU, 512Mi RAM | 500m CPU, 512Mi RAM |
| Redis | 250m CPU, 256Mi RAM | 250m CPU, 256Mi RAM |

## 🌐 Access

Once deployed, the application will be accessible via:

- **Development**: `http://pern-standard-dev.local`
- **Staging**: `http://pern-standard-staging.local`

> **Note**: Add these hosts to your `/etc/hosts` file pointing to your cluster's ingress IP

## 📊 Monitoring

### Check Deployment Status

```bash
# Check pods
kubectl get pods -n pern-standard

# Check services
kubectl get svc -n pern-standard

# Check ingress
kubectl get ingress -n pern-standard

# View logs
kubectl logs -f deployment/dev-backend -n pern-standard
```

### Health Checks

All components include:
- **Liveness Probes**: Restart containers if unhealthy
- **Readiness Probes**: Remove from service if not ready

## 🔄 CI/CD Pipeline

The GitHub Actions workflow (`build-push-standard.yml`) provides a complete CI/CD pipeline:

### **Automatic Triggers**
- **Push to main**: Builds, validates, and deploys to development → staging
- **Pull request**: Builds, validates, and runs security scans (no deployment)
- **Manual trigger**: Deploy to specific environment via GitHub Actions UI

### **Pipeline Stages**

1. **🏗️ Build Phase**
   - Build backend and frontend Docker images
   - Push to GitHub Container Registry with tags
   - Run in parallel for faster execution

2. **✅ Validation Phase**
   - Validate Kubernetes manifests with Kustomize
   - Security scan with Trivy (on PRs)
   - Upload manifests as artifacts

3. **🚀 Deployment Phase**
   - **Development**: Deploy with lower resources, single replicas
   - **Staging**: Deploy with higher resources, multiple replicas
   - Automatic image tag updates in manifests
   - Health checks and rollout verification

4. **🔄 Recovery Phase**
   - Automatic rollback on deployment failure
   - Notification of deployment status

### **Required Secrets**

Add these to your GitHub repository secrets:

| Secret | Description | Example |
|--------|-------------|---------|
| `GITOPS_TOKEN` | GitHub PAT with packages:write | `ghp_xxxx` |
| `KUBECONFIG` | Base64 encoded kubeconfig | `apiVersion: v1...` |

```bash
# Generate KUBECONFIG secret
cat ~/.kube/config | base64 -w 0
```

### Required Secrets

Add these secrets to your GitHub repository:

- `KUBECONFIG`: Base64 encoded kubeconfig file

```bash
# Generate the secret
cat ~/.kube/config | base64 -w 0
```

## 🚨 Troubleshooting

### Common Issues

**Pods stuck in Pending:**
```bash
# Check node resources
kubectl top nodes

# Check PV availability  
kubectl get pv
```

**Service not accessible:**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress rules
kubectl describe ingress pern-standard-ingress -n pern-standard
```

**Database connection issues:**
```bash
# Check PostgreSQL logs
kubectl logs deployment/dev-postgresql -n pern-standard

# Test database connectivity
kubectl exec -it deployment/dev-backend -n pern-standard -- nc -zv postgresql 5432
```

## 🧹 Cleanup

```bash
# Using the script
./deploy-standard.sh -c

# Manual cleanup
kubectl delete namespace pern-standard
```

## 📚 Learn More

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kustomize](https://kustomize.io/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## 🤝 Comparison with GitOps Version

This standard deployment provides a simpler alternative to the GitOps version with Argo Rollouts. Choose this approach when:

- ✅ You want simple, predictable deployments
- ✅ Your team is new to Kubernetes
- ✅ You don't need advanced deployment strategies  
- ✅ You prefer manual control over deployments

Choose the GitOps version when:
- ✅ You need canary/blue-green deployments
- ✅ You want automated rollbacks
- ✅ You need advanced traffic management
- ✅ You have complex deployment requirements
