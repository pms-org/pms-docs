---
sidebar_position: 7
title: Environments
---

---

sidebar_position: 7
title: Environments

---

# Environments

## Overview

The PMS platform operates across multiple environments to support the complete software development lifecycle, from development through production. Each environment is designed with specific purposes, security levels, and operational characteristics.

## Environment Architecture

### Development Environment (dev)

**Purpose**: Primary development and testing environment for feature development and integration testing.

**Key Characteristics**:

- **Kubernetes Namespace**: `pms-dev`
- **AWS Region**: us-east-1
- **EKS Cluster**: pms-dev
- **Database**: Shared PostgreSQL instance with isolated schemas
- **Access**: Full developer access with relaxed security policies
- **Data Persistence**: Ephemeral data, regular cleanup
- **Monitoring**: Basic logging and health checks

**Use Cases**:

- Feature development and debugging
- Integration testing with external services
- Performance testing with realistic data volumes
- API contract validation

### Testing Environment (test)

**Purpose**: Quality assurance and automated testing environment.

**Key Characteristics**:

- **Kubernetes Namespace**: `pms-test`
- **AWS Region**: us-east-1
- **EKS Cluster**: pms-dev (shared with dev)
- **Database**: Isolated PostgreSQL schemas with test data
- **Access**: Restricted to QA team and CI/CD pipelines
- **Data Management**: Automated test data seeding and cleanup
- **Monitoring**: Comprehensive test result aggregation

**Use Cases**:

- Automated regression testing
- Load and performance testing
- Security testing and vulnerability scanning
- User acceptance testing (UAT)

### Production Environment (prod)

**Purpose**: Live production environment serving end users and external systems.

**Key Characteristics**:

- **Kubernetes Namespace**: `pms-prod`
- **AWS Region**: us-east-1 (primary), us-east-2 (DR)
- **EKS Cluster**: pms-prod
- **Database**: Aurora PostgreSQL with multi-AZ deployment
- **Access**: Strictly controlled, principle of least privilege
- **Security**: Enhanced security groups, WAF, encryption at rest/transit
- **Monitoring**: Full observability stack with alerting
- **Backup**: Automated backups with cross-region replication

**Use Cases**:

- Live user traffic and transactions
- Production API integrations
- Real-time data processing and analytics

## Environment Configuration

### Infrastructure as Code

All environments are defined using Terraform and Helm charts for consistent deployment:

```hcl
# environments/dev/main.tf
module "eks" {
  source = "../../modules/eks"

  environment = "dev"
  cluster_name = "pms-dev"
  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
    }
  }
}
```

### Helm Values Override

Environment-specific configurations are managed through Helm value files:

```yaml
# environments/dev/values.yaml
global:
  environment: dev
  domain: dev.pms-platform.com

database:
  host: pms-db-dev.cluster.us-east-1.rds.amazonaws.com
  name: pms_db_dev

ingress:
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip

monitoring:
  enabled: true
  prometheus:
    retention: 7d
  grafana:
    adminPassword: ${GRAFANA_ADMIN_PASSWORD}
```

## Data Management

### Database Isolation

Each environment uses separate database schemas to prevent data contamination:

- **Development**: `pms_db_dev` - Frequent data resets
- **Testing**: `pms_db_test` - Controlled test data sets
- **Production**: `pms_db_prod` - Live production data with backups

### Test Data Strategy

**Development Environment**:

- Anonymous test data generation
- Realistic data volumes for performance testing
- Automated data refresh scripts

**Testing Environment**:

- Curated test datasets with known edge cases
- Performance testing data (large volumes)
- Compliance and security test scenarios

## Access Control

### Development Access

```yaml
# RBAC Configuration
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-access
  namespace: pms-dev
subjects:
  - kind: Group
    name: developers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
```

### Production Access

```yaml
# Restricted RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prod-access
  namespace: pms-prod
subjects:
  - kind: User
    name: platform-admin@pms.com
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
```

## Deployment Strategy

### CI/CD Pipelines

**Development**:

- Automatic deployment on merge to `develop` branch
- Rolling updates with zero downtime
- Automated smoke tests post-deployment

**Testing**:

- Deployment triggered by release candidates
- Comprehensive test suite execution
- Manual approval gates for production promotion

**Production**:

- Blue-green deployment strategy
- Automated canary releases
- Rollback automation within 5 minutes

### Deployment Commands

```bash
# Deploy to development
helm upgrade --install pms-platform ./charts/pms-platform \
  --namespace pms-dev \
  --values environments/dev/values.yaml \
  --wait

# Deploy to production with canary
helm upgrade --install pms-platform ./charts/pms-platform \
  --namespace pms-prod \
  --values environments/prod/values.yaml \
  --set canary.enabled=true \
  --set canary.weight=10
```

## Monitoring and Observability

### Development Monitoring

- Basic health checks and pod status
- Application logs aggregation
- Error rate monitoring

### Production Monitoring

- Full metrics collection (Prometheus)
- Distributed tracing (Jaeger)
- Log aggregation and analysis (ELK stack)
- Real-time alerting (PagerDuty integration)

### Key Metrics by Environment

| Metric              | Development | Testing       | Production |
| ------------------- | ----------- | ------------- | ---------- |
| Uptime SLA          | 99%         | 99.5%         | 99.9%      |
| Response Time       | &lt;500ms   | &lt;200ms     | &lt;100ms  |
| Error Rate          | &lt;5%      | &lt;1%        | &lt;0.1%   |
| Monitoring Coverage | Basic       | Comprehensive | Full       |

## Disaster Recovery

### Development DR

- **RTO**: 4 hours
- **RPO**: 1 day
- **Strategy**: Rebuild from infrastructure as code

### Production DR

- **RTO**: 1 hour
- **RPO**: 5 minutes
- **Strategy**: Multi-region active-passive with automated failover

### DR Testing

- Quarterly DR drills in testing environment
- Annual full-scale DR testing in production
- Automated failover validation

## Cost Optimization

### Development Costs

- Auto-scaling with scale-to-zero capabilities
- Spot instances for non-critical workloads
- Scheduled shutdown during off-hours

### Production Costs

- Reserved instances for predictable workloads
- Auto-scaling based on traffic patterns
- Cost allocation tags for chargeback

## Environment Promotion

### Branching Strategy

```
main (production)
├── release/v1.2.3 (testing)
└── develop (development)
    ├── feature/portfolio-enhancement
    └── feature/analytics-improvement
```

### Promotion Process

1. **Feature Development**: Work in feature branches
2. **Integration**: Merge to `develop` → auto-deploy to dev
3. **Testing**: Create release branch → deploy to test
4. **Production**: Merge release to `main` → deploy to prod

### Quality Gates

- **Development**: Unit tests, integration tests
- **Testing**: Full regression suite, performance tests, security scan
- **Production**: Manual approval, final smoke tests

## Troubleshooting

### Common Issues

#### Environment Connectivity

```bash
# Check cluster access
kubectl config current-context

# Verify namespace
kubectl get pods -n pms-dev

# Test database connectivity
kubectl run postgres-client --image=postgres:15-alpine \
  --rm -i --restart=Never -- psql -h $DB_HOST -U $DB_USER
```

#### Deployment Failures

```bash
# Check helm release status
helm list -n pms-dev

# View pod logs
kubectl logs -n pms-dev deployment/pms-apigateway

# Check events
kubectl get events -n pms-dev --sort-by=.metadata.creationTimestamp
```

#### Resource Issues

```bash
# Check node capacity
kubectl describe nodes

# Monitor resource usage
kubectl top pods -n pms-dev

# Scale deployment
kubectl scale deployment pms-portfolio --replicas=3 -n pms-dev
```
