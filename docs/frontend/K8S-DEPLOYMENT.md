# Kubernetes Deployment Guide

## Prerequisites
- Kubernetes cluster (v1.19+)
- kubectl configured
- Docker registry access
- Nginx Ingress Controller installed

## Quick Deploy

### 1. Build and Push Image
```bash
# Build for specific version
docker build -t your-registry/pms-frontend:v1.0.0 .

# Push to registry
docker push your-registry/pms-frontend:v1.0.0
```

### 2. Update k8s-deployment.yaml
Replace `pms-frontend:v1.0.0` with your registry path:
```yaml
image: your-registry/pms-frontend:v1.0.0
```

Update Ingress host:
```yaml
host: pms.example.com  # Your actual domain
```

### 3. Deploy to Kubernetes
```bash
kubectl apply -f k8s-deployment.yaml
```

### 4. Verify Deployment
```bash
# Check pods
kubectl get pods -l app=pms-frontend

# Check service
kubectl get svc pms-frontend-service

# Check ingress
kubectl get ingress pms-frontend-ingress

# View logs
kubectl logs -l app=pms-frontend --tail=50
```

## Configuration

### Backend Services
Ensure these services are running in your cluster:
- `analytics-service:8082`
- `leaderboard-service:8000`
- `rttm-service:8085`

### Health Checks
- Liveness: `/health` (checks every 10s)
- Readiness: `/health` (checks every 5s)

### Auto-scaling
HPA configured:
- Min replicas: 2
- Max replicas: 5
- CPU threshold: 70%
- Memory threshold: 80%

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod -l app=pms-frontend
```

### Check nginx config
```bash
kubectl exec -it <pod-name> -- cat /etc/nginx/nginx.conf
```

### Test health endpoint
```bash
kubectl exec -it <pod-name> -- wget -O- http://localhost/health
```

## Production Checklist
- [ ] Update image registry path
- [ ] Set proper domain in Ingress
- [ ] Configure TLS/SSL certificates
- [ ] Adjust resource limits based on load testing
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy
- [ ] Review security policies
