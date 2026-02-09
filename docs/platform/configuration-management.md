---
sidebar_position: 6
title: Configuration Management
---

# Configuration Management

## Overview

The PMS (Portfolio Management System) implements a comprehensive, hierarchical configuration management system designed to support multiple environments, secure secret handling, and runtime flexibility. This document outlines the configuration architecture, management processes, and implementation details.

## Configuration Architecture

### Hierarchical Configuration Model

PMS uses a four-tier configuration hierarchy that provides flexibility while maintaining security and consistency:

```
┌─────────────────────────────────────────────────────────────┐
│                    IMAGE_DEFAULT                            │
│  • Baked into container images                             │
│  • Spring Boot defaults                                    │
│  • Dockerfile environment variables                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  GLOBAL_CONFIG                              │
│  • Shared across all services                              │
│  • Infrastructure connection details                       │
│  • Common service endpoints                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 SERVICE_CONFIG                              │
│  • Service-specific non-secret values                      │
│  • Performance tuning parameters                          │
│  • Feature flags and thresholds                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 SERVICE_SECRET                              │
│  • Service-specific sensitive data                         │
│  • API keys and JWT secrets                                │
│  • Database credentials                                    │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Sources

#### 1. Image Defaults (IMAGE_DEFAULT)

Values compiled into container images at build time:

```dockerfile
# Dockerfile example
FROM openjdk:17-jdk-alpine
ENV SERVER_PORT=8080
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8080
```

#### 2. Global Configuration (GLOBAL_CONFIG)

Shared configuration managed through Kubernetes ConfigMaps:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pms-global-config
  namespace: pms
data:
  DB_HOST: "postgres"
  DB_PORT: "5432"
  DB_NAME: "pmsdb"
  REDIS_HOST: "redis"
  REDIS_PORT: "6379"
  KAFKA_BOOTSTRAP_SERVERS: "kafka:9092"
  RABBITMQ_HOST: "rabbitmq"
  RABBITMQ_PORT: "5672"
```

#### 3. Service Configuration (SERVICE_CONFIG)

Service-specific configuration in individual ConfigMaps:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trade-capture-config
  namespace: pms
data:
  TRADE_CAPTURE_POOL_SIZE: "20"
  TRADE_CAPTURE_BATCH_SIZE: "500"
  TRADE_CAPTURE_BATCH_TIMEOUT_MS: "100"
  GATEWAY_CONNECT_TIMEOUT: "3000"
  GATEWAY_RESPONSE_TIMEOUT: "10s"
```

#### 4. Secrets (SERVICE_SECRET)

Sensitive data managed through AWS Secrets Manager and External Secrets Operator:

```json
{
  "pms/dev/database": {
    "POSTGRES_USER": "pms_app",
    "POSTGRES_PASSWORD": "encrypted_password"
  },
  "pms/dev/auth": {
    "AUTH_JWT_SECRET": "256-bit-secret-key"
  }
}
```

## Environment Management

### Environment Strategy

PMS supports multiple deployment environments with consistent configuration management:

| Environment     | Namespace   | Purpose             | Configuration Source   |
| --------------- | ----------- | ------------------- | ---------------------- |
| **Local**       | `pms`       | Development         | Local files + defaults |
| **Development** | `pms-dev`   | Integration testing | AWS Secrets Manager    |
| **Staging**     | `pms-stage` | Pre-production      | AWS Secrets Manager    |
| **Production**  | `pms-prod`  | Live system         | AWS Secrets Manager    |

### Environment-Specific Overrides

Configuration values can be overridden per environment using Kustomize overlays:

```yaml
# k8s/overlays-pms/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

patchesStrategicMerge:
  - configmap-patch.yaml

configMapGenerator:
  - name: environment-config
    literals:
      - ENVIRONMENT=development
      - LOG_LEVEL=DEBUG
```

## Configuration Delivery

### Kubernetes Integration

#### ConfigMaps for Non-Sensitive Data

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pms-config
  namespace: pms
data:
  # Global configuration
  DB_HOST: "postgres.pms.svc.cluster.local"
  DB_PORT: "5432"
  REDIS_HOST: "redis.pms.svc.cluster.local"

  # Service endpoints
  AUTH_SERVICE_HOST: "auth.pms.svc.cluster.local"
  ANALYTICS_SERVICE_HOST: "analytics.pms.svc.cluster.local"
```

#### Secrets for Sensitive Data

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pms-secrets
  namespace: pms
type: Opaque
data:
  # Base64 encoded secrets
  db-password: <base64-encoded-password>
  jwt-secret: <base64-encoded-secret>
  api-key: <base64-encoded-key>
```

### External Secrets Operator (ESO)

ESO synchronizes AWS Secrets Manager secrets to Kubernetes:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
  namespace: pms
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: db-secret
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: pms/prod/database
        property: POSTGRES_USER
    - secretKey: password
      remoteRef:
        key: pms/prod/database
        property: POSTGRES_PASSWORD
```

### Helm Chart Integration

Configuration is delivered through the PMS Platform umbrella chart:

```yaml
# pms-platform/values.yaml
global:
  config:
    db:
      host: "postgres"
      port: "5432"
      name: "pmsdb"
    redis:
      host: "redis"
      port: "6379"
    kafka:
      bootstrapServers: "kafka:9092"

services:
  auth:
    config:
      jwtExpiration: "3600"
    secret:
      jwtSecret: "pms/dev/auth"
  tradeCapture:
    config:
      batchSize: "500"
      poolSize: "20"
    secret:
      apiKey: "pms/dev/trade-capture"
```

## Runtime Configuration

### Spring Boot Configuration

Services use Spring Boot's configuration hierarchy:

```properties
# application.properties (in container)
spring.config.import=configtree:/app/config/
spring.profiles.active=docker

# Runtime configuration sources (in order of precedence):
# 1. Command line arguments
# 2. SPRING_APPLICATION_JSON property
# 3. ServletConfig init parameters
# 4. ServletContext init parameters
# 5. JNDI attributes (java:comp/env/)
# 6. System properties (System.getProperties())
# 7. OS environment variables
# 8. Profile-specific application properties
# 9. Application properties
# 10. @PropertySource annotations
# 11. Default properties
```

### Environment Variable Mapping

Configuration properties are mapped to environment variables:

```yaml
# Deployment environment variables
env:
  - name: DB_HOST
    valueFrom:
      configMapKeyRef:
        name: pms-global-config
        key: DB_HOST
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
  - name: SPRING_PROFILES_ACTIVE
    value: "kubernetes"
```

### Angular Runtime Configuration

Frontend applications use runtime configuration injection:

```typescript
// Runtime configuration service
@Injectable({
  providedIn: "root",
})
export class RuntimeConfigService {
  private config: RuntimeConfig;

  constructor() {
    // Load configuration from window.__ENV__
    const envConfig = (window as any).__ENV__;
    this.config = this.transformConfig(envConfig);
  }

  get apiGateway(): string {
    return this.config.apiGateway;
  }

  get analytics(): { baseHttp: string; baseWs: string } {
    return this.config.analytics;
  }
}
```

## Configuration Validation

### Schema Validation

Configuration schemas ensure data integrity:

```typescript
// Configuration interface with validation
export interface DatabaseConfig {
  host: string;
  port: number;
  name: string;
  username: string;
  password: string;
  ssl: boolean;
}

export const databaseConfigSchema = Joi.object({
  host: Joi.string().hostname().required(),
  port: Joi.number().integer().min(1024).max(65535).required(),
  name: Joi.string().min(1).max(64).required(),
  username: Joi.string().min(1).max(32).required(),
  password: Joi.string().min(8).required(),
  ssl: Joi.boolean().default(true),
});
```

### Startup Validation

Services validate configuration at startup:

```java
@Configuration
public class ConfigurationValidation {

    @Bean
    public static BeanPostProcessor configurationValidator() {
        return new BeanPostProcessor() {
            @Override
            public Object postProcessBeforeInitialization(Object bean, String beanName) {
                if (bean instanceof EnvironmentAware) {
                    validateConfiguration(((EnvironmentAware) bean).getEnvironment());
                }
                return bean;
            }
        };
    }

    private static void validateConfiguration(Environment environment) {
        // Validate required configuration properties
        Assert.notNull(environment.getProperty("db.host"), "Database host is required");
        Assert.notNull(environment.getProperty("db.password"), "Database password is required");
    }
}
```

## Configuration Lifecycle

### Development Workflow

1. **Local Development**

   ```bash
   # Use local configuration files
   cp secrets/examples/secrets.env.example k8s/overlays-pms/local/secrets.env
   ./scripts/deploy-local.sh
   ```

2. **Configuration Changes**

   ```bash
   # Update ConfigMap
   kubectl create configmap pms-config --from-env-file=config.properties -o yaml --dry-run=client > configmap.yaml

   # Apply changes
   kubectl apply -f configmap.yaml
   ```

3. **Secret Rotation**

   ```bash
   # Update AWS Secrets Manager
   aws secretsmanager update-secret --secret-id pms/dev/database --secret-string '{"username":"newuser","password":"newpass"}'

   # ESO automatically syncs to Kubernetes
   kubectl get externalsecret -n pms
   ```

### Deployment Process

Configuration is managed through GitOps:

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pms-platform
  namespace: argocd
spec:
  project: pms
  source:
    repoURL: https://github.com/pms-org/pms-infra
    path: k8s/overlays-pms/dev
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: pms-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Configuration Monitoring

### Configuration Drift Detection

Monitor for configuration drift between environments:

```bash
# Compare configurations
kubectl get configmap pms-config -n pms-dev -o yaml > dev-config.yaml
kubectl get configmap pms-config -n pms-prod -o yaml > prod-config.yaml
diff dev-config.yaml prod-config.yaml
```

### Audit Logging

Configuration changes are audited:

```yaml
# Audit webhook configuration
apiVersion: v1
kind: Config
clusters: null
contexts: null
current-context: ""
kind: Config
preferences: {}
users:
- name: audit-webhook
  user:
    token: <audit-token>
```

### Health Checks

Configuration health is monitored:

```yaml
# Configuration health check
livenessProbe:
  httpGet:
    path: /actuator/health/config
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/config
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Security Considerations

### Secret Management

#### Encryption at Rest

- AWS Secrets Manager encrypts all secrets with AES-256
- Kubernetes secrets are encrypted using envelope encryption
- Database credentials are never logged or exposed

#### Access Control

```yaml
# IAM policy for secret access
{
  "Version": "2012-10-17",
  "Statement":
    [
      {
        "Effect": "Allow",
        "Action":
          ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:pms/prod/*",
      },
    ],
}
```

#### Key Rotation

- Secrets are automatically rotated every 30 days
- Applications handle rotation transparently
- Previous secret versions are maintained during transition

### Configuration Security

#### Input Validation

All configuration inputs are validated:

```typescript
// Configuration validation
export class ConfigValidator {
  static validate(config: any): ValidationResult {
    const result = Joi.validate(config, configSchema);
    if (result.error) {
      throw new ConfigurationError(result.error.details);
    }
    return result.value;
  }
}
```

#### Secure Defaults

Configuration uses secure defaults:

```yaml
# Security-focused defaults
security:
  headers:
    hsts: "max-age=31536000; includeSubDomains"
    contentSecurityPolicy: "default-src 'self'"
    xFrameOptions: "DENY"
  cors:
    allowedOrigins: ["https://trusted-domain.com"]
    allowedMethods: ["GET", "POST"]
    allowCredentials: false
```

## Troubleshooting

### Common Configuration Issues

#### Configuration Not Loading

```bash
# Check ConfigMap exists
kubectl get configmap -n pms

# Check pod environment variables
kubectl exec -it deployment/trade-capture -n pms -- env | grep DB_

# Check application logs
kubectl logs deployment/trade-capture -n pms | grep config
```

#### Secret Synchronization Issues

```bash
# Check ExternalSecret status
kubectl describe externalsecret database-secret -n pms

# Check ESO logs
kubectl logs -n external-secrets deployment/external-secrets-webhook

# Verify AWS permissions
aws sts get-caller-identity
```

#### Environment Variable Conflicts

```bash
# List all environment variables
kubectl exec -it deployment/trade-capture -n pms -- env | sort

# Check for duplicates
kubectl exec -it deployment/trade-capture -n pms -- env | grep -c "DB_HOST"
```

### Configuration Debugging

#### Enable Debug Logging

```yaml
# Enable configuration debug logging
env:
  - name: SPRING_BOOT_DEBUG
    value: "true"
  - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_BOOT
    value: "DEBUG"
```

#### Configuration Dump

```bash
# Dump Spring Boot configuration
kubectl exec -it deployment/trade-capture -n pms -- curl http://localhost:8080/actuator/configprops
```

This configuration management system provides a robust, secure, and maintainable approach to managing application configuration across all PMS components and environments.
