---
sidebar_position: 4
title: Configuration
---

# Analytics Service — Configuration

## Overview

The Analytics Service uses a layered configuration approach combining **Spring Boot properties**, **environment variables**, **Kubernetes ConfigMaps**, and **Kubernetes Secrets**. This document provides comprehensive guidance on all configuration options, their purposes, and best practices.

---

## Configuration Sources Priority

Spring Boot resolves configuration in the following order (highest to lowest priority):

1. **Environment Variables** (OS-level, Kubernetes env)
2. **application.properties** / **application.yaml** (bundled in JAR)
3. **ConfigMaps** (Kubernetes-mounted properties)
4. **Secrets** (Kubernetes-mounted sensitive values)
5. **Default Values** (hardcoded in application)

---

## Environment Variables

### Critical Runtime Variables

These environment variables **must** be set for the service to function.

| Variable | Type | Required | Description | Example |
|----------|------|----------|-------------|---------|
| `KAFKA_BROKERS` | String | **Yes** | Comma-separated Kafka bootstrap servers | `kafka-0:9092,kafka-1:9092` |
| `DB_URL` | String | **Yes** | PostgreSQL JDBC connection string | `jdbc:postgresql://pms-db:5432/pmsdb` |
| `DB_USERNAME` | String | **Yes** | Database username | `analytics_user` |
| `DB_PASSWORD` | String | **Yes** | Database password (from Secret) | `<encrypted>` |
| `REDIS_HOST` | String | **Yes** | Redis server hostname | `pms-redis` |
| `REDIS_PORT` | Integer | No | Redis server port (default: 6379) | `6379` |
| `FINNHUB_API_KEY` | String | **Yes** | Finnhub API authentication token | `<your-api-key>` |
| `FINNHUB_API_BASE_URL` | String | No | Finnhub API base URL | `https://finnhub.io/api/v1` |

### Optional Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PRICE_REFRESH_INTERVAL` | Integer | `20000` | Market price fetch interval (milliseconds) |
| `UNREALISED_PNL_INTERVAL` | Integer | `30000` | Unrealised P&L calculation interval (milliseconds) |
| `APP_BUFFER_SIZE` | Integer | `1000` | Kafka message buffer capacity |
| `APP_BATCH_SIZE` | Integer | `100` | Database batch insert size |
| `SPRING_PROFILES_ACTIVE` | String | `default` | Active Spring profile (`dev`, `prod`, `test`) |
| `LOGGING_LEVEL_ROOT` | String | `INFO` | Root logging level |
| `LOGGING_LEVEL_ANALYTICS` | String | `INFO` | Analytics service logging level |

### Example: Kubernetes Deployment Environment Variables

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pms-analytics
spec:
  template:
    spec:
      containers:
      - name: analytics
        image: pms-analytics:latest
        env:
        - name: KAFKA_BROKERS
          valueFrom:
            configMapKeyRef:
              name: pms-config
              key: kafka.brokers
        - name: DB_URL
          valueFrom:
            configMapKeyRef:
              name: pms-config
              key: postgres.url
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: pms-secrets
              key: postgres.username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pms-secrets
              key: postgres.password
        - name: REDIS_HOST
          valueFrom:
            configMapKeyRef:
              name: pms-config
              key: redis.host
        - name: FINNHUB_API_KEY
          valueFrom:
            secretKeyRef:
              name: pms-secrets
              key: finnhub.apikey
```

---

## Application Properties

### Spring Boot Configuration File

**Location**: `src/main/resources/application.properties`

```properties
# Server Configuration
server.port=8086
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s

# Application Name
spring.application.name=pms-analytics

# Database Configuration
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

# Hikari Connection Pool
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.max-lifetime=1800000

# JPA / Hibernate
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.jdbc.batch_size=${APP_BATCH_SIZE:100}
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true

# Kafka Consumer Configuration
spring.kafka.bootstrap-servers=${KAFKA_BROKERS}
spring.kafka.consumer.group-id=analytics-consumer-group
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.enable-auto-commit=false
spring.kafka.consumer.max-poll-records=500
spring.kafka.consumer.fetch-min-size=1
spring.kafka.consumer.fetch-max-wait=500ms
spring.kafka.listener.ack-mode=manual
spring.kafka.listener.concurrency=3

# Kafka Producer Configuration
spring.kafka.producer.acks=all
spring.kafka.producer.retries=3
spring.kafka.producer.batch-size=16384
spring.kafka.producer.buffer-memory=33554432
spring.kafka.producer.compression-type=gzip

# Kafka Topics
app.kafka.consumer-id=analytics-transactions-consumer
app.kafka.consumer-topic=transactions
app.kafka.producer-topic=risk-events

# Redis Configuration
spring.data.redis.host=${REDIS_HOST}
spring.data.redis.port=${REDIS_PORT:6379}
spring.data.redis.timeout=2000ms
spring.data.redis.lettuce.pool.max-active=20
spring.data.redis.lettuce.pool.max-idle=10
spring.data.redis.lettuce.pool.min-idle=5

# Finnhub API
finnhub.api.key=${FINNHUB_API_KEY}
finnhub.api.base-url=${FINNHUB_API_BASE_URL:https://finnhub.io/api/v1}

# WebSocket Configuration
spring.websocket.allowed-origins=*
spring.websocket.sockjs.enabled=true

# Actuator (Health & Metrics)
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=when-authorized
management.health.livenessState.enabled=true
management.health.readinessState.enabled=true

# Logging
logging.level.root=${LOGGING_LEVEL_ROOT:INFO}
logging.level.com.pms.analytics=${LOGGING_LEVEL_ANALYTICS:INFO}
logging.level.org.springframework.kafka=WARN
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
logging.pattern.file=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n

# Scheduler Configuration
app.scheduler.price-update-interval=${PRICE_REFRESH_INTERVAL:20000}
app.scheduler.unrealised-pnl-interval=${UNREALISED_PNL_INTERVAL:30000}
app.scheduler.risk-metrics-cron=0 0 0 * * ?

# Buffer Configuration
app.buffer.size=${APP_BUFFER_SIZE:1000}
app.buffer.threshold=0.8
```

---

## Profile-Specific Configuration

### Development Profile (`application-dev.properties`)

```properties
# Development-specific overrides
spring.jpa.show-sql=true
spring.jpa.hibernate.ddl-auto=update
logging.level.com.pms.analytics=DEBUG
logging.level.org.springframework.kafka=DEBUG

# Use local services
spring.kafka.bootstrap-servers=localhost:9092
spring.data.redis.host=localhost
spring.datasource.url=jdbc:postgresql://localhost:5432/pmsdb_dev

# Disable authentication for testing
spring.security.enabled=false

# Faster intervals for testing
app.scheduler.price-update-interval=10000
app.scheduler.unrealised-pnl-interval=15000
```

**Activation**: Set `SPRING_PROFILES_ACTIVE=dev`

### Production Profile (`application-prod.properties`)

```properties
# Production-specific overrides
spring.jpa.show-sql=false
spring.jpa.hibernate.ddl-auto=validate
logging.level.root=WARN
logging.level.com.pms.analytics=INFO

# Enhanced connection pool
spring.datasource.hikari.maximum-pool-size=50
spring.datasource.hikari.minimum-idle=10

# Kafka optimizations
spring.kafka.consumer.max-poll-records=1000
spring.kafka.listener.concurrency=5

# Stricter health checks
management.endpoint.health.probes.enabled=true
```

**Activation**: Set `SPRING_PROFILES_ACTIVE=prod`

---

## Kubernetes ConfigMaps

### ConfigMap Definition

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pms-analytics-config
  namespace: pms
data:
  # Kafka Configuration
  kafka.brokers: "kafka-0.kafka-headless.kafka.svc.cluster.local:9092,kafka-1.kafka-headless.kafka.svc.cluster.local:9092"
  kafka.topic.transactions: "transactions"
  kafka.topic.risk-events: "risk-events"
  kafka.consumer-group: "analytics-consumer-group"
  
  # Database Configuration
  postgres.url: "jdbc:postgresql://pms-db.pms.svc.cluster.local:5432/pmsdb"
  postgres.pool.max-size: "20"
  postgres.pool.min-idle: "5"
  
  # Redis Configuration
  redis.host: "pms-redis.pms.svc.cluster.local"
  redis.port: "6379"
  redis.timeout: "2000"
  
  # Scheduler Configuration
  scheduler.price-update-ms: "20000"
  scheduler.unrealised-pnl-ms: "30000"
  scheduler.risk-metrics-cron: "0 0 0 * * ?"
  
  # Buffer Configuration
  buffer.size: "1000"
  batch.size: "100"
  
  # Finnhub API
  finnhub.base-url: "https://finnhub.io/api/v1"
  
  # Logging
  logging.level.root: "INFO"
  logging.level.analytics: "INFO"
```

### Mounting ConfigMap

```yaml
spec:
  containers:
  - name: analytics
    envFrom:
    - configMapRef:
        name: pms-analytics-config
```

---

## Kubernetes Secrets

### Secret Definition

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pms-analytics-secrets
  namespace: pms
type: Opaque
stringData:
  DB_USERNAME: "analytics_user"
  DB_PASSWORD: "SuperSecurePassword123!"
  FINNHUB_API_KEY: "your-finnhub-api-key-here"
  REDIS_PASSWORD: "" # Redis without auth in dev
```

### Mounting Secrets

```yaml
spec:
  containers:
  - name: analytics
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: pms-analytics-secrets
          key: DB_USERNAME
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: pms-analytics-secrets
          key: DB_PASSWORD
    - name: FINNHUB_API_KEY
      valueFrom:
        secretKeyRef:
          name: pms-analytics-secrets
          key: FINNHUB_API_KEY
```

---

## Configuration Behavior & Validation

### Missing Required Values

#### Kafka Missing
**Behavior**: Service fails to start  
**Error**: `org.springframework.kafka.KafkaException: Failed to construct kafka consumer`  
**Resolution**: Verify `KAFKA_BROKERS` is set and Kafka cluster is reachable

#### Database Missing
**Behavior**: Service fails to start  
**Error**: `org.springframework.jdbc.CannotGetJdbcConnectionException`  
**Resolution**: Verify `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` are correct

#### Redis Missing
**Behavior**: Service starts with **degraded performance**  
**Impact**:
- Finnhub API called directly without caching
- Increased API rate limit consumption
- Slower unrealised P&L calculations
**Logs**: `WARN - Redis connection failed, continuing without cache`

#### Finnhub API Key Missing
**Behavior**: Service starts but **unrealised P&L disabled**  
**Impact**:
- Price fetching fails
- Unrealised P&L calculations skipped
- WebSocket topic `/topic/unrealised-pnl` receives no updates
**Logs**: `ERROR - Finnhub API key not configured, price updates disabled`

---

## Development vs Production Differences

### Local Development

**Purpose**: Fast iteration, detailed debugging

**Key Differences**:
- `spring.jpa.hibernate.ddl-auto=update` (auto-schema updates)
- `spring.jpa.show-sql=true` (SQL logging)
- `logging.level=DEBUG` (verbose logs)
- Lower Kafka partition counts
- Mocked Finnhub responses (optional)
- Single-node Kafka/Redis

**Configuration**:
```bash
export SPRING_PROFILES_ACTIVE=dev
export KAFKA_BROKERS=localhost:9092
export DB_URL=jdbc:postgresql://localhost:5432/pmsdb_dev
export DB_USERNAME=dev_user
export DB_PASSWORD=dev_pass
export REDIS_HOST=localhost
export FINNHUB_API_KEY=mock-key
```

### Production

**Purpose**: High performance, reliability, security

**Key Differences**:
- `spring.jpa.hibernate.ddl-auto=validate` (no schema changes)
- `spring.jpa.show-sql=false` (no SQL logging)
- `logging.level=INFO/WARN` (minimal logs)
- Higher connection pool sizes
- Full rate-limited Finnhub API
- Multi-node Kafka/Redis clusters
- Secrets managed via sealed secrets or external vaults

**Configuration**:
```bash
export SPRING_PROFILES_ACTIVE=prod
# All other values from Kubernetes ConfigMap/Secrets
```

---

## Performance Tuning

### Database Connection Pool

**Recommended Settings** (per pod):
- **Max Pool Size**: `20-50` (based on load)
- **Min Idle**: `5-10`
- **Connection Timeout**: `30000ms`

**Calculation**:
```
Max Connections = (Number of Pods) × (Max Pool Size per Pod)
Ensure PostgreSQL max_connections > Max Connections
```

### Kafka Consumer Tuning

**High Throughput**:
```properties
spring.kafka.consumer.max-poll-records=1000
spring.kafka.listener.concurrency=5
app.buffer.size=2000
```

**Low Latency**:
```properties
spring.kafka.consumer.max-poll-records=100
spring.kafka.listener.concurrency=3
spring.kafka.consumer.fetch-max-wait=100ms
```

### Redis Connection Pool

```properties
spring.data.redis.lettuce.pool.max-active=50
spring.data.redis.lettuce.pool.max-idle=20
spring.data.redis.lettuce.pool.min-idle=10
```

---

## Health Check Configuration

### Liveness Probe

**Endpoint**: `/actuator/health/liveness`

**Purpose**: Detect if JVM is alive

**Kubernetes Configuration**:
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8086
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

### Readiness Probe

**Endpoint**: `/actuator/health/readiness`

**Purpose**: Verify service can accept traffic

**Checks**:
- Database connectivity
- Kafka broker reachability
- Redis availability (optional)

**Kubernetes Configuration**:
```yaml
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8086
  initialDelaySeconds: 30
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

---

## Security Best Practices

### Secrets Management

1. **Never commit secrets to Git**
2. Use Kubernetes Secrets or external secret managers (AWS Secrets Manager, HashiCorp Vault)
3. Rotate secrets regularly (quarterly minimum)
4. Use different credentials per environment

### Database Credentials

```bash
# Generate secure password
openssl rand -base64 32

# Create Kubernetes secret
kubectl create secret generic pms-analytics-secrets \
  --from-literal=DB_USERNAME=analytics_user \
  --from-literal=DB_PASSWORD=$(openssl rand -base64 32) \
  --namespace=pms
```

### Finnhub API Key

- Request production key from Finnhub
- Store in Kubernetes Secret
- Monitor usage via Finnhub dashboard
- Set up alerts for rate limit approaching

---

## Monitoring & Observability

### Metrics Exposure

**Prometheus Endpoint**: `/actuator/prometheus`

**Key Metrics**:
- `kafka_consumer_lag`: Kafka consumer lag
- `hikari_connections_active`: Active DB connections
- `redis_commands_total`: Redis operations count
- `http_server_requests_seconds`: API response times

**Kubernetes ServiceMonitor**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pms-analytics
spec:
  selector:
    matchLabels:
      app: pms-analytics
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
```

---

## Troubleshooting Configuration Issues

### Service Fails to Start

**Check**:
1. Logs: `kubectl logs -f <pod-name>`
2. Environment variables: `kubectl exec <pod-name> -- env | grep -E "(KAFKA|DB|REDIS)"`
3. ConfigMap: `kubectl get configmap pms-analytics-config -o yaml`
4. Secrets: `kubectl get secret pms-analytics-secrets -o yaml`

### Common Misconfigurations

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| `Connection refused` errors | Wrong host/port in config | Verify service names and ports |
| `Authentication failed` | Wrong credentials | Check Secret values |
| Service starts but no data | Kafka topic mismatch | Verify topic names |
| High CPU usage | Too many concurrent threads | Reduce Kafka concurrency |
| Out of memory | Buffer size too large | Reduce `app.buffer.size` |

---

## Configuration Checklist

### Pre-Deployment

- [ ] All required environment variables set
- [ ] ConfigMap created with correct values
- [ ] Secrets created with strong passwords
- [ ] Finnhub API key obtained and configured
- [ ] Database connection tested
- [ ] Kafka topics created
- [ ] Redis cluster deployed

### Post-Deployment

- [ ] Health endpoints returning 200
- [ ] Kafka consumer lag < 1000 messages
- [ ] Database connections stable
- [ ] Redis cache hit rate > 80%
- [ ] No ERROR logs in startup
- [ ] Metrics being scraped by Prometheus

---

## References

- [Spring Boot External Configuration](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Finnhub API Documentation](https://finnhub.io/docs/api)

