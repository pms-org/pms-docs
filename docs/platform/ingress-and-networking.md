---
sidebar_position: 3
title: Ingress and Networking
---

# Ingress and Networking

## Overview

The PMS (Portfolio Management System) implements a production-grade ingress and networking architecture designed for high availability, security, and scalability. This document outlines the ingress controller selection, network topology, routing strategies, and security implementations.

## Architecture Overview

### Network Topology

PMS uses a layered network architecture that separates external traffic, internal service communication, and data plane networking:

```
┌─────────────────────────────────────────────────────────────┐
│                    External Layer                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                 AWS Application Load Balancer       │    │
│  │  • Single entry point for all traffic               │    │
│  │  • TLS termination with ACM certificates            │    │
│  │  • Path-based routing and WebSocket support         │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Ingress Layer                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            AWS Load Balancer Controller             │    │
│  │  • Kubernetes Ingress resource management           │    │
│  │  • ALB annotation processing                        │    │
│  │  • Target group and listener configuration          │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│               Service Mesh Layer                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            Kubernetes Services                       │    │
│  │  • ClusterIP for internal communication             │    │
│  │  • Service discovery via DNS                        │    │
│  │  • Load balancing across pods                        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Pod Network Layer                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            Container Network Interface              │    │
│  │  • VPC CNI plugin for EKS                           │    │
│  │  • Pod-to-pod communication                         │    │
│  │  • Network policies for security                    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Ingress Controller Selection

### Decision: AWS Load Balancer Controller

After evaluating multiple ingress solutions, PMS selected the **AWS Load Balancer Controller** for the following reasons:

#### Selection Criteria

- **Production Readiness**: Native AWS integration with enterprise support
- **WebSocket Support**: Native HTTP/1.1 upgrade handling for real-time features
- **Security**: Integration with AWS WAF, Shield, and ACM
- **Cost Efficiency**: Single ALB vs. multiple LoadBalancers
- **Operational Simplicity**: AWS-managed infrastructure, no pods to maintain
- **GitOps Compatibility**: Standard Kubernetes Ingress resources

#### Comparison Matrix

| Criteria                 | AWS ALB Controller  | NGINX Ingress + NLB | Traefik           |
| ------------------------ | ------------------- | ------------------- | ----------------- |
| **WebSocket Support**    | ✅ Native           | ⚠️ Manual config    | ✅ Native         |
| **AWS Integration**      | ✅ First-class      | ❌ Limited          | ❌ Limited        |
| **TLS Management**       | ✅ ACM integration  | ⚠️ cert-manager     | ⚠️ cert-manager   |
| **Cost**                 | 💰 $22-30/month     | 💰 $35-45/month     | 💰 $25-35/month   |
| **Operational Overhead** | ✅ AWS managed      | ❌ Pod management   | ❌ Pod management |
| **Security Features**    | ✅ WAF/Shield ready | ⚠️ Manual setup     | ⚠️ Manual setup   |

### Controller Installation

The AWS Load Balancer Controller is installed via Helm:

```yaml
# Helm values for ALB Controller
clusterName: pms-dev
region: us-east-1
vpcId: vpc-12345678
serviceAccount:
  create: true
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/alb-controller-role
```

#### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeTags",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
```

## Ingress Configuration

### Ingress Resource

PMS uses a single Ingress resource with comprehensive routing rules:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pms-platform-ingress
  namespace: pms
  annotations:
    # ALB Controller annotations
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip

    # SSL/TLS configuration
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"

    # WebSocket support
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=300
    alb.ingress.kubernetes.io/target-group-attributes: |
      stickiness.enabled=true,
      stickiness.lb_cookie.duration_seconds=86400

    # Health checks
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/success-codes: 200-299

    # Security
    alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:us-east-1:123456789012:regional/webacl/pms-waf/12345678-1234-1234-1234-123456789012

spec:
  rules:
    - host: pms.yourdomain.com
      http:
        paths:
          # Frontend - Angular SPA
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80

          # API Gateway routes
          - path: /api/auth
            pathType: Exact
            backend:
              service:
                name: apigateway
                port:
                  number: 8080

          - path: /api/portfolio
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8080

          - path: /api/analysis
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8080

          # WebSocket routes
          - path: /ws
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8080

          - path: /ws/updates
            pathType: Exact
            backend:
              service:
                name: apigateway
                port:
                  number: 8080

          - path: /ws/rttm
            pathType: Prefix
            backend:
              service:
                name: apigateway
                port:
                  number: 8080
```

### Routing Strategy

#### Path-Based Routing Rules

| Path Pattern       | Target Service | Port | Protocol  | Purpose                      |
| ------------------ | -------------- | ---- | --------- | ---------------------------- |
| `/`                | frontend       | 80   | HTTP      | Angular SPA (catch-all)      |
| `/api/auth/*`      | apigateway     | 8080 | HTTP      | Authentication endpoints     |
| `/api/portfolio/*` | apigateway     | 8080 | HTTP      | Portfolio management APIs    |
| `/api/analysis/*`  | apigateway     | 8080 | HTTP      | Analytics APIs               |
| `/ws/*`            | apigateway     | 8080 | WebSocket | Analytics WebSocket (SockJS) |
| `/ws/updates`      | apigateway     | 8080 | WebSocket | Leaderboard updates          |
| `/ws/rttm/*`       | apigateway     | 8080 | WebSocket | Real-time trade monitoring   |

#### Routing Order Importance

- **Specific paths first**: `/api/auth/*`, `/ws/updates` before generic patterns
- **WebSocket paths**: Must come before catch-all `/` to prevent conflicts
- **Frontend catch-all**: Last rule handles Angular client-side routing

## WebSocket Support

### WebSocket Architecture

PMS supports multiple WebSocket implementations for real-time features:

#### SockJS (Analytics)

- **Protocol**: SockJS over HTTP (fallback support)
- **Endpoint**: `/ws/*`
- **Features**: Automatic protocol negotiation, heartbeat
- **Browser Support**: Universal compatibility

#### Native WebSocket (RTTM, Leaderboard)

- **Protocol**: RFC 6455 WebSocket
- **Endpoints**: `/ws/rttm/*`, `/ws/updates`
- **Features**: Binary frames, custom subprotocols
- **Performance**: Lower latency than SockJS

### ALB WebSocket Configuration

```yaml
# WebSocket-specific ALB settings
alb.ingress.kubernetes.io/load-balancer-attributes: |
  idle_timeout.timeout_seconds=300

alb.ingress.kubernetes.io/target-group-attributes: |
  stickiness.enabled=true,
  stickiness.lb_cookie.duration_seconds=86400
```

#### Sticky Sessions

- **Purpose**: WebSocket connections must maintain pod affinity
- **Duration**: 24 hours (86400 seconds)
- **Mechanism**: ALB-generated cookies for session persistence
- **Impact**: Ensures WebSocket messages reach the correct pod

#### Connection Timeouts

- **Idle Timeout**: 300 seconds (5 minutes) for long-lived connections
- **Connection Upgrade**: Automatic HTTP/1.1 upgrade to WebSocket
- **Heartbeat**: Application-level keepalive messages

## TLS/SSL Configuration

### Certificate Management

#### AWS Certificate Manager (ACM)

- **Certificate Type**: RSA 2048-bit
- **Validation**: DNS validation (recommended)
- **Renewal**: Automatic (60 days before expiration)
- **Cost**: Free for public certificates

#### Certificate Configuration

```yaml
alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
alb.ingress.kubernetes.io/ssl-redirect: "443"
```

### SSL Policies

#### Security Headers

```nginx
# Security headers added via ALB
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

#### SSL Redirect

- **HTTP to HTTPS**: Automatic 301 redirect
- **HSTS**: Strict Transport Security enabled
- **Mixed Content**: Blocked by Content Security Policy

## Security Implementation

### AWS Web Application Firewall (WAF)

#### WAF Configuration

```yaml
alb.ingress.kubernetes.io/wafv2-acl-arn: "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/pms-waf/12345678-1234-1234-1234-123456789012"
```

#### WAF Rules

- **AWSManagedRulesCommonRuleSet**: Common web exploits
- **AWSManagedRulesSQLiRuleSet**: SQL injection protection
- **AWSManagedRulesKnownBadInputsRuleSet**: Malicious inputs
- **Rate-based rules**: DDoS protection (1000 requests/5 minutes)

### Network Policies

#### Kubernetes Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway-policy
  namespace: pms
spec:
  podSelector:
    matchLabels:
      app: apigateway
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx # ALB controller
      ports:
        - protocol: TCP
          port: 8080
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: auth
      ports:
        - protocol: TCP
          port: 8081
    - to:
        - podSelector:
            matchLabels:
              app: analytics
      ports:
        - protocol: TCP
          port: 8086
```

## Service Discovery

### Kubernetes DNS

#### Service Naming Convention

```
{service-name}.{namespace}.svc.cluster.local
```

#### Service Endpoints

- **PostgreSQL**: `postgres.pms.svc.cluster.local:5432`
- **Redis**: `redis.pms.svc.cluster.local:6379`
- **Kafka**: `kafka.pms.svc.cluster.local:9092`
- **API Gateway**: `apigateway.pms.svc.cluster.local:8080`

### Service Types

#### ClusterIP (Default)

- **Purpose**: Internal service communication
- **Accessibility**: Within cluster only
- **Load Balancing**: Round-robin across pods
- **DNS Resolution**: Automatic via kube-dns

#### External Access Patterns

- **Ingress**: HTTP/HTTPS traffic via ALB
- **LoadBalancer**: Direct external access (legacy, being phased out)
- **NodePort**: Development/testing access (not used in production)

## Monitoring and Observability

### ALB Metrics

#### CloudWatch Metrics

- **RequestCount**: Total requests per time period
- **HTTPCode_Target_2XX_Count**: Successful responses
- **HTTPCode_Target_4XX_Count**: Client errors
- **HTTPCode_Target_5XX_Count**: Server errors
- **TargetResponseTime**: Average response time

#### Custom Dashboards

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [
            "AWS/ApplicationELB",
            "RequestCount",
            "LoadBalancer",
            "app/pms-alb/1234567890123456"
          ]
        ],
        "title": "ALB Request Count"
      }
    }
  ]
}
```

### Health Checks

#### Target Group Health Checks

```yaml
alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
alb.ingress.kubernetes.io/healthcheck-port: traffic-port
alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
alb.ingress.kubernetes.io/success-codes: 200-299
alb.ingress.kubernetes.io/healthcheck-interval-seconds: 30
alb.ingress.kubernetes.io/healthy-threshold-count: 2
alb.ingress.kubernetes.io/unhealthy-threshold-count: 2
```

#### Pod Readiness Probes

```yaml
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3
```

## Performance Optimization

### Connection Pooling

#### Keep-Alive Connections

- **ALB**: Connection reuse enabled by default
- **Application**: HTTP client connection pooling
- **Database**: HikariCP connection pooling

### Caching Strategy

#### ALB Caching

- **Static Assets**: CloudFront CDN integration
- **API Responses**: Application-level caching
- **Session Data**: Redis for session persistence

### Scaling Considerations

#### Auto Scaling

- **ALB**: Automatically scales based on traffic
- **Target Groups**: Pod-level scaling via HPA
- **Pod Distribution**: Cross-AZ deployment for high availability

## Troubleshooting

### Common Issues

#### WebSocket Connection Failures

```bash
# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN

# Verify sticky sessions
aws elbv2 describe-target-group-attributes --target-group-arn $TARGET_GROUP_ARN

# Check pod logs
kubectl logs -f deployment/apigateway -n pms | grep websocket
```

#### SSL/TLS Issues

```bash
# Verify certificate
aws acm describe-certificate --certificate-arn $CERT_ARN

# Check SSL redirect
curl -I http://pms.yourdomain.com

# Test HTTPS
curl -I https://pms.yourdomain.com
```

#### Routing Problems

```bash
# Check ingress status
kubectl describe ingress pms-platform-ingress -n pms

# Verify ALB rules
aws elbv2 describe-rules --listener-arn $LISTENER_ARN

# Test path routing
curl -H "Host: pms.yourdomain.com" https://pms.yourdomain.com/api/health
```

### Debugging Tools

#### Network Debugging

```bash
# Test service DNS resolution
kubectl run test --image=busybox --rm -it -- nslookup apigateway.pms.svc.cluster.local

# Test connectivity
kubectl run test --image=busybox --rm -it -- telnet apigateway.pms.svc.cluster.local 8080

# Capture network traffic
kubectl run test --image=busybox --rm -it -- tcpdump -i eth0 port 8080
```

#### ALB Access Logs

```bash
# Enable ALB access logs
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn $ALB_ARN \
  --attributes Key=access_logs.s3.enabled,Value=true Key=access_logs.s3.bucket,Value=pms-alb-logs

# Query logs with Athena
SELECT * FROM alb_logs WHERE request_url LIKE '/ws/%' LIMIT 10;
```

## Cost Optimization

### ALB Cost Breakdown

- **Base Cost**: $0.0225 per hour
- **LCU Cost**: $0.008 per LCU per hour
- **Data Transfer**: $0.008 per GB

### Optimization Strategies

- **Connection Reuse**: Keep-alive connections reduce LCU usage
- **Caching**: CloudFront reduces ALB requests
- **Compression**: Enable gzip compression
- **Monitoring**: Track LCU usage and optimize accordingly

## Migration Strategy

### From Dual LoadBalancer to Single ALB

#### Phase 1: Infrastructure Setup

1. Install AWS Load Balancer Controller
2. Create ACM certificate
3. Configure WAF rules
4. Deploy ingress resource

#### Phase 2: Application Updates

1. Update frontend configuration URLs
2. Modify API Gateway routing rules
3. Test WebSocket connections
4. Validate authentication flows

#### Phase 3: Traffic Migration

1. Update DNS to point to ALB
2. Monitor traffic patterns
3. Gradually increase traffic
4. Remove old LoadBalancers

#### Phase 4: Cleanup

1. Delete unused LoadBalancers
2. Remove legacy configurations
3. Update documentation
4. Monitor cost savings

This ingress and networking architecture provides a robust, scalable, and secure foundation for the PMS platform while maintaining high availability and performance for real-time financial applications.
