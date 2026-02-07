#!/bin/bash

###############################################################################
# PMS Documentation Expansion Script
# Purpose: Automate the expansion of all service documentation files
# Usage: ./expand-docs.sh [service-name]
#        If no service-name provided, expands all services
###############################################################################

set -e

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docs/services"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Services to process
SERVICES=("analytics" "apigateway" "auth" "portfolio" "simulation")

# Document types
DOCS=("deployment" "security" "failure-modes")

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a file needs expansion
needs_expansion() {
    local file=$1
    local line_count=$(wc -l < "$file")
    
    # If file has less than 100 lines, it probably needs expansion
    if [ "$line_count" -lt 100 ]; then
        return 0
    fi
    return 1
}

# Function to backup a file
backup_file() {
    local file=$1
    local backup_dir="$(dirname "$file")/.backups"
    local filename=$(basename "$file")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    cp "$file" "$backup_dir/${filename}.${timestamp}.bak"
    log_info "Backed up to: $backup_dir/${filename}.${timestamp}.bak"
}

# Function to generate deployment documentation
generate_deployment_doc() {
    local service=$1
    local file=$2
    
    log_info "Generating deployment documentation for $service..."
    
    cat > "$file.tmp" << 'EOF'
---
sidebar_position: 5
title: Deployment
---

# {SERVICE_NAME} — Deployment

## Deployment Model

### Container Orchestration
- **Platform**: Kubernetes (Amazon EKS)
- **Deployment Type**: Deployment (StatefulSet not required)
- **Replicas**: Configurable (default: 2-3 for HA)
- **Update Strategy**: RollingUpdate
- **Pod Disruption Budget**: MinAvailable: 1

### Container Specifications

**Base Image**: `openjdk:17-slim` or `eclipse-temurin:17-jre`

**Resource Requests & Limits**:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

**Ports**:
- Container Port: Service-specific (check service overview)
- Protocol: TCP
- Health Check Port: Same as service port

---

## Kubernetes Deployment Manifest

### Complete Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service-name}
  namespace: pms
  labels:
    app: {service-name}
    version: v1
    component: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: {service-name}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: {service-name}
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      serviceAccountName: {service-name}-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: {service-name}
        image: {service-image}:latest
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        envFrom:
        - configMapRef:
            name: {service-name}-config
        - secretRef:
            name: {service-name}-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: http
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: http
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /actuator/health/liveness
            port: http
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
      volumes:
      - name: logs
        emptyDir: {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - {service-name}
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: {service-name}
  namespace: pms
  labels:
    app: {service-name}
spec:
  type: ClusterIP
  selector:
    app: {service-name}
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  sessionAffinity: None
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {service-name}-pdb
  namespace: pms
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: {service-name}
```

---

## Startup Dependencies

### Required Services
The service requires the following dependencies to be healthy before starting:

- **Database**: PostgreSQL must be reachable
- **Message Broker**: Kafka cluster must be available
- **Cache**: Redis (optional but recommended)

### Dependency Health Checks

Use **init containers** to wait for dependencies:

```yaml
initContainers:
- name: wait-for-db
  image: busybox:1.28
  command: ['sh', '-c', 'until nc -z postgres 5432; do echo waiting for db; sleep 2; done;']
- name: wait-for-kafka
  image: busybox:1.28
  command: ['sh', '-c', 'until nc -z kafka 9092; do echo waiting for kafka; sleep 2; done;']
```

---

## Health Checks

### Liveness Probe
**Purpose**: Detect if the application is alive and restart if frozen

**Endpoint**: `/actuator/health/liveness`

**Configuration**:
- Initial Delay: 60 seconds (allow JVM startup)
- Period: 10 seconds
- Timeout: 5 seconds
- Failure Threshold: 3 (restart after 30 seconds of failures)

**Checked Conditions**:
- JVM is responsive
- Main application thread is running

### Readiness Probe
**Purpose**: Determine if the service can accept traffic

**Endpoint**: `/actuator/health/readiness`

**Configuration**:
- Initial Delay: 30 seconds
- Period: 5 seconds
- Timeout: 3 seconds
- Failure Threshold: 3

**Checked Conditions**:
- Database connectivity
- Kafka broker reachability
- All critical dependencies available

### Startup Probe
**Purpose**: Handle slow-starting applications

**Configuration**:
- Initial Delay: 0 seconds
- Period: 10 seconds
- Failure Threshold: 30 (allows up to 5 minutes for startup)

---

## Scaling Behavior

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {service-name}-hpa
  namespace: pms
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {service-name}
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 30
      selectPolicy: Max
```

### Scaling Triggers
- **CPU Utilization**: > 70% triggers scale-up
- **Memory Utilization**: > 80% triggers scale-up
- **Custom Metrics**: Kafka lag, request rate (future)

### Scaling Limits
- **Minimum Replicas**: 2 (high availability)
- **Maximum Replicas**: 10 (cost control)
- **Scale-down Stabilization**: 5 minutes (avoid flapping)

---

## Ingress Configuration

### Via API Gateway
All external traffic routes through the API Gateway:

```
Client → Ingress Controller → API Gateway → Service
```

### Direct Ingress (Internal Only)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {service-name}
  namespace: pms
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - {service-name}.internal.pms-platform.com
    secretName: {service-name}-tls
  rules:
  - host: {service-name}.internal.pms-platform.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {service-name}
            port:
              number: 80
```

---

## Deployment Process

### CI/CD Pipeline

**1. Build Stage**:
```bash
# Build JAR
./mvnw clean package -DskipTests

# Build Docker image
docker build -t {service-image}:${VERSION} .

# Push to registry
docker push {service-image}:${VERSION}
```

**2. Deploy Stage**:
```bash
# Update image tag
kubectl set image deployment/{service-name} \
  {service-name}={service-image}:${VERSION} \
  -n pms

# Wait for rollout
kubectl rollout status deployment/{service-name} -n pms
```

**3. Verification Stage**:
```bash
# Check pod status
kubectl get pods -n pms -l app={service-name}

# Check health
kubectl exec -it <pod-name> -n pms -- curl localhost:8080/actuator/health

# Check logs
kubectl logs -f <pod-name> -n pms
```

### GitOps with ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {service-name}
  namespace: argocd
spec:
  project: pms
  source:
    repoURL: https://github.com/pms-org/pms-infra
    targetRevision: main
    path: k8s/{service-name}
  destination:
    server: https://kubernetes.default.svc
    namespace: pms
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## Rollback Procedures

### Manual Rollback

```bash
# View deployment history
kubectl rollout history deployment/{service-name} -n pms

# Rollback to previous version
kubectl rollout undo deployment/{service-name} -n pms

# Rollback to specific revision
kubectl rollout undo deployment/{service-name} --to-revision=3 -n pms
```

### Automated Rollback

Configure in ArgoCD or deployment pipeline to automatically rollback if:
- Readiness probe fails for > 2 minutes
- Error rate > 10%
- P95 latency > 2x baseline

---

## Monitoring & Observability

### Metrics Collection

**Prometheus ServiceMonitor**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {service-name}
  namespace: pms
spec:
  selector:
    matchLabels:
      app: {service-name}
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
    scrapeTimeout: 10s
```

### Logging

**Centralized Logging**: Logs shipped to ELK/CloudWatch

```yaml
containers:
- name: {service-name}
  env:
  - name: LOGGING_PATTERN_CONSOLE
    value: '{"timestamp":"%d{ISO8601}","level":"%p","thread":"%t","class":"%c{1}","message":"%m"}%n'
```

### Tracing

**Distributed Tracing**: Jaeger/AWS X-Ray integration

```yaml
env:
- name: SPRING_SLEUTH_ENABLED
  value: "true"
- name: SPRING_ZIPKIN_BASE_URL
  value: "http://zipkin:9411"
```

---

## Security Considerations

### Pod Security

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: false
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {service-name}-netpol
  namespace: pms
spec:
  podSelector:
    matchLabels:
      app: {service-name}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: pms
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
    - protocol: TCP
      port: 9092  # Kafka
    - protocol: TCP
      port: 6379  # Redis
```

---

## Disaster Recovery

### Backup Strategy
- Database backups: Daily automated backups
- Configuration backups: Stored in Git
- No stateful data in pods

### Recovery Procedures

**Complete Service Failure**:
```bash
# 1. Verify infrastructure
kubectl get nodes
kubectl get pvc -n pms

# 2. Redeploy service
kubectl apply -f k8s/{service-name}/

# 3. Verify recovery
kubectl get pods -n pms -l app={service-name}
kubectl logs -f <pod-name> -n pms
```

---

## Performance Optimization

### JVM Tuning

```yaml
env:
- name: JAVA_OPTS
  value: >-
    -Xms512m
    -Xmx1536m
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=200
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:HeapDumpPath=/var/log/app
```

### Connection Pooling

Optimize database and Kafka connection pools based on pod count and load.

---

## Troubleshooting

### Common Deployment Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| ImagePullBackOff | Cannot pull container image | Verify image registry credentials |
| CrashLoopBackOff | Pod repeatedly crashes | Check application logs |
| Pending | Pod stuck in Pending state | Check resource quotas and node capacity |
| Service Unavailable | 503 errors | Check readiness probe and dependencies |

### Debug Commands

```bash
# Describe pod
kubectl describe pod <pod-name> -n pms

# View logs
kubectl logs <pod-name> -n pms --tail=100

# Interactive shell
kubectl exec -it <pod-name> -n pms -- /bin/sh

# Port forward for local testing
kubectl port-forward <pod-name> 8080:8080 -n pms
```

---

## Checklist

### Pre-Deployment
- [ ] Docker image built and pushed
- [ ] ConfigMaps and Secrets created
- [ ] Database migrations applied
- [ ] Dependencies (Kafka, Redis, DB) verified
- [ ] Resource quotas checked

### Post-Deployment
- [ ] All pods running and ready
- [ ] Health endpoints returning 200
- [ ] Metrics being scraped
- [ ] Logs flowing to centralized logging
- [ ] No error spikes in monitoring
- [ ] Integration tests passed

EOF

    # Replace placeholders
    local service_upper=$(echo "$service" | tr '[:lower:]' '[:upper:]')
    sed -i "s/{SERVICE_NAME}/${service_upper}/g" "$file.tmp"
    sed -i "s/{service-name}/${service}/g" "$file.tmp"
    sed -i "s/{service-image}/pms-${service}/g" "$file.tmp"
    
    mv "$file.tmp" "$file"
    log_success "Generated deployment documentation for $service"
}

# Main execution
main() {
    local target_service=$1
    
    log_info "Starting documentation expansion process..."
    
    if [ -n "$target_service" ]; then
        SERVICES=("$target_service")
        log_info "Processing single service: $target_service"
    else
        log_info "Processing all services: ${SERVICES[*]}"
    fi
    
    for service in "${SERVICES[@]}"; do
        log_info "Processing service: $service"
        
        service_dir="$DOCS_DIR/$service"
        
        if [ ! -d "$service_dir" ]; then
            log_warning "Service directory not found: $service_dir"
            continue
        fi
        
        for doc_type in "${DOCS[@]}"; do
            doc_file="$service_dir/${doc_type}.md"
            
            if [ ! -f "$doc_file" ]; then
                log_warning "File not found: $doc_file"
                continue
            fi
            
            if needs_expansion "$doc_file"; then
                log_info "File needs expansion: $doc_file"
                backup_file "$doc_file"
                
                case "$doc_type" in
                    "deployment")
                        generate_deployment_doc "$service" "$doc_file"
                        ;;
                    "security")
                        log_info "Security doc expansion - to be implemented"
                        ;;
                    "failure-modes")
                        log_info "Failure modes doc expansion - to be implemented"
                        ;;
                esac
            else
                log_success "File already expanded: $doc_file"
            fi
        done
    done
    
    log_success "Documentation expansion complete!"
}

# Run main function
main "$@"
