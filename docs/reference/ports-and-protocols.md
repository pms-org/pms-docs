---
sidebar_position: 2
title: Ports and Protocols
---

---
sidebar_position: 2
title: Ports and Protocols
---

# Ports and Protocols Reference

## Overview

This document outlines the network ports, protocols, and communication patterns used across the PMS platform components. Understanding these is crucial for network configuration, security policies, and troubleshooting connectivity issues.

## Service Ports

### Internal Service Ports

| Service | Port | Protocol | Description | Health Check |
|---------|------|----------|-------------|--------------|
| **API Gateway** | 8088 | HTTP/HTTPS | Main API entry point, routes to backend services | `/actuator/health` |
| **Auth Service** | 8081 | HTTP/HTTPS | User authentication and token management | `/actuator/health` |
| **Portfolio Service** | 8095 | HTTP/HTTPS | Portfolio CRUD operations | `/actuator/health` |
| **Simulation Service** | 8090 | HTTP/HTTPS | Portfolio simulation and modeling | `/actuator/health` |
| **Analytics Service** | 8085 | HTTP/HTTPS | Risk analysis and performance metrics | `/actuator/health` |
| **Trade Capture Service** | 8080 | HTTP/HTTPS | Trade recording and audit trails | `/actuator/health` |
| **Leaderboard Service** | 8075 | HTTP/HTTPS | Performance rankings and competitions | `/actuator/health` |
| **RTTM Service** | 8070 | HTTP/HTTPS | Real-time market data and trade monitoring | `/actuator/health` |
| **Validation Service** | 8065 | HTTP/HTTPS | Data validation and compliance checking | `/actuator/health` |
| **Transactional Service** | 8060 | HTTP/HTTPS | Transaction processing and settlement | `/actuator/health` |
| **Frontend** | 80 | HTTP/HTTPS | React web application | `/` (static file) |

### External Load Balancer Ports

| Component | External Port | Internal Port | Protocol | Description |
|-----------|---------------|---------------|----------|-------------|
| **Application Load Balancer** | 80 | - | HTTP | External HTTP traffic |
| **Application Load Balancer** | 443 | - | HTTPS | External HTTPS traffic (SSL termination) |
| **Network Load Balancer** | 80 | 8088 | HTTP | Direct API Gateway access (if needed) |

## Communication Protocols

### HTTP/HTTPS Protocols

#### REST API Communication
- **Protocol**: HTTP/1.1, HTTP/2
- **Security**: TLS 1.3 (recommended), TLS 1.2 (minimum)
- **Authentication**: JWT Bearer tokens, Basic Auth (service-to-service)
- **Content-Type**: `application/json`
- **Compression**: gzip, deflate

#### WebSocket Communication
- **Protocol**: WebSocket (RFC 6455)
- **Security**: WSS (WebSocket Secure)
- **Authentication**: JWT token in query parameters
- **Heartbeat**: Ping/Pong frames every 30 seconds
- **Message Format**: JSON

### Database Protocols

#### PostgreSQL
- **Port**: 5432
- **Protocol**: PostgreSQL wire protocol
- **Security**: SSL/TLS encryption
- **Authentication**: SCRAM-SHA-256, MD5 (legacy)
- **Connection Pooling**: HikariCP (application side)

#### Redis (Future/Caching)
- **Port**: 6379
- **Protocol**: RESP (Redis Serialization Protocol)
- **Security**: TLS encryption (if enabled)
- **Authentication**: Password-based
- **Persistence**: RDB snapshots, AOF logs

### Message Queue Protocols (Future)

#### Apache Kafka
- **Port**: 9092 (plaintext), 9093 (SSL)
- **Protocol**: Kafka wire protocol
- **Security**: SASL authentication, SSL encryption
- **Serialization**: Avro, JSON, Protobuf

## Network Architecture

### Kubernetes Networking

#### Service Communication
```yaml
# Internal service discovery
apiVersion: v1
kind: Service
metadata:
  name: portfolio-service
  namespace: pms-prod
spec:
  selector:
    app: portfolio
  ports:
  - name: http
    port: 8095
    targetPort: 8095
    protocol: TCP
  type: ClusterIP
```

#### Ingress Configuration
```yaml
# External traffic routing
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pms-ingress
  namespace: pms-prod
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
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
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

### AWS Network Configuration

#### Security Groups

**ALB Security Group**:
```
Inbound:
- 80 (HTTP) from 0.0.0.0/0
- 443 (HTTPS) from 0.0.0.0/0

Outbound:
- All traffic to VPC subnets
```

**EKS Node Security Group**:
```
Inbound:
- 80, 443 from ALB security group
- 22 (SSH) from bastion host
- All traffic from self (pod-to-pod)

Outbound:
- All traffic to 0.0.0.0/0
```

**RDS Security Group**:
```
Inbound:
- 5432 (PostgreSQL) from EKS node security group

Outbound:
- All traffic to 0.0.0.0/0
```

## Protocol-Specific Configurations

### HTTP/2 Support

The platform supports HTTP/2 for improved performance:

```nginx
# ALB Configuration
server {
    listen 443 ssl http2;
    server_name api.pms-platform.com;

    # SSL Configuration
    ssl_certificate /etc/ssl/certs/pms.crt;
    ssl_certificate_key /etc/ssl/private/pms.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Upstream to API Gateway
    location / {
        proxy_pass http://apigateway:8088;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### WebSocket Configuration

```javascript
// Client-side WebSocket connection
const wsUrl = `wss://api.pms-platform.com/ws/portfolio/${portfolioId}?token=${jwtToken}`;

const ws = new WebSocket(wsUrl);

// Connection handling
ws.onopen = () => {
  console.log('WebSocket connected');
  // Send heartbeat
  setInterval(() => ws.send(JSON.stringify({ type: 'PING' })), 30000);
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  handlePortfolioUpdate(data);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
  // Implement reconnection logic
};
```

### Database Connection

```java
// Spring Boot PostgreSQL configuration
@Configuration
public class DatabaseConfig {

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource")
    public HikariDataSource dataSource() {
        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setJdbcUrl("jdbc:postgresql://pms-db-prod.cluster.us-east-1.rds.amazonaws.com:5432/pms_db_prod");
        dataSource.setUsername("${DB_USERNAME}");
        dataSource.setPassword("${DB_PASSWORD}");
        dataSource.setDriverClassName("org.postgresql.Driver");

        // Connection pool settings
        dataSource.setMaximumPoolSize(20);
        dataSource.setMinimumIdle(5);
        dataSource.setConnectionTimeout(30000);
        dataSource.setIdleTimeout(600000);
        dataSource.setMaxLifetime(1800000);

        return dataSource;
    }
}
```

## Security Protocols

### TLS Configuration

**Certificate Management**:
- AWS Certificate Manager (ACM) for ALB certificates
- Let's Encrypt for development environments
- Automated certificate renewal

**SSL/TLS Settings**:
```yaml
# ALB SSL Policy
sslPolicy: ELBSecurityPolicy-TLS-1-2-2017-01

# Cipher suites
ciphers:
  - ECDHE-RSA-AES128-GCM-SHA256
  - ECDHE-RSA-AES256-GCM-SHA384
  - ECDHE-RSA-AES128-SHA256
```

### Authentication Protocols

**JWT Token Structure**:
```json
{
  "alg": "RS256",
  "typ": "JWT",
  "kid": "pms-key-001"
}
```

**Token Validation**:
- RSA signature verification
- Issuer validation (`http://auth:8081`)
- Expiration time checking
- Token type validation (USER/SERVICE)

## Monitoring Ports

### Application Metrics
- **Prometheus**: 9090 (scraped by Prometheus operator)
- **Grafana**: 3000 (internal access)
- **Jaeger**: 16686 (distributed tracing)

### Health Check Endpoints
All services expose health check endpoints:
- **Path**: `/actuator/health`
- **Method**: GET
- **Authentication**: None required
- **Response**: JSON health status

## Troubleshooting

### Common Port Issues

#### Connection Refused
```bash
# Check service status
kubectl get pods -n pms-prod

# Check service endpoints
kubectl get endpoints -n pms-prod

# Test connectivity
kubectl run test --image=busybox --rm -i --restart=Never -- wget --timeout=5 apigateway:8088/actuator/health
```

#### SSL/TLS Errors
```bash
# Test SSL connection
openssl s_client -connect api.pms-platform.com:443 -servername api.pms-platform.com

# Check certificate validity
openssl x509 -in cert.pem -text -noout
```

#### WebSocket Connection Issues
```bash
# Test WebSocket upgrade
curl -I -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -H "Sec-WebSocket-Version: 13" wss://api.pms-platform.com/ws
```

### Network Debugging Commands

```bash
# Check network policies
kubectl get networkpolicies -n pms-prod

# Test DNS resolution
kubectl run dns-test --image=busybox --rm -i --restart=Never -- nslookup apigateway.pms-prod.svc.cluster.local

# Packet capture
kubectl run packet-capture --image=corfr/tcpdump --rm -i --restart=Never -- tcpdump -i eth0 port 8088

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

## Performance Optimization

### Connection Pooling
- **HikariCP**: Database connection pooling
- **HTTP Client**: Apache HttpClient connection pooling
- **WebSocket**: Connection multiplexing

### Load Balancing
- **ALB**: Round-robin distribution
- **Kubernetes**: Service load balancing
- **Database**: Read replicas for read-heavy workloads

### Caching Strategies
- **Application Level**: Redis for session data
- **HTTP Level**: ALB caching for static content
- **Database Level**: Query result caching

## Compliance and Security

### Network Security
- **VPC Isolation**: Services in private subnets
- **Security Groups**: Least privilege access
- **Network ACLs**: Additional network layer security

### Data in Transit
- **TLS 1.3**: End-to-end encryption
- **Certificate Pinning**: Public key pinning for mobile clients
- **Perfect Forward Secrecy**: Ephemeral key exchange

### Audit and Monitoring
- **VPC Flow Logs**: Network traffic auditing
- **ALB Access Logs**: Request/response logging
- **CloudTrail**: AWS API call auditing
