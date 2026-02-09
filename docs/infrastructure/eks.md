---
sidebar_position: 1
title: EKS
---

---
sidebar_position: 1
title: EKS
---

# EKS Infrastructure

## Overview

The PMS platform runs on Amazon Elastic Kubernetes Service (EKS), a managed Kubernetes service that eliminates the need to install, operate, and maintain your own Kubernetes control plane. EKS provides a highly available and secure Kubernetes environment with seamless integration with AWS services.

## Architecture

### Cluster Configuration

**Production Cluster**:
- **Name**: pms-prod
- **Region**: us-east-1
- **Kubernetes Version**: 1.28+
- **Control Plane**: Managed by AWS
- **High Availability**: Multi-AZ deployment across 3 availability zones

**Development Cluster**:
- **Name**: pms-dev
- **Region**: us-east-1
- **Kubernetes Version**: 1.28+
- **Control Plane**: Managed by AWS
- **High Availability**: Single AZ for cost optimization

### Node Groups

#### Production Node Groups

**Application Nodes**:
```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: pms-prod
  region: us-east-1
managedNodeGroups:
  - name: app-nodes
    instanceType: m6i.large
    minSize: 3
    maxSize: 20
    desiredCapacity: 6
    privateNetworking: true
    iam:
      withAddonPolicies:
        albIngress: true
        cloudWatch: true
        ebs: true
    labels:
      role: application
    taints: []
```

**Database Nodes** (Future):
```yaml
  - name: db-nodes
    instanceType: r6i.xlarge
    minSize: 2
    maxSize: 8
    desiredCapacity: 3
    privateNetworking: true
    iam:
      withAddonPolicies:
        ebs: true
    labels:
      role: database
    taints:
      - key: dedicated
        value: database
        effect: NoSchedule
```

#### Development Node Groups

**General Purpose Nodes**:
```yaml
managedNodeGroups:
  - name: dev-nodes
    instanceType: t3.medium
    minSize: 1
    maxSize: 5
    desiredCapacity: 2
    privateNetworking: true
    iam:
      withAddonPolicies:
        albIngress: true
        cloudWatch: true
        ebs: true
    labels:
      environment: development
```

## Networking

### VPC Configuration

**Production VPC**:
- **CIDR**: 10.0.0.0/16
- **Subnets**:
  - Public: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 (3 AZs)
  - Private: 10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24 (3 AZs)
- **NAT Gateways**: One per AZ for outbound traffic
- **Internet Gateway**: For public subnet internet access

**Security Groups**:

**EKS Control Plane SG**:
```
Inbound:
- 443 (HTTPS) from worker node SGs
- 10250 (kubelet) from worker node SGs

Outbound:
- All traffic to 0.0.0.0/0
```

**Worker Node SG**:
```
Inbound:
- All traffic from self (pod-to-pod)
- 22 (SSH) from bastion host
- 80, 443 from ALB SG
- 10250 from control plane

Outbound:
- All traffic to 0.0.0.0/0
```

### Network Policies

```yaml
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: pms-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Allow intra-namespace traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-intra-namespace
  namespace: pms-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}

---
# Allow API Gateway to access all services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-apigateway
  namespace: pms-prod
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: apigateway
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: portfolio
    ports:
    - protocol: TCP
      port: 8095
  - to:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: simulation
    ports:
    - protocol: TCP
      port: 8090
  # Add other service rules...
```

## Storage

### EBS Volumes

**Persistent Volume Claims**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: pms-prod
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 100Gi
```

**Storage Classes**:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
reclaimPolicy: Retain
allowVolumeExpansion: true
```

### EFS (Future)

For shared file storage across pods:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-12345678
```

## Identity and Access Management

### IAM Roles for Service Accounts (IRSA)

**API Gateway IRSA**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: apigateway-sa
  namespace: pms-prod
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/pms-apigateway-role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: apigateway-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
```

**IAM Policy for API Gateway**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:pms/prod/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/*"
    }
  ]
}
```

### RBAC Configuration

**Cluster Admin Role**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: admin@pms-platform.com
  apiGroup: rbac.authorization.k8s.io
```

**Namespace-specific Roles**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: pms-dev
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "jobs", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

## Monitoring and Logging

### CloudWatch Integration

**EKS Control Plane Logging**:
```bash
aws eks update-cluster-config \
  --region us-east-1 \
  --name pms-prod \
  --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
```

**Container Insights**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-info
  namespace: amazon-cloudwatch
data:
  cluster.name: pms-prod
  logs.region: us-east-1
  http.server: "on"
  http.port: "2020"
```

### Prometheus and Grafana

**Prometheus Installation**:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace
```

**Grafana Installation**:
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set adminPassword='admin'
```

## Auto Scaling

### Horizontal Pod Autoscaling

**API Gateway HPA**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apigateway-hpa
  namespace: pms-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apigateway
  minReplicas: 3
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
```

### Cluster Autoscaling

**Cluster Autoscaler Installation**:
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=pms-prod \
  --set awsRegion=us-east-1
```

## Backup and Disaster Recovery

### ETCD Backup

EKS automatically backs up the etcd cluster, but for additional security:

```bash
# Manual etcd backup
kubectl get secrets -n kube-system | grep etcd
```

### Application Data Backup

**PostgreSQL Backup**:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: pms-prod
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15-alpine
            command:
            - /bin/sh
            - -c
            - pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > /backup/backup-$(date +%Y%m%d-%H%M%S).sql.gz
            env:
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: host
            # ... other env vars
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
          volumes:
          - name: backup-volume
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

## Security

### Pod Security Standards

**Baseline Policy**:
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: baseline-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: MustRunAs
    ranges:
    - min: 1
      max: 65535
  fsGroup:
    rule: MustRunAs
    ranges:
    - min: 1
      max: 65535
  readOnlyRootFilesystem: true
  volumes:
  - configMap
  - downwardAPI
  - emptyDir
  - persistentVolumeClaim
  - secret
  - projected
```

### Image Security

**Container Image Scanning**:
```yaml
# Using Trivy
apiVersion: batch/v1
kind: Job
metadata:
  name: image-scan
spec:
  template:
    spec:
      containers:
      - name: trivy
        image: aquasecurity/trivy:latest
        command: ["trivy", "image", "nehanawork1/pms-apigateway:latest"]
      restartPolicy: Never
```

## Cost Optimization

### Spot Instances

**Spot Node Group**:
```yaml
managedNodeGroups:
  - name: spot-nodes
    instanceType: m6i.large
    minSize: 0
    maxSize: 10
    desiredCapacity: 2
    spot: true
    labels:
      lifecycle: spot
    taints:
      - key: spot
        value: "true"
        effect: NoSchedule
```

### Node Selector for Cost Optimization

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cost-optimized-app
spec:
  replicas: 3
  template:
    spec:
      nodeSelector:
        lifecycle: spot
      containers:
      - name: app
        image: nehanawork1/pms-apigateway:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

## Troubleshooting

### Common EKS Issues

#### Node Not Joining Cluster
```bash
# Check node status
kubectl get nodes

# Check kubelet logs
kubectl logs -n kube-system kubelet-pod-name

# Verify security groups
aws ec2 describe-security-groups --group-ids $NODE_SG_ID
```

#### Pod Scheduling Issues
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check node capacity
kubectl describe node <node-name>

# Check taints and tolerations
kubectl get nodes -o jsonpath='{.items[*].spec.taints}'
```

#### Network Connectivity
```bash
# Test pod-to-pod communication
kubectl run test --image=busybox --rm -i --restart=Never -- wget --timeout=5 -qO- http://apigateway:8088/actuator/health

# Check network policies
kubectl get networkpolicies -n pms-prod

# Verify VPC configuration
aws ec2 describe-vpcs --vpc-ids $VPC_ID
```

### Performance Issues

#### High CPU/Memory Usage
```bash
# Check resource usage
kubectl top pods -n pms-prod

# Check HPA status
kubectl get hpa -n pms-prod

# Review application metrics
kubectl logs -f deployment/prometheus-server -n monitoring
```

#### Slow API Responses
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN

# Review application logs
kubectl logs -f deployment/apigateway -n pms-prod

# Check database connections
kubectl exec -it postgres-pod -- psql -c "SELECT count(*) FROM pg_stat_activity;"
```

## Maintenance Procedures

### Cluster Updates

**Control Plane Update**:
```bash
aws eks update-cluster-version \
  --region us-east-1 \
  --name pms-prod \
  --kubernetes-version 1.29
```

**Node Group Update**:
```bash
aws eks update-nodegroup-version \
  --cluster-name pms-prod \
  --nodegroup-name app-nodes \
  --kubernetes-version 1.29
```

### Cluster Maintenance Windows

**Scheduled Maintenance**:
- **Weekly**: Security patches and minor updates
- **Monthly**: Major version updates and infrastructure changes
- **Quarterly**: Full cluster backup and disaster recovery testing

### Emergency Procedures

**Cluster Failure Response**:
1. Assess impact and notify stakeholders
2. Check AWS service health dashboard
3. Attempt cluster recovery or failover
4. Restore from backup if necessary
5. Update incident response documentation

This EKS infrastructure provides a robust, scalable, and secure foundation for the PMS platform, ensuring high availability and performance for production workloads.
