---
sidebar_position: 1
title: Deployment Guide
---

# Deployment Guide

This comprehensive guide covers the deployment, configuration, and management of the PMS (Portfolio Management System) platform across different environments.

## Overview

The PMS platform consists of multiple microservices deployed on AWS EKS with ArgoCD for continuous deployment. This guide provides step-by-step instructions for deploying the entire platform from infrastructure to applications.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Kubernetes Configuration](#kubernetes-configuration)
4. [ArgoCD Setup](#argocd-setup)
5. [Application Deployment](#application-deployment)
6. [Environment Configuration](#environment-configuration)
7. [Monitoring & Verification](#monitoring--verification)
8. [Rollback Procedures](#rollback-procedures)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

**Core Tools:**
```bash
# Kubernetes CLI
kubectl version --client

# Helm package manager
helm version

# AWS CLI
aws --version

# Terraform
terraform version
```

**Optional Tools:**
```bash
# ArgoCD CLI (for advanced operations)
argocd version

# Docker (for local development)
docker --version

# k9s (for cluster management)
k9s version
```

### AWS Permissions

The deployment requires the following AWS IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "rds:*",
        "secretsmanager:*",
        "kms:*",
        "s3:*",
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Environment Requirements

- **AWS Region**: us-east-1 (N. Virginia)
- **Kubernetes Version**: 1.28+
- **Node Types**: m5.large, m5.xlarge, m5.2xlarge
- **Storage**: gp3 EBS volumes
- **Networking**: VPC with public/private subnets

---

## Infrastructure Setup

### 1. Terraform Infrastructure Deployment

Navigate to the infrastructure directory and initialize Terraform:

```bash
cd pms-infra/terraform/environments/dev
terraform init
```

Deploy the complete infrastructure stack:

```bash
terraform plan
terraform apply -auto-approve
```

**What gets deployed:**
- EKS cluster with managed node groups
- VPC with public/private subnets
- RDS Aurora PostgreSQL database
- ElastiCache Redis cluster
- Application Load Balancer
- Security groups and IAM roles
- S3 buckets for backups and logs

### 2. AWS Secrets Manager Setup

Create application secrets:

```bash
# Auth service secrets
aws secretsmanager create-secret \
  --name "pms/dev/auth" \
  --description "JWT and authentication secrets" \
  --region us-east-1

# Database credentials
aws secretsmanager create-secret \
  --name "pms/dev/database" \
  --description "PostgreSQL connection details" \
  --region us-east-1

# Redis configuration
aws secretsmanager create-secret \
  --name "pms/dev/redis" \
  --description "Redis cluster configuration" \
  --region us-east-1
```

---

## Kubernetes Configuration

### 1. Cluster Access Setup

Update kubeconfig for cluster access:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name pms-dev
```

Verify cluster connectivity:

```bash
kubectl cluster-info
kubectl get nodes
```

### 2. Namespace Creation

Create required namespaces:

```bash
# Platform namespace
kubectl create namespace pms

# ArgoCD namespace
kubectl create namespace argocd

# Monitoring namespace
kubectl create namespace monitoring
```

### 3. External Secrets Operator

Install External Secrets Operator for AWS Secrets Manager integration:

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace
```

Apply the ClusterSecretStore configuration:

```bash
kubectl apply -f pms-infra/helper-yaml/cluster-secret-store.yaml
kubectl apply -f pms-infra/helper-yaml/external-secret.yaml
```

---

## ArgoCD Setup

### 1. ArgoCD Installation

Install ArgoCD using Kustomize:

```bash
cd pms-infra/argocd/install
kubectl apply -k .
```

### 2. ArgoCD Access

Expose ArgoCD server (temporary for setup):

```bash
kubectl patch svc argocd-server \
  -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

Get the ArgoCD server URL:

```bash
kubectl get svc argocd-server -n argocd
```

### 3. Initial Login

Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

Login using the CLI:

```bash
argocd login <argocd-server-url>
```

### 4. Project Creation

Create the PMS ArgoCD project:

```bash
kubectl apply -f pms-infra/argocd/projects/pms-project.yaml
```

---

## Application Deployment

### 1. Platform Chart Deployment

Deploy the complete PMS platform using the umbrella chart:

```bash
kubectl apply -f pms-infra/argocd/applications/pms-platform.yaml
```

This deploys:
- API Gateway service
- Authentication service
- Analytics service
- Portfolio service
- Simulation service
- Trade Capture service
- Leaderboard service
- RTTM service
- Validation service
- Frontend application

### 2. Deployment Verification

Monitor deployment progress:

```bash
# Check ArgoCD application status
argocd app get pms-platform

# Check pod status
kubectl get pods -n pms

# Check service endpoints
kubectl get svc -n pms
```

### 3. Database Initialization

Run database migration jobs:

```bash
kubectl apply -f pms-infra/k8s/jobs/database-init/
kubectl get jobs -n pms
```

---

## Environment Configuration

### Development Environment

**Scaling:** 1 replica per service
**Resources:** Minimal CPU/memory limits
**Features:** All services enabled, debug logging

### Testing Environment

**Scaling:** 2 replicas per service
**Resources:** Standard CPU/memory limits
**Features:** Full feature set, performance testing enabled

### Production Environment

**Scaling:** 3+ replicas per service (horizontal scaling)
**Resources:** High CPU/memory limits
**Features:** Optimized for performance, security hardening

### Environment Variables

Key configuration variables by environment:

```yaml
# Development
ENVIRONMENT: dev
LOG_LEVEL: DEBUG
REPLICAS: 1

# Production
ENVIRONMENT: prod
LOG_LEVEL: INFO
REPLICAS: 3
HPA_ENABLED: true
```

---

## Monitoring & Verification

### Health Checks

Verify all services are healthy:

```bash
# Check all pods are running
kubectl get pods -n pms

# Check service endpoints
kubectl get svc -n pms

# Test API connectivity
curl -H "Authorization: Bearer <token>" \
  https://api.pms-platform.com/api/health
```

### Application Metrics

Monitor key metrics:

```bash
# Check ArgoCD sync status
argocd app get pms-platform --hard-refresh

# View pod resource usage
kubectl top pods -n pms

# Check logs for errors
kubectl logs -f deployment/pms-analytics -n pms
```

### Database Connectivity

Verify database connections:

```bash
# Check database pod
kubectl get pods -n pms -l app=postgres

# Test database connectivity from application
kubectl exec -it deployment/pms-analytics -n pms -- \
  psql -h pms-database -U pms_user -d pms_db -c "SELECT 1;"
```

---

## Rollback Procedures

### ArgoCD Rollback

Rollback to previous version:

```bash
# List available revisions
argocd app history pms-platform

# Rollback to specific revision
argocd app rollback pms-platform <revision-id>
```

### Manual Rollback

For emergency rollbacks:

```bash
# Scale down current deployment
kubectl scale deployment pms-analytics \
  --replicas=0 -n pms

# Deploy previous version
kubectl set image deployment/pms-analytics \
  analytics=pms-analytics:v1.2.0 -n pms

# Scale back up
kubectl scale deployment pms-analytics \
  --replicas=3 -n pms
```

### Database Rollback

For schema changes:

```bash
# Use Flyway or Liquibase rollback
kubectl exec -it deployment/pms-analytics -n pms -- \
  ./flyway migrate -target=1.2.0
```

---

## Troubleshooting

### Common Issues

**Pods not starting:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n pms

# Check logs
kubectl logs <pod-name> -n pms

# Check resource constraints
kubectl describe node
```

**Service connectivity issues:**
```bash
# Check service discovery
kubectl get endpoints -n pms

# Test service DNS
kubectl run test --image=busybox --rm -it -- \
  nslookup pms-analytics.pms.svc.cluster.local
```

**Database connection issues:**
```bash
# Check database secrets
kubectl get externalsecret -n pms

# Verify secret values
kubectl get secret pms-database -n pms -o yaml
```

### Performance Issues

**High CPU/Memory usage:**
```bash
# Check resource usage
kubectl top pods -n pms

# Adjust resource limits
kubectl edit deployment <deployment-name> -n pms
```

**Slow response times:**
```bash
# Check network latency
kubectl run nettest --image=busybox --rm -it -- \
  ping pms-database.pms.svc.cluster.local

# Review application metrics
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
```

### Logs and Debugging

**Centralized logging:**
```bash
# View application logs
kubectl logs -f deployment/pms-analytics -n pms

# Search logs for errors
kubectl logs -f deployment/pms-analytics -n pms | grep ERROR
```

**Debug containers:**
```bash
# Start debug session
kubectl debug deployment/pms-analytics -n pms --image=busybox

# Access running container
kubectl exec -it deployment/pms-analytics -n pms -- /bin/bash
```

---

## Security Considerations

### Network Security

- All inter-service communication uses mTLS
- External access through ALB with WAF
- Security groups restrict traffic by port and source

### Secret Management

- All secrets stored in AWS Secrets Manager
- Automatic rotation enabled for database credentials
- No secrets in application code or configuration files

### Access Control

- RBAC enabled on Kubernetes cluster
- ArgoCD projects restrict deployment permissions
- Service accounts with minimal required permissions

---

## Maintenance Procedures

### Regular Updates

**Weekly:**
- Review ArgoCD application sync status
- Check resource utilization trends
- Update security patches

**Monthly:**
- Rotate database credentials
- Review and update IAM policies
- Update Kubernetes version (if available)

**Quarterly:**
- Full infrastructure audit
- Performance optimization review
- Disaster recovery testing

### Backup Strategy

**Database backups:**
- Automated daily backups to S3
- Point-in-time recovery available
- Cross-region replication for DR

**Application backups:**
- Helm chart versions tracked in Git
- Container images immutable and versioned
- Configuration as code in Git repository

---

## Support and Escalation

### Monitoring Alerts

Critical alerts are configured for:
- Service downtime (>5 minutes)
- High error rates (>5%)
- Resource exhaustion (>90% usage)
- Security incidents

### Escalation Matrix

1. **Level 1**: On-call engineer (15-minute response)
2. **Level 2**: Platform team lead (1-hour response)
3. **Level 3**: Engineering director (4-hour response)
4. **Level 4**: Executive team (business hours)

### Documentation Updates

Keep deployment documentation current:
- Update runbooks after changes
- Document incident resolutions
- Review procedures quarterly
