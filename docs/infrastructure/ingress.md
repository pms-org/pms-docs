---
sidebar_position: 2
title: Ingress
---

# Ingress

---

sidebar_position: 2
title: Ingress

---

# Ingress

## Overview

Ingress is a Kubernetes resource that manages external access to services within a cluster, typically HTTP and HTTPS traffic. The PMS platform uses AWS Application Load Balancer (ALB) Ingress Controller to automatically provision and configure AWS ALBs based on Kubernetes Ingress resources.

## Architecture

### ALB Ingress Controller

The ALB Ingress Controller runs as a deployment in the `kube-system` namespace and watches for Ingress resources. When an Ingress is created, updated, or deleted, the controller automatically:

1. Creates or updates the corresponding ALB
2. Configures listeners and target groups
3. Sets up security groups and routing rules
4. Manages SSL certificates via AWS Certificate Manager

### Ingress Resource Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pms-ingress
  namespace: pms-prod
  annotations:
    # ALB-specific annotations
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "30"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
    # SSL/TLS configuration
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    # Security headers
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:us-east-1:123456789012:regional/webacl/pms-waf/12345678-1234-1234-1234-123456789012
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8088
          - path: /simulation
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8088
          - path: /ws
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8088
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

## Path-Based Routing

### API Gateway Routes

| Path            | Service    | Port | Description                  |
| --------------- | ---------- | ---- | ---------------------------- |
| `/api/*`        | apigateway | 8088 | REST API endpoints           |
| `/simulation/*` | apigateway | 8088 | Simulation service endpoints |
| `/ws/*`         | apigateway | 8088 | WebSocket connections        |
| `/`             | frontend   | 80   | React web application        |

### Routing Rules

**Exact Path Matching**:

```yaml
- path: /api/auth/login
  pathType: Exact
  backend:
    service:
      name: apigateway
      port:
        number: 8088
```

**Prefix Path Matching**:

```yaml
- path: /api/portfolio
  pathType: Prefix
  backend:
    service:
      name: apigateway
      port:
        number: 8088
```

**Regex Path Matching** (Advanced):

```yaml
- path: /api/v[0-9]+/.*
  pathType: ImplementationSpecific
  backend:
    service:
      name: apigateway
      port:
        number: 8088
```

## SSL/TLS Configuration

### Certificate Management

**AWS Certificate Manager Integration**:

```yaml
metadata:
  annotations:
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
    alb.ingress.kubernetes.io/ssl-redirect: "443"
```

**Automatic Certificate Renewal**:

- ACM automatically renews certificates 60 days before expiration
- ALB automatically picks up renewed certificates
- No manual intervention required

### SSL Policies

**Available SSL Policies**:

- `ELBSecurityPolicy-TLS-1-2-2017-01`: TLS 1.2+ with secure ciphers
- `ELBSecurityPolicy-TLS-1-1-2017-01`: TLS 1.1+ (legacy)
- `ELBSecurityPolicy-2016-08`: TLS 1.0+ (deprecated)

**Custom SSL Policy**:

```yaml
alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
```

## Health Checks

### Target Group Health Checks

**Default Configuration**:

```yaml
alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
alb.ingress.kubernetes.io/healthcheck-port: traffic-port
alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
alb.ingress.kubernetes.io/healthcheck-interval-seconds: "30"
alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
alb.ingress.kubernetes.io/healthy-threshold-count: "2"
alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
```

**Custom Health Check**:

```yaml
alb.ingress.kubernetes.io/healthcheck-path: /api/health
alb.ingress.kubernetes.io/healthcheck-port: "8088"
alb.ingress.kubernetes.io/healthcheck-success-codes: "200"
```

### Health Check Endpoints

All services must expose health check endpoints:

**Spring Boot Actuator**:

```java
@RestController
public class HealthController {

    @GetMapping("/actuator/health")
    public ResponseEntity<Health> health() {
        return ResponseEntity.ok(Health.up().build());
    }
}
```

## Load Balancing

### ALB Configuration

**Load Balancer Attributes**:

```yaml
alb.ingress.kubernetes.io/load-balancer-attributes: |
  idle_timeout.timeout_seconds=60
  routing.http.drop_invalid_header_fields.enabled=true
  routing.http.preserve_host_header.enabled=true
```

**Target Group Attributes**:

```yaml
alb.ingress.kubernetes.io/target-group-attributes: |
  deregistration_delay.timeout_seconds=30
  stickiness.enabled=true
  stickiness.type=lb_cookie
  stickiness.cookie_duration=86400
```

### Session Stickiness

**Application-Based Stickiness**:

```yaml
alb.ingress.kubernetes.io/target-group-attributes: |
  stickiness.enabled=true
  stickiness.type=app_cookie
  stickiness.cookie-name=AWSALB
  stickiness.cookie-duration=86400
```

## Security

### Web Application Firewall (WAF)

**WAF Integration**:

```yaml
alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:us-east-1:123456789012:regional/webacl/pms-waf/12345678-1234-1234-1234-123456789012
```

**WAF Rules**:

- SQL injection protection
- Cross-site scripting (XSS) prevention
- Rate limiting based on IP
- Geographic blocking
- Bot protection

### Security Headers

**ALB Security Headers**:

```yaml
alb.ingress.kubernetes.io/actions.ssl-redirect: |
  [{"type": "redirect", "redirectConfig": {"protocol": "HTTPS", "port": "443", "statusCode": "HTTP_301"}}]
```

**Application Security Headers**:

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.headers()
            .contentTypeOptions()
            .and()
            .httpStrictTransportSecurity(hstsConfig -> hstsConfig
                .maxAgeInSeconds(31536000)
                .includeSubdomains(true))
            .and()
            .frameOptions().deny()
            .xssProtection();
    }
}
```

## Monitoring and Logging

### Access Logs

**ALB Access Logs**:

```yaml
alb.ingress.kubernetes.io/load-balancer-attributes: |
  access_logs.s3.enabled=true
  access_logs.s3.bucket=pms-alb-logs
  access_logs.s3.prefix=prod
```

**Log Format**:

```
{
  "type": "http",
  "time": "2026-02-09T10:30:00Z",
  "elb": "app/pms-alb/1234567890123456",
  "client_ip": "192.168.1.1",
  "client_port": "12345",
  "target_ip": "10.0.10.100",
  "target_port": "8088",
  "request_processing_time": "0.001",
  "target_processing_time": "0.002",
  "response_processing_time": "0.000",
  "elb_status_code": "200",
  "target_status_code": "200",
  "received_bytes": "1234",
  "sent_bytes": "5678",
  "request": "GET /api/portfolio/list HTTP/1.1",
  "user_agent": "curl/7.68.0",
  "ssl_cipher": "ECDHE-RSA-AES128-GCM-SHA256",
  "ssl_protocol": "TLSv1.2",
  "target_group_arn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/pms-api/1234567890123456",
  "trace_id": "1-12345678-123456789012345678901234",
  "domain_name": "api.pms-platform.com",
  "chosen_cert_arn": "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
  "matched_rule_priority": "1",
  "request_creation_time": "2026-02-09T10:30:00Z",
  "actions_executed": "forward",
  "redirect_url": "-",
  "error_reason": "-",
  "target_port_list": "8088",
  "target_status_code_list": "200",
  "classification": "Allow",
  "classification_reason": "-"
}
```

### CloudWatch Metrics

**ALB Metrics**:

- `RequestCount`: Number of requests processed
- `HTTPCode_Target_2XX_Count`: Successful responses
- `HTTPCode_Target_4XX_Count`: Client errors
- `HTTPCode_Target_5XX_Count`: Server errors
- `TargetResponseTime`: Response time in seconds

**Custom Metrics**:

```yaml
# Prometheus metrics for ingress
alb.ingress.kubernetes.io/prometheus-rule: |
  groups:
  - name: alb-ingress
    rules:
    - alert: HighErrorRate
      expr: rate(alb_httpcode_target_5xx_count[5m]) / rate(alb_request_count[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate on ALB"
```

## Troubleshooting

### Common Issues

#### 404 Not Found

```bash
# Check ingress status
kubectl get ingress -n pms-prod

# Check ALB target groups
aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN

# Verify service endpoints
kubectl get endpoints -n pms-prod
```

#### SSL Certificate Issues

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn $CERT_ARN

# Verify certificate domains
aws acm list-certificates --include keyUsage=ENCRYPT_DECRYPT
```

#### Health Check Failures

```bash
# Check pod health
kubectl describe pod <pod-name> -n pms-prod

# Test health endpoint directly
kubectl exec -it <pod-name> -n pms-prod -- curl http://localhost:8088/actuator/health

# Check target group health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

### Debugging Commands

```bash
# Check ingress controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Describe ingress resource
kubectl describe ingress pms-ingress -n pms-prod

# Check ALB configuration
aws elbv2 describe-load-balancers --names pms-alb

# Test connectivity
curl -v https://api.pms-platform.com/api/health

# Check SSL certificate
openssl s_client -connect api.pms-platform.com:443 -servername api.pms-platform.com
```

## Performance Optimization

### Connection Draining

**Graceful Shutdown**:

```yaml
alb.ingress.kubernetes.io/target-group-attributes: |
  deregistration_delay.timeout_seconds=30
```

### Compression

**Gzip Compression**:

```yaml
alb.ingress.kubernetes.io/load-balancer-attributes: |
  routing.http.drop_invalid_header_fields.enabled=false
  routing.http.preserve_host_header.enabled=true
```

### Caching

**Static Content Caching**:

```yaml
alb.ingress.kubernetes.io/actions.response-add-header: |
  [{"type": "add-header", "addHeaderConfig": {"headerName": "Cache-Control", "headerValue": "max-age=3600"}}]
```

## Deployment Strategies

### Blue-Green Deployments

**Blue Ingress**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pms-ingress-blue
  annotations:
    alb.ingress.kubernetes.io/group.name: pms-platform
spec:
  rules:
    - host: blue.api.pms-platform.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: apigateway-blue
                port:
                  number: 8088
```

**Green Ingress**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pms-ingress-green
  annotations:
    alb.ingress.kubernetes.io/group.name: pms-platform
spec:
  rules:
    - host: green.api.pms-platform.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: apigateway-green
                port:
                  number: 8088
```

### Canary Deployments

**Traffic Splitting**:

```yaml
alb.ingress.kubernetes.io/actions.forward: |
  [{"type": "forward", "forwardConfig": {"targetGroups": [{"serviceName": "apigateway-stable", "servicePort": "8088", "weight": 90}, {"serviceName": "apigateway-canary", "servicePort": "8088", "weight": 10}]}}]
```

## Backup and Recovery

### Ingress Configuration Backup

**Automated Backup**:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ingress-backup
  namespace: pms-prod
spec:
  schedule: "0 */6 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: bitnami/kubectl:latest
              command:
                - /bin/sh
                - -c
                - kubectl get ingress -n pms-prod -o yaml > /backup/ingress-$(date +%Y%m%d-%H%M%S).yaml
              volumeMounts:
                - name: backup-volume
                  mountPath: /backup
          volumes:
            - name: backup-volume
              persistentVolumeClaim:
                claimName: backup-pvc
          serviceAccountName: backup-sa
          restartPolicy: OnFailure
```

### Disaster Recovery

**Ingress Failover**:

1. Create ingress in backup region
2. Update DNS to point to backup ALB
3. Verify traffic routing
4. Restore from backup configuration

This ingress configuration provides secure, scalable, and highly available external access to the PMS platform services.
