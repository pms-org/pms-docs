---
sidebar_position: 4
title: Runbooks
---

# Runbooks

This document contains operational runbooks for common procedures, incident response, and maintenance tasks in the PMS platform.

## Overview

Runbooks provide step-by-step instructions for operational tasks, ensuring consistency and reducing resolution time for common issues.

## Table of Contents

1. [Service Restart Procedures](#service-restart-procedures)
2. [Database Maintenance](#database-maintenance)
3. [Backup and Recovery](#backup-and-recovery)
4. [Scaling Procedures](#scaling-procedures)
5. [Security Incident Response](#security-incident-response)
6. [Performance Issues](#performance-issues)
7. [Network Issues](#network-issues)
8. [Monitoring Maintenance](#monitoring-maintenance)

---

## Service Restart Procedures

### Emergency Service Restart

**When to Use:**
- Service is unresponsive
- High error rates (>10%)
- Memory leaks detected
- Critical alerts firing

**Procedure:**

1. **Assess Impact:**
   ```bash
   # Check current service status
   kubectl get pods -n pms -l app=pms-analytics

   # Check service metrics
   kubectl top pods -n pms
   ```

2. **Notify Stakeholders:**
   - Slack: #platform-alerts
   - Email: platform-team@pms-platform.com
   - PagerDuty: Create incident

3. **Graceful Shutdown:**
   ```bash
   # Scale down gracefully
   kubectl scale deployment pms-analytics --replicas=0 -n pms

   # Wait for pods to terminate
   kubectl get pods -n pms -l app=pms-analytics -w
   ```

4. **Restart Service:**
   ```bash
   # Scale back up
   kubectl scale deployment pms-analytics --replicas=3 -n pms

   # Monitor startup
   kubectl logs -f deployment/pms-analytics -n pms
   ```

5. **Verify Health:**
   ```bash
   # Check readiness
   kubectl get pods -n pms -l app=pms-analytics

   # Test endpoints
   curl -f https://api.pms-platform.com/api/analytics/health
   ```

6. **Update Incident:**
   - Close PagerDuty incident
   - Update stakeholders
   - Document root cause

### Rolling Restart

**When to Use:**
- Configuration changes
- Non-critical updates
- Zero-downtime required

**Procedure:**

```bash
# Perform rolling restart
kubectl rollout restart deployment/pms-analytics -n pms

# Monitor rollout progress
kubectl rollout status deployment/pms-analytics -n pms

# Check rollout history
kubectl rollout history deployment/pms-analytics -n pms
```

---

## Database Maintenance

### Daily Maintenance

**Backup Verification:**
```bash
# Check backup status
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier pms-database \
  --snapshot-type automated \
  --query 'DBClusterSnapshots[0].SnapshotCreateTime'

# Verify backup integrity
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier pms-database \
  --query 'DBClusterSnapshots[0].Status'
```

**Index Maintenance:**
```sql
-- Update table statistics
ANALYZE VERBOSE;

-- Check for unused indexes
SELECT schemaname, tablename, indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Weekly Maintenance

**Vacuum Operations:**
```sql
-- Vacuum analyze for all tables
VACUUM ANALYZE;

-- Check for bloat
SELECT schemaname, tablename,
       n_dead_tup, n_live_tup,
       ROUND(n_dead_tup::float / (n_live_tup + n_dead_tup) * 100, 2) as bloat_ratio
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY bloat_ratio DESC;
```

**Long-Running Query Analysis:**
```sql
-- Find queries running > 5 minutes
SELECT pid, now() - pg_stat_activity.query_start AS duration,
       query
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - pg_stat_activity.query_start > interval '5 minutes';
```

### Monthly Maintenance

**Index Rebuild:**
```sql
-- Rebuild fragmented indexes
REINDEX INDEX CONCURRENTLY idx_portfolio_positions_portfolio_id;

-- Check index health
SELECT indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

**Table Partitioning Review:**
```sql
-- Check partition sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename LIKE '%_partition_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Backup and Recovery

### Automated Backups

**RDS Aurora Backups:**
- **Frequency:** Daily automated snapshots
- **Retention:** 30 days
- **Location:** Cross-region replication
- **Encryption:** AWS KMS

**Application Backups:**
- **Configuration:** Git repository
- **Container Images:** ECR with immutable tags
- **Logs:** S3 with lifecycle policies

### Manual Backup

**Database Backup:**
```bash
# Create manual snapshot
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier pms-database \
  --db-cluster-snapshot-identifier manual-backup-$(date +%Y%m%d-%H%M%S)

# Monitor snapshot creation
aws rds describe-db-cluster-snapshots \
  --db-cluster-snapshot-identifier manual-backup-$(date +%Y%m%d-%H%M%S) \
  --query 'DBClusterSnapshots[0].Status'
```

**Configuration Backup:**
```bash
# Backup Helm values
helm get values pms-platform -n pms > backup-values-$(date +%Y%m%d).yaml

# Backup ArgoCD applications
kubectl get applications -n argocd -o yaml > argocd-backup-$(date +%Y%m%d).yaml
```

### Recovery Procedures

**Point-in-Time Recovery:**
```bash
# Restore to specific time
aws rds restore-db-cluster-to-point-in-time \
  --db-cluster-identifier pms-database \
  --restore-to-time 2026-02-09T10:00:00Z \
  --db-cluster-identifier pms-database-restored

# Update application configuration
kubectl set env deployment/pms-analytics \
  DB_HOST=pms-database-restored.cluster-xxxxx.us-east-1.rds.amazonaws.com -n pms
```

**Application Rollback:**
```bash
# Rollback to previous Helm release
helm rollback pms-platform 1 -n pms

# Verify rollback
helm history pms-platform -n pms
```

**Complete Environment Recovery:**
1. Restore database from backup
2. Deploy infrastructure with Terraform
3. Deploy applications with ArgoCD
4. Update DNS and load balancers
5. Verify all services functional

---

## Scaling Procedures

### Horizontal Scaling

**Automatic Scaling:**
```yaml
# HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pms-analytics-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pms-analytics
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Manual Scaling:**
```bash
# Scale specific service
kubectl scale deployment pms-analytics --replicas=5 -n pms

# Scale all services
kubectl get deployments -n pms -o name | \
  xargs -I {} kubectl scale {} --replicas=5 -n pms
```

### Vertical Scaling

**Pod Resource Adjustment:**
```bash
# Update resource requests/limits
kubectl set resources deployment pms-analytics \
  --requests=cpu=1000m,memory=2Gi \
  --limits=cpu=2000m,memory=4Gi -n pms
```

**Node Group Scaling:**
```bash
# Scale EKS node group
aws eks update-nodegroup-config \
  --cluster-name pms-dev \
  --nodegroup-name pms-nodes \
  --scaling-config minSize=3,maxSize=10,desiredSize=5
```

### Database Scaling

**Read Replica Scaling:**
```bash
# Add read replica
aws rds create-db-instance \
  --db-instance-identifier pms-database-replica \
  --db-cluster-identifier pms-database \
  --db-instance-class db.r7g.large

# Update application to use read replicas
kubectl set env deployment/pms-analytics \
  DB_READ_REPLICA_HOST=pms-database-replica.cluster-xxxxx.us-east-1.rds.amazonaws.com -n pms
```

---

## Security Incident Response

### Data Breach Response

**Immediate Actions:**
1. **Isolate Affected Systems:**
   ```bash
   # Quarantine compromised pods
   kubectl cordon <node-name>

   # Block suspicious IPs
   aws ec2 authorize-security-group-ingress \
     --group-id <security-group-id> \
     --protocol tcp --port 80 --cidr 0.0.0.0/0 --revoke
   ```

2. **Preserve Evidence:**
   ```bash
   # Capture logs
   kubectl logs --all-containers --timestamps deployment/pms-analytics > incident-logs-$(date +%s).txt

   # Create forensic snapshots
   aws ec2 create-snapshot --volume-id <volume-id> --description "Security incident evidence"
   ```

3. **Notify Authorities:**
   - Report to relevant regulatory bodies
   - Notify affected customers
   - Update security team

### Unauthorized Access

**Response Procedure:**
1. **Change Credentials:**
   ```bash
   # Rotate database passwords
   aws secretsmanager update-secret \
     --secret-id pms/dev/database \
     --secret-string '{"username":"pms_user","password":"new_password"}'

   # Update application secrets
   kubectl rollout restart deployment/pms-analytics -n pms
   ```

2. **Review Access Logs:**
   ```bash
   # Check CloudTrail logs
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin

   # Review application access logs
   aws logs filter-log-events --log-group-name /aws/alb/pms-alb
   ```

3. **Strengthen Security:**
   - Implement MFA requirements
   - Update security groups
   - Review IAM policies

---

## Performance Issues

### High CPU Usage

**Diagnosis:**
```bash
# Check pod CPU usage
kubectl top pods -n pms

# Check JVM thread dumps
kubectl exec -it deployment/pms-analytics -- \
  jstack 1 > cpu-analysis-$(date +%s).txt
```

**Resolution:**
```bash
# Scale horizontally
kubectl scale deployment pms-analytics --replicas=5 -n pms

# Optimize JVM settings
kubectl set env deployment/pms-analytics \
  JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200" -n pms
```

### Memory Issues

**Diagnosis:**
```bash
# Check memory usage
kubectl top pods -n pms

# Generate heap dump
kubectl exec -it deployment/pms-analytics -- \
  jmap -dump:format=b,file=/tmp/heap.hprof 1
```

**Resolution:**
```bash
# Increase memory limits
kubectl set resources deployment pms-analytics \
  --limits=memory=4Gi -n pms

# Enable memory profiling
kubectl set env deployment/pms-analytics \
  JAVA_OPTS="-Xmx3g -XX:+HeapDumpOnOutOfMemoryError" -n pms
```

### Database Performance

**Slow Query Diagnosis:**
```sql
-- Find slow queries
SELECT query, total_time, calls, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Check locks
SELECT * FROM pg_locks WHERE granted = false;
```

**Optimization:**
```sql
-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_portfolio_positions_symbol
ON portfolio_positions (symbol);

-- Update statistics
ANALYZE portfolio_positions;
```

---

## Network Issues

### Service Connectivity

**Diagnosis:**
```bash
# Test service DNS
kubectl run dns-test --image=busybox --rm -it -- \
  nslookup pms-analytics.pms.svc.cluster.local

# Test connectivity
kubectl run connectivity-test --image=busybox --rm -it -- \
  wget --timeout=5 -qO- http://pms-analytics:8080/actuator/health
```

**Resolution:**
```bash
# Check service endpoints
kubectl get endpoints pms-analytics -n pms

# Restart service if endpoints are empty
kubectl rollout restart deployment/pms-analytics -n pms
```

### Load Balancer Issues

**Diagnosis:**
```bash
# Check ALB health
aws elbv2 describe-target-health --target-group-arn <arn>

# Check ALB logs
aws logs filter-log-events \
  --log-group-name /aws/alb/pms-alb \
  --filter-pattern '"502" OR "503" OR "504"'
```

**Resolution:**
```bash
# Deregister unhealthy targets
aws elbv2 deregister-targets \
  --target-group-arn <arn> \
  --targets Id=<instance-id>

# Check security groups
aws ec2 describe-security-groups --group-ids <alb-sg>
```

---

## Monitoring Maintenance

### Alert Tuning

**Review Alert Effectiveness:**
```bash
# Check alert firing frequency
kubectl get prometheusrules -n monitoring

# Analyze alert patterns
# Use Grafana to review alert history
```

**Update Alert Thresholds:**
```yaml
# Adjust based on baseline metrics
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.03  # Reduced from 0.05
for: 10m  # Increased from 5m
```

### Dashboard Maintenance

**Update Dashboards:**
- Add new service metrics
- Remove obsolete panels
- Update thresholds based on trends
- Improve visualization clarity

**Performance Optimization:**
```bash
# Optimize Prometheus queries
# Reduce query resolution for long time ranges
# Implement data aggregation
```

### Log Rotation

**Configure Log Retention:**
```yaml
# Elasticsearch ILM policy
{
  "policy": {
    "phases": {
      "hot": {"min_age": "0ms", "actions": {"rollover": {"max_age": "1d"}}},
      "warm": {"min_age": "30d", "actions": {"shrink": {"number_of_shards": 1}}},
      "delete": {"min_age": "90d", "actions": {"delete": {}}}
    }
  }
}
```

---

## Emergency Procedures

### Complete System Outage

**Immediate Response:**
1. **Assess Scope:** Determine affected services and users
2. **Communicate:** Notify stakeholders and customers
3. **Prioritize Recovery:** Start with critical services
4. **Parallel Recovery:** Recover multiple services simultaneously

**Recovery Steps:**
```bash
# 1. Check infrastructure
kubectl get nodes
aws rds describe-db-clusters --db-cluster-identifier pms-database

# 2. Restore from backup if needed
# 3. Deploy services in dependency order
kubectl apply -f pms-infra/argocd/applications/pms-platform.yaml

# 4. Verify functionality
# 5. Update stakeholders
```

### Data Loss Incident

**Response Protocol:**
1. **Stop Operations:** Prevent further data loss
2. **Assess Damage:** Determine scope of data loss
3. **Restore from Backup:** Use most recent clean backup
4. **Validate Data:** Ensure data integrity
5. **Resume Operations:** Gradually bring services back online

### Communication Templates

**Initial Notification:**
```
Subject: PMS Platform Incident - Service Disruption

Dear Stakeholders,

We are experiencing a service disruption affecting [describe impact].
Our team is actively investigating and implementing recovery procedures.

Status: 🔴 ACTIVE INCIDENT
Impact: [High/Medium/Low]
Estimated Resolution: [timeframe]

We will provide updates every 30 minutes.
```

**Resolution Update:**
```
Subject: RESOLVED - PMS Platform Incident

The service disruption has been resolved.

Root Cause: [brief description]
Impact Duration: [time period]
Affected Services: [list]

Corrective Actions:
- [action 1]
- [action 2]
- [action 3]

Post-mortem analysis will be completed within 24 hours.
```

---

## Runbook Maintenance

### Regular Updates

**Monthly Review:**
- Update contact information
- Review procedure effectiveness
- Incorporate lessons learned
- Update tool versions and commands

**After Incidents:**
- Document new issues encountered
- Update procedures based on resolution
- Add preventive measures
- Update monitoring and alerting

### Testing and Validation

**Quarterly Testing:**
- Test backup restoration procedures
- Validate disaster recovery procedures
- Perform failover testing
- Update contact lists

**Documentation Standards:**
- Use clear, actionable language
- Include verification steps
- Document prerequisites
- Provide rollback procedures
