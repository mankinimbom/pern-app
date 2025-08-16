# PERN Stack Application - Production Ready

A full-stack **PostgreSQL, Express, React, Node.js** application with production-grade DevOps infrastructure using **GitOps**, **Kubernetes**, and **ArgoCD**.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   React Frontend │───▶│  Express Backend │───▶│   PostgreSQL    │
│   (Nginx)        │    │   (Node.js)      │    │   Database      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         │                        ▼                        │
         │              ┌─────────────────┐                │
         │              │     Redis       │                │
         │              │    (Cache)      │                │
         │              └─────────────────┘                │
         │                                                 │
         ▼                                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                          │
│  ┌───────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │    ArgoCD     │  │  Prometheus  │  │    Grafana         │  │
│  │   (GitOps)    │  │ (Monitoring) │  │ (Visualization)    │  │
│  └───────────────┘  └──────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Features

### Application Features
- **User Management**: CRUD operations with validation
- **Real-time Health Monitoring**: Live application status
- **Responsive UI**: Modern React interface with error boundaries
- **Form Validation**: Client and server-side validation
- **Search & Pagination**: Efficient data browsing

### DevOps Features
- **GitOps Deployment**: Automated deployments with ArgoCD
- **Canary Releases**: Progressive deployment strategy
- **Comprehensive Monitoring**: Prometheus + Grafana
- **Security Scanning**: Trivy vulnerability scanning
- **Multi-environment**: Staging and production environments
- **CI/CD Pipeline**: GitHub Actions with multiple stages

### Security Features
- **Secret Management**: Kubernetes secrets with encryption
- **Container Security**: Non-root containers, security scanning
- **Network Security**: Ingress with TLS termination
- **Rate Limiting**: Protection against abuse
- **Input Validation**: Comprehensive data validation

## 🛠️ Tech Stack

### Frontend
- **React 18** with hooks and context
- **Vite** for fast development and building
- **React Query** for data fetching and caching
- **React Hook Form** for form management
- **Axios** for HTTP client with interceptors
- **React Router** for navigation
- **Tailwind CSS** for styling

### Backend
- **Node.js** with Express framework
- **Prisma** ORM with PostgreSQL
- **Redis** for caching and sessions
- **Winston** for structured logging
- **Joi** for data validation
- **Helmet** for security headers
- **Rate limiting** and compression

### Infrastructure
- **Kubernetes** for container orchestration
- **ArgoCD** for GitOps deployments
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Nginx Ingress** for load balancing
- **Cert-Manager** for TLS certificates

### CI/CD
- **GitHub Actions** for automation
- **Docker** multi-stage builds
- **Trivy** security scanning
- **CodeQL** code analysis
- **Multi-platform** container builds

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+
- PostgreSQL 15+
- Redis 7+

### Local Development

1. **Clone the repository**:
   ```bash
   git clone https://github.com/mankinimbom/pern-app.git
   cd pern-app
   ```

2. **Setup Backend**:
   ```bash
   cd apps/backend
   cp .env.example .env
   npm install
   npx prisma migrate dev
   npx prisma db seed
   npm run dev
   ```

3. **Setup Frontend**:
   ```bash
   cd apps/frontend
   npm install
   npm run dev
   ```

4. **Access the application**:
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:3001

### Production Deployment

1. **Setup Kubernetes cluster** (e.g., using Rancher, GKE, EKS, AKS)

2. **Create secrets**:
   ```bash
   chmod +x scripts/create-secrets.sh
   ./scripts/create-secrets.sh
   ```

3. **Deploy ArgoCD**:
   ```bash
   chmod +x scripts/bootstrap-argocd.sh
   ./scripts/bootstrap-argocd.sh
   ```

4. **Complete setup**:
   ```bash
   chmod +x scripts/complete-setup.sh
   ./scripts/complete-setup.sh
   ```

## 📊 Monitoring & Observability

### Health Checks
- **Backend**: `/health` and `/ready` endpoints
- **Frontend**: `/health` endpoint via nginx
- **Database**: PostgreSQL health checks
- **Cache**: Redis connectivity checks

### Metrics Collection
- **Application metrics**: Response times, error rates
- **Infrastructure metrics**: CPU, memory, disk usage
- **Business metrics**: User registrations, API usage

### Alerting Rules
- High error rates (>5%)
- High response times (>1s)
- Pod crashes and restarts
- Resource usage thresholds
- Database connectivity issues

### Dashboards
- **Application Dashboard**: Request rates, errors, latency
- **Infrastructure Dashboard**: Pod health, resource usage
- **Business Dashboard**: User metrics, feature usage

## 🔐 Security

### Container Security
- Non-root user execution
- Minimal base images (Alpine Linux)
- Regular security updates
- Vulnerability scanning with Trivy

### Application Security
- Input validation and sanitization
- Rate limiting and CORS configuration
- Security headers with Helmet
- Secure session management

### Infrastructure Security
- TLS encryption for all traffic
- Network policies (when available)
- Secret management with Kubernetes
- Regular security scanning

## 🧪 Testing

### Backend Tests
```bash
cd apps/backend
npm test                    # Run all tests
npm run test:coverage      # Run with coverage
npm run test:watch         # Watch mode
```

### Frontend Tests
```bash
cd apps/frontend
npm test                    # Run all tests
npm run test:coverage      # Run with coverage
npm run test:ui            # Interactive UI
```

### End-to-End Tests
```bash
npm run test:e2e           # Cypress tests
```

## 📈 Performance

### Backend Optimizations
- Database connection pooling
- Redis caching layer
- Compression middleware
- Efficient database queries

### Frontend Optimizations
- Code splitting and lazy loading
- Image optimization
- Service worker caching
- Bundle size optimization

### Infrastructure Optimizations
- Horizontal pod autoscaling
- Resource requests and limits
- CDN integration
- Database read replicas

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
NODE_ENV=production
PORT=3001
DATABASE_URL=postgresql://...
JWT_SECRET=your-secret
REDIS_URL=redis://...
CORS_ORIGIN=https://your-domain.com
LOG_LEVEL=info
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000
```

#### Frontend
Configuration is handled through Vite build process and environment-specific builds.

### Kubernetes Configuration
- **Resources**: CPU and memory limits defined per environment
- **Replicas**: 3 for production, 2 for staging
- **Storage**: Persistent volumes for database and Redis
- **Networking**: Ingress with TLS termination

## 🚢 Deployment Strategy

### GitOps Workflow
1. **Code changes** pushed to `main` branch
2. **CI pipeline** runs tests and builds containers
3. **Security scanning** validates containers
4. **GitOps repository** updated with new image tags
5. **ArgoCD** detects changes and deploys automatically

### Environments
- **Development**: Local development with hot reload
- **Staging**: Pre-production testing environment
- **Production**: Live environment with monitoring

### Rollback Strategy
- **Automatic rollback** on failed health checks
- **Manual rollback** via ArgoCD UI or CLI
- **Database migrations** handled carefully with backups

## 📞 Support & Contributing

### Getting Help
- **Documentation**: Check this README and inline code comments
- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

### Development Workflow
1. **Feature development** on feature branches
2. **Pull requests** with automated testing
3. **Code review** process
4. **Merge to main** triggers deployment

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ArgoCD** team for GitOps excellence
- **Prisma** team for the amazing ORM
- **React** team for the frontend framework
- **Kubernetes** community for container orchestration
- Open source community for all the amazing tools

---

**Built with ❤️ for production workloads**
