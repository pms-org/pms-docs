---
sidebar_position: 3
title: Debugging
---

# Debugging Guide

This comprehensive guide covers debugging techniques, tools, and methodologies for troubleshooting issues across the PMS platform, from application code to infrastructure.

## Overview

Effective debugging in a microservices architecture requires understanding the entire stack: frontend applications, backend services, databases, message queues, and infrastructure components.

## Table of Contents

1. [Debugging Methodology](#debugging-methodology)
2. [Application Debugging](#application-debugging)
3. [Frontend Debugging](#frontend-debugging)
4. [Database Debugging](#database-debugging)
5. [Network Debugging](#network-debugging)
6. [Kubernetes Debugging](#kubernetes-debugging)
7. [Performance Debugging](#performance-debugging)
8. [Distributed Tracing](#distributed-tracing)
9. [Debug Tools](#debug-tools)
10. [Common Issues](#common-issues)

---

## Debugging Methodology

### Systematic Approach

**1. Define the Problem:**
- What is the expected behavior?
- What is the actual behavior?
- When did the issue start?
- Who is affected?

**2. Gather Information:**
- Application logs
- System metrics
- User reports
- Error messages

**3. Form Hypothesis:**
- What could cause this behavior?
- What has changed recently?
- Are there similar issues in other services?

**4. Test Hypothesis:**
- Reproduce the issue
- Isolate components
- Use debugging tools

**5. Implement Fix:**
- Apply minimal changes
- Test thoroughly
- Monitor for regressions

**6. Document and Learn:**
- Update runbooks
- Improve monitoring
- Prevent future occurrences

### Debugging Levels

```
┌─────────────────┐
│   User Reports  │ ← Start here
└─────────────────┘
         ↓
┌─────────────────┐
│  Application    │ ← Check logs, metrics
│    Symptoms     │
└─────────────────┘
         ↓
┌─────────────────┐
│ Infrastructure  │ ← Network, resources
│    Issues       │
└─────────────────┘
         ↓
┌─────────────────┐
│   Root Cause    │ ← Code, configuration
│   Analysis      │
└─────────────────┘
```

---

## Application Debugging

### Spring Boot Applications

**Actuator Endpoints:**
```bash
# Health check
curl http://localhost:8080/actuator/health

# Application info
curl http://localhost:8080/actuator/info

# Environment properties
curl http://localhost:8080/actuator/env

# Heap dump
curl http://localhost:8080/actuator/heapdump -o heapdump.hprof
```

**JVM Debugging:**
```bash
# Enable remote debugging
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 \
  -jar application.jar

# Connect with IntelliJ IDEA or Eclipse
# Host: localhost
# Port: 5005
```

**Thread Dumps:**
```bash
# Generate thread dump
jstack -l <pid> > thread_dump.txt

# Analyze with tools like fastThread or TDA
```

### Log Analysis

**Log Levels:**
```yaml
logging:
  level:
    com.pms: DEBUG
    org.springframework: INFO
    org.hibernate: WARN
```

**Structured Logging:**
```java
logger.info("Processing trade",
    kv("tradeId", tradeId),
    kv("portfolioId", portfolioId),
    kv("amount", amount));
```

**Log Correlation:**
```java
// Add trace ID to MDC
MDC.put("traceId", traceId);
logger.info("Starting trade processing");
```

---

## Frontend Debugging

### Browser Developer Tools

**Console Debugging:**
```javascript
// Debug WebSocket connections
console.log('WebSocket connected:', ws.readyState);

// Debug API calls
fetch('/api/portfolio')
  .then(response => {
    console.log('Response:', response);
    return response.json();
  })
  .then(data => console.log('Data:', data))
  .catch(error => console.error('Error:', error));
```

**Network Tab:**
- Check HTTP status codes
- Verify request/response headers
- Monitor WebSocket connections
- Analyze payload sizes

**Application Tab:**
- Local storage and session storage
- Service worker status
- Cache storage

### Angular Debugging

**Change Detection:**
```typescript
// Debug change detection cycles
ng.profiler.timeChangeDetection();

// Check for unnecessary changes
constructor(private cdr: ChangeDetectorRef) {
  cdr.detach(); // Manual control
}
```

**Component Debugging:**
```typescript
// Debug component lifecycle
ngOnInit() {
  console.log('Component initialized', this);
}

ngOnDestroy() {
  console.log('Component destroyed');
}
```

**Service Debugging:**
```typescript
@Injectable()
export class DebugService {
  debug<T>(label: string, data: T): T {
    console.log(`[${label}]`, data);
    return data;
  }
}
```

### WebSocket Debugging

**Connection Monitoring:**
```javascript
const ws = new WebSocket(url);

ws.onopen = () => console.log('WebSocket opened');
ws.onmessage = (event) => {
  console.log('Message received:', event.data);
  try {
    const data = JSON.parse(event.data);
    console.log('Parsed data:', data);
  } catch (e) {
    console.error('Failed to parse message:', e);
  }
};
ws.onclose = (event) => console.log('WebSocket closed:', event.code, event.reason);
ws.onerror = (error) => console.error('WebSocket error:', error);
```

**STOMP Debugging:**
```javascript
const client = new Client({
  debug: (str) => console.log('STOMP:', str),
  // ... other config
});
```

---

## Database Debugging

### PostgreSQL Debugging

**Connection Issues:**
```sql
-- Check active connections
SELECT * FROM pg_stat_activity;

-- Check connection limits
SHOW max_connections;

-- Monitor slow queries
SELECT * FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

**Query Performance:**
```sql
-- Explain query execution
EXPLAIN ANALYZE
SELECT * FROM portfolio_positions
WHERE portfolio_id = $1;

-- Check index usage
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public';
```

**Lock Analysis:**
```sql
-- Check for locks
SELECT * FROM pg_locks;

-- Find blocking queries
SELECT
  blocked_locks.pid AS blocked_pid,
  blocking_locks.pid AS blocking_pid,
  blocked_activity.query AS blocked_query,
  blocking_activity.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid;
```

### Redis Debugging

**Connection Issues:**
```bash
# Test Redis connectivity
redis-cli ping

# Check Redis info
redis-cli info

# Monitor commands
redis-cli monitor
```

**Key Analysis:**
```bash
# Check key patterns
redis-cli keys "portfolio:*"

# Analyze memory usage
redis-cli memory stats

# Check TTL values
redis-cli ttl "session:user123"
```

---

## Network Debugging

### Service-to-Service Communication

**DNS Resolution:**
```bash
# Test service discovery
nslookup pms-analytics.pms.svc.cluster.local

# Check DNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

**Connectivity Testing:**
```bash
# Test HTTP connectivity
curl -v http://pms-analytics:8080/actuator/health

# Test WebSocket connectivity
websocat ws://pms-analytics:8080/ws/portfolio
```

**Network Policies:**
```bash
# Check network policies
kubectl get networkpolicies -n pms

# Test policy enforcement
kubectl run test --image=busybox --rm -it -- \
  wget --timeout=5 pms-analytics.pms.svc.cluster.local:8080
```

### Load Balancer Debugging

**ALB Access Logs:**
```bash
# Check ALB logs in CloudWatch
aws logs filter-log-events \
  --log-group-name /aws/alb/pms-alb \
  --start-time $(date -d '1 hour ago' +%s)000

# Common issues:
# - 502 Bad Gateway: Service unavailable
# - 504 Gateway Timeout: Service slow
# - 503 Service Unavailable: No healthy targets
```

**Target Group Health:**
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

---

## Kubernetes Debugging

### Pod Debugging

**Pod Status:**
```bash
# Check pod status
kubectl get pods -n pms

# Describe pod
kubectl describe pod <pod-name> -n pms

# Check pod logs
kubectl logs <pod-name> -n pms --previous
```

**Container Debugging:**
```bash
# Execute into running container
kubectl exec -it <pod-name> -n pms -- /bin/bash

# Debug with ephemeral container
kubectl debug <pod-name> -n pms --image=busybox -- /bin/bash
```

**Resource Issues:**
```bash
# Check resource usage
kubectl top pods -n pms

# Check resource limits
kubectl describe pod <pod-name> -n pms | grep -A 10 "Limits:"
```

### Service Debugging

**Service Discovery:**
```bash
# Check service endpoints
kubectl get endpoints -n pms

# Test service connectivity
kubectl run test --image=busybox --rm -it -- \
  telnet pms-analytics.pms.svc.cluster.local 8080
```

**Ingress Issues:**
```bash
# Check ingress status
kubectl get ingress -n pms

# Check ingress controller logs
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
```

---

## Performance Debugging

### Application Performance

**Memory Leaks:**
```java
// JVM memory analysis
jmap -dump:format=b,file=heap.hprof <pid>

// Use tools like VisualVM or MAT
```

**CPU Profiling:**
```java
// Generate CPU flame graph
java -agentpath:/path/to/async-profiler/lib/libasyncProfiler.so=start \
  -jar application.jar
```

**Database Performance:**
```sql
-- Find slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Check index usage
SELECT * FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Frontend Performance

**Core Web Vitals:**
```javascript
// Measure FCP, LCP, CLS, FID
new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log(entry.name, entry.value);
  }
}).observe({ entryTypes: ['measure'] });
```

**Bundle Analysis:**
```bash
# Analyze bundle size
npm run build -- --stats-json
npx webpack-bundle-analyzer dist/stats.json
```

**Runtime Performance:**
```javascript
// Profile JavaScript execution
console.profile('operation');
// ... code to profile ...
console.profileEnd('operation');
```

---

## Distributed Tracing

### Jaeger Integration

**Spring Boot Configuration:**
```yaml
opentracing:
  jaeger:
    enabled: true
    service-name: pms-analytics
    udp-sender:
      host: jaeger-agent
      port: 6831
```

**Trace Analysis:**
```bash
# Query traces
curl "http://jaeger:16686/api/traces?service=pms-analytics&limit=10"

# Find slow traces
curl "http://jaeger:16686/api/traces?service=pms-analytics&minDuration=1s"
```

### Frontend Tracing

**User Interaction Tracing:**
```javascript
// Trace user actions
const tracer = window.tracer;

const span = tracer.startSpan('user-click');
span.setTag('component', 'button');
span.setTag('action', 'submit-form');
// ... perform action ...
span.finish();
```

---

## Debug Tools

### Development Tools

**IDE Integration:**
- IntelliJ IDEA: Remote debugging, database tools
- VS Code: Extensions for Kubernetes, Docker
- Chrome DevTools: Frontend debugging

**Command Line Tools:**
```bash
# Network debugging
netcat, telnet, curl, wget

# Process monitoring
htop, ps, lsof, strace

# Log analysis
grep, sed, awk, jq

# Container tools
docker, podman, kubectl
```

### Monitoring Tools

**Application Monitoring:**
- Spring Boot Actuator
- Micrometer metrics
- JVM tools (jstack, jmap, jstat)

**Infrastructure Monitoring:**
- Prometheus metrics
- Grafana dashboards
- ELK stack logging

**Cloud Tools:**
- AWS CloudWatch
- AWS X-Ray
- Kubernetes dashboard

---

## Common Issues

### Service Startup Issues

**Database Connection:**
```bash
# Check database connectivity
kubectl exec -it deployment/pms-analytics -- \
  psql -h pms-database -U pms_user -d pms_db -c "SELECT 1;"

# Check connection pool
kubectl logs deployment/pms-analytics | grep "connection pool"
```

**Configuration Issues:**
```bash
# Check environment variables
kubectl exec -it deployment/pms-analytics -- env | grep PMS

# Check ConfigMaps
kubectl get configmap -n pms
kubectl describe configmap <configmap-name> -n pms
```

### Runtime Issues

**Memory Issues:**
```bash
# Check JVM memory
kubectl exec -it deployment/pms-analytics -- \
  jcmd 1 VM.native_memory summary

# Check container limits
kubectl describe pod <pod-name> -n pms | grep -A 5 "Limits:"
```

**Thread Issues:**
```bash
# Generate thread dump
kubectl exec -it deployment/pms-analytics -- \
  jstack 1 > /tmp/thread_dump.txt

# Check for deadlocks
kubectl exec -it deployment/pms-analytics -- \
  jcmd 1 Thread.print | grep -A 10 "Found.*deadlock"
```

### Network Issues

**Service Discovery:**
```bash
# Check DNS resolution
kubectl run dns-test --image=busybox --rm -it -- \
  nslookup pms-analytics.pms.svc.cluster.local

# Check service endpoints
kubectl get endpoints pms-analytics -n pms
```

**Load Balancer Issues:**
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <arn>

# Check ALB access logs
aws logs tail /aws/alb/pms-alb --follow
```

### Data Issues

**Database Corruption:**
```sql
-- Check table consistency
VACUUM VERBOSE portfolio_positions;

-- Check for orphaned records
SELECT COUNT(*) FROM portfolio_positions
WHERE portfolio_id NOT IN (SELECT id FROM portfolios);
```

**Cache Inconsistency:**
```bash
# Clear Redis cache
redis-cli flushall

# Check cache hit rates
redis-cli info | grep keyspace
```

---

## Best Practices

### Debugging Environment

**Local Development:**
- Use Docker Compose for local testing
- Enable debug logging
- Use IDE debugging tools
- Mock external dependencies

**Staging Environment:**
- Mirror production configuration
- Enable detailed logging
- Use real data subsets
- Test with production load patterns

### Code Debugging

**Defensive Programming:**
```java
// Add debug logging
logger.debug("Processing trade {} for portfolio {}",
    tradeId, portfolioId, kv("amount", amount));

// Validate inputs
if (portfolioId == null) {
    throw new IllegalArgumentException("Portfolio ID cannot be null");
}
```

**Error Handling:**
```java
try {
    processTrade(trade);
} catch (Exception e) {
    logger.error("Failed to process trade", e);
    // Add context
    throw new TradeProcessingException(
        "Failed to process trade " + tradeId, e);
}
```

### Documentation

**Debugging Runbooks:**
- Document common issues and solutions
- Include debugging commands
- Update with new issues encountered
- Share knowledge across team

**Post-Mortem Analysis:**
- Document root cause analysis
- Identify preventive measures
- Update monitoring and alerting
- Improve system resilience

---

## Support Resources

### Internal Resources

**Team Documentation:**
- Service architecture diagrams
- API documentation
- Troubleshooting runbooks
- On-call rotation schedule

**Tools and Access:**
- Development environment access
- Production log access
- Monitoring dashboard access
- Database read-only access

### External Resources

**Spring Boot Debugging:**
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [JVM Troubleshooting](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/)

**Kubernetes Debugging:**
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

**Frontend Debugging:**
- [Chrome DevTools](https://developers.google.com/web/tools/chrome-devtools)
- [Angular Debugging](https://angular.io/guide/devtools)

### Escalation Contacts

**Debugging Support:**
- **Level 1**: Development team (same day)
- **Level 2**: Platform architects (next day)
- **Level 3**: External consultants (as needed)

**Emergency Contacts:**
- **Production Issues**: On-call engineer (24/7)
- **Security Issues**: Security team (immediate)
- **Infrastructure Issues**: Cloud provider support (business hours)
