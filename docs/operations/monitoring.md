---
sidebar_position: 2
title: Monitoring
---

# Monitoring Guide

This guide covers the comprehensive monitoring strategy for the PMS platform, including metrics collection, alerting, logging, and observability practices.

## Overview

The PMS platform implements a multi-layered monitoring approach combining infrastructure metrics, application performance monitoring, and business KPIs to ensure system reliability and performance.

## Table of Contents

1. [Monitoring Architecture](#monitoring-architecture)
2. [Infrastructure Monitoring](#infrastructure-monitoring)
3. [Application Monitoring](#application-monitoring)
4. [Business Metrics](#business-metrics)
5. [Alerting Strategy](#alerting-strategy)
6. [Logging Strategy](#logging-strategy)
7. [Dashboards](#dashboards)
8. [Troubleshooting](#troubleshooting)

---

## Monitoring Architecture

### Monitoring Stack

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │ Infrastructure  │    │   Business      │
│     Metrics     │    │    Metrics      │    │    Metrics      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Prometheus    │
                    │   & Alerting    │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Grafana       │
                    │   Dashboards    │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   ELK Stack     │
                    │  (Logs)         │
                    └─────────────────┘
```

### Key Components

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **ELK Stack**: Centralized logging (Elasticsearch, Logstash, Kibana)
- **AWS CloudWatch**: Infrastructure monitoring
- **Application Metrics**: Custom business metrics

---

## Infrastructure Monitoring

### Kubernetes Cluster Metrics

**Node Health:**
```yaml
# Key metrics to monitor
- node_cpu_usage
- node_memory_usage
- node_disk_usage
- node_network_io
```

**Pod Metrics:**
```yaml
- pod_cpu_usage
- pod_memory_usage
- pod_restart_count
- pod_status
```

**Cluster Resources:**
```yaml
- cluster_cpu_total
- cluster_memory_total
- cluster_pods_available
- cluster_nodes_ready
```

### AWS Infrastructure Metrics

**EKS Cluster:**
```bash
# Monitor via CloudWatch
- Cluster node count
- Cluster status
- Node group scaling events
```

**RDS Aurora:**
```bash
# Database performance
- DatabaseConnections
- DatabaseLoad
- FreeStorageSpace
- ReadLatency/WriteLatency
```

**ElastiCache Redis:**
```bash
# Cache performance
- CacheHitRate
- CurrConnections
- Evictions
- KeyspaceHits/Misses
```

**Application Load Balancer:**
```bash
# Load balancer metrics
- RequestCount
- TargetResponseTime
- HTTPCode_Target_2XX_Count
- HTTPCode_Target_4XX_Count
- HTTPCode_Target_5XX_Count
```

### Network Monitoring

**Service Mesh Metrics:**
```yaml
- istio_requests_total
- istio_request_duration_seconds
- istio_response_codes
```

**DNS Resolution:**
```bash
# Monitor service discovery
kubectl run dns-test --image=busybox --rm -it -- nslookup pms-analytics.pms.svc.cluster.local
```

---

## Application Monitoring

### Service Health Checks

**Readiness Probes:**
```yaml
readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

**Liveness Probes:**
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 30
```

### Application Metrics

**Spring Boot Actuator Endpoints:**
```yaml
# Health endpoint
GET /actuator/health

# Metrics endpoint
GET /actuator/metrics

# Info endpoint
GET /actuator/info

# Prometheus metrics
GET /actuator/prometheus
```

**Custom Business Metrics:**
```java
// Portfolio value tracking
registry.counter("portfolio.value.calculated", "portfolioId", portfolioId);

// Trade processing metrics
registry.timer("trade.process.duration", "service", "trade-capture");

// Error tracking
registry.counter("error.count", "service", serviceName, "errorType", errorType);
```

### Performance Metrics

**Response Times:**
```yaml
- http_request_duration_seconds{quantile="0.5"} < 200ms
- http_request_duration_seconds{quantile="0.95"} < 500ms
- http_request_duration_seconds{quantile="0.99"} < 1000ms
```

**Throughput:**
```yaml
- http_requests_total{status="200"} > 1000 per minute
- websocket_connections_active > 100
```

**Error Rates:**
```yaml
- http_requests_total{status="500"} / http_requests_total < 0.01
- application_errors_total < 10 per minute
```

---

## Business Metrics

### Portfolio Analytics

**Key Performance Indicators:**
```yaml
# Portfolio performance
- portfolio_total_value
- portfolio_daily_pnl
- portfolio_monthly_return
- portfolio_volatility

# Trading activity
- trades_executed_total
- trade_volume_total
- trade_success_rate
```

### Real-Time Metrics

**RTTM (Real-Time Trade Monitoring):**
```yaml
- rttm_events_processed_total
- rttm_alerts_triggered_total
- rttm_pipeline_latency
- rttm_dlq_messages_total
```

**Leaderboard Metrics:**
```yaml
- leaderboard_participants_active
- leaderboard_updates_total
- leaderboard_calculation_duration
```

### User Experience Metrics

**Frontend Performance:**
```javascript
// Core Web Vitals
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Cumulative Layout Shift (CLS)
- First Input Delay (FID)
```

**WebSocket Metrics:**
```javascript
- connection_established_total
- connection_dropped_total
- message_received_total
- message_sent_total
- reconnection_attempts_total
```

---

## Alerting Strategy

### Alert Severity Levels

**Critical (P1):**
- Service completely down
- Data loss or corruption
- Security breach
- Database unavailable

**High (P2):**
- Service degraded performance
- High error rates (>5%)
- Resource exhaustion (>90%)
- Failed deployments

**Medium (P3):**
- Warning signs
- Performance degradation
- Increased latency

**Low (P4):**
- Informational alerts
- Maintenance notifications

### Alert Rules

**Service Availability:**
```yaml
alert: ServiceDown
expr: up{job="pms-services"} == 0
for: 5m
labels:
  severity: critical
annotations:
  summary: "Service {{ $labels.service }} is down"
  description: "Service {{ $labels.service }} has been down for more than 5 minutes"
```

**High Error Rate:**
```yaml
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
for: 5m
labels:
  severity: high
annotations:
  summary: "High error rate on {{ $labels.service }}"
  description: "Error rate > 5% for {{ $labels.service }}"
```

**Resource Exhaustion:**
```yaml
alert: HighMemoryUsage
expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
for: 5m
labels:
  severity: high
annotations:
  summary: "High memory usage on {{ $labels.pod }}"
  description: "Memory usage > 90% for pod {{ $labels.pod }}"
```

### Alert Routing

**Notification Channels:**
- **PagerDuty**: Critical and high-priority alerts
- **Slack**: Medium and low-priority alerts
- **Email**: Daily summary reports
- **SMS**: Critical alerts for on-call personnel

**Escalation Policy:**
1. **Immediate**: Alert on-call engineer (15-minute response)
2. **15 minutes**: Escalate to team lead
3. **1 hour**: Escalate to engineering director
4. **4 hours**: Executive notification

---

## Logging Strategy

### Log Levels

**Production Environment:**
```yaml
- ERROR: System errors requiring immediate attention
- WARN: Potential issues or unusual conditions
- INFO: Important business logic events
- DEBUG: Detailed troubleshooting information (disabled)
```

**Development Environment:**
```yaml
- ERROR: System errors
- WARN: Potential issues
- INFO: Business logic events
- DEBUG: Detailed debugging information
```

### Log Structure

**Standard Log Format:**
```json
{
  "timestamp": "2026-02-09T10:30:00.000Z",
  "level": "INFO",
  "service": "pms-analytics",
  "traceId": "abc123def456",
  "userId": "user123",
  "message": "Portfolio value calculated",
  "context": {
    "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
    "calculationTime": 150,
    "value": 125000.50
  }
}
```

### Centralized Logging

**ELK Stack Configuration:**
```yaml
# Logstash pipeline
input {
  kubernetes {
    namespace_name => "pms"
  }
}

filter {
  json {
    source => "message"
  }
  mutate {
    add_field => { "service" => "%{[kubernetes][labels][app]}" }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "pms-logs-%{+YYYY.MM.dd}"
  }
}
```

### Log Retention

**Retention Policies:**
- **Application Logs**: 30 days
- **Audit Logs**: 1 year
- **Security Logs**: 2 years
- **Debug Logs**: 7 days

---

## Dashboards

### Grafana Dashboards

**System Overview Dashboard:**
- Cluster health status
- Service availability
- Resource utilization
- Error rates and trends

**Application Performance Dashboard:**
- Response times by endpoint
- Throughput metrics
- Error rates by service
- Database performance

**Business Metrics Dashboard:**
- Portfolio performance
- Trading activity
- User engagement
- Real-time system status

### Custom Dashboards

**Service-Specific Dashboards:**
```yaml
# Analytics Service Dashboard
- Portfolio calculations per minute
- Data processing latency
- Cache hit rates
- External API call success rates

# Trade Capture Dashboard
- Message processing rates
- Trade validation success rates
- Queue depths
- Processing latency
```

**Infrastructure Dashboard:**
```yaml
# Kubernetes Dashboard
- Pod status and restarts
- Resource usage by namespace
- Network traffic patterns
- Storage utilization

# AWS Services Dashboard
- RDS performance metrics
- Redis cache statistics
- ALB request patterns
- Cost optimization insights
```

---

## Troubleshooting

### Common Monitoring Issues

**Metrics Not Appearing:**
```bash
# Check Prometheus targets
kubectl get servicemonitors -n monitoring

# Verify service annotations
kubectl describe service pms-analytics -n pms

# Check Prometheus configuration
kubectl get configmap prometheus-config -n monitoring -o yaml
```

**Alert Not Firing:**
```bash
# Test alert expression in Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring

# Check alert rules
kubectl get prometheusrules -n monitoring
```

**Logs Not Appearing in Kibana:**
```bash
# Check Elasticsearch cluster health
curl -X GET "elasticsearch:9200/_cluster/health"

# Verify Logstash pipeline
kubectl logs -f deployment/logstash -n logging

# Check index patterns
curl -X GET "elasticsearch:9200/_cat/indices"
```

### Performance Troubleshooting

**High Latency Issues:**
1. Check application metrics for bottlenecks
2. Review database query performance
3. Analyze network latency between services
4. Check resource utilization

**Memory Leaks:**
1. Monitor heap usage over time
2. Check for garbage collection issues
3. Review application code for memory leaks
4. Consider horizontal scaling

**Database Performance:**
1. Check slow query logs
2. Review index usage
3. Monitor connection pool utilization
4. Consider read replicas for heavy queries

### Incident Response

**Standard Operating Procedure:**

1. **Acknowledge Alert**: Confirm alert validity and impact
2. **Assess Impact**: Determine affected users and systems
3. **Gather Information**: Collect relevant logs and metrics
4. **Communicate**: Notify stakeholders of incident
5. **Investigate**: Identify root cause
6. **Resolve**: Implement fix
7. **Document**: Record incident details and resolution
8. **Review**: Conduct post-mortem analysis

### Monitoring Maintenance

**Regular Tasks:**
- Review and tune alert thresholds
- Update dashboards based on new metrics
- Archive old log data
- Upgrade monitoring stack components
- Test alerting mechanisms

**Monthly Reviews:**
- Alert effectiveness analysis
- Dashboard usage and usefulness
- Monitoring coverage gaps
- Performance baseline updates

---

## Best Practices

### Monitoring as Code

**Infrastructure as Code for Monitoring:**
```yaml
# monitoring-stack.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: monitoring-stack
  namespace: monitoring
spec:
  chart:
    spec:
      chart: kube-prometheus-stack
      sourceRef:
        kind: HelmRepository
        name: prometheus-community
  values:
    prometheus:
      additionalServiceMonitors:
        - name: pms-services
          selector:
            matchLabels:
              app.kubernetes.io/name: pms
          endpoints:
            - port: metrics
              path: /actuator/prometheus
```

### Security Considerations

**Monitoring Security:**
- Encrypted communication between monitoring components
- RBAC for dashboard access
- Audit logging of monitoring access
- Secure storage of monitoring credentials

### Cost Optimization

**Monitoring Cost Management:**
- Configure appropriate retention periods
- Use sampling for high-volume metrics
- Implement data aggregation
- Regular cleanup of unused dashboards

---

## Support and Resources

### Documentation Links

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [ELK Stack Documentation](https://www.elastic.co/guide/index.html)
- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)

### Training Resources

- **Prometheus Fundamentals**: Query language, alerting rules
- **Grafana Dashboards**: Visualization best practices
- **ELK Stack**: Log analysis and troubleshooting
- **Kubernetes Monitoring**: Cluster and application monitoring

### Contact Information

**Monitoring Team:**
- **Primary**: monitoring@pms-platform.com
- **Emergency**: +1-800-PMS-MONITOR
- **Slack**: #monitoring-alerts

**Escalation Contacts:**
- **Level 1**: On-call monitoring engineer
- **Level 2**: Platform monitoring lead
- **Level 3**: DevOps director
