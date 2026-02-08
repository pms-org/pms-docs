## Failure modes & debugging — pms-rttm

This section describes common failure scenarios, how they appear, and how to diagnose and remediate them. Intended for on-call engineers.

1) Kafka or Schema Registry unavailable

- Symptoms
  - Consumer exceptions in logs (connection timeouts, deserialization errors).
  - Consumers unable to read messages; metrics stop updating.

- Diagnosis
  - Check pod logs for Kafka connection errors.
  - Verify `KAFKA_BOOTSTRAP_SERVERS` and `SCHEMA_REGISTRY_URL` reachability from the pod.
  - Run `kafka-consumer-groups` from platform tooling to inspect consumer lag.

- Remediation
  - Restore Kafka/Schema Registry availability. If schema mismatch caused deserialization errors, inspect message payloads and schema versions.

2) PostgreSQL unavailable or slow

- Symptoms
  - DB exceptions in logs, slow inserts or timeouts, readiness probe failures if configured.
  - Aggregation jobs failing to persist.

- Diagnosis
  - Check DB connection logs; run a lightweight `SELECT 1` from the pod.
  - Check DB CPU, connection pool exhaustion, or long-running transactions.

- Remediation
  - Restore DB; consider increasing DB resources or tuning connection pools.

3) Redis / Sentinel failure

- Symptoms
  - Cache misses, inability to use Redis-backed structures, queue metadata not available.

- Diagnosis
  - Check `REDIS_SENTINEL_NODES` and Sentinel logs; from pod, test connectivity to Redis nodes.

- Remediation
  - Restore Sentinel/Redis; if TTLs were lost, some in-memory metrics may be temporarily incorrect.

4) In-memory queue overflow (BatchQueueService enqueue fails)

- Symptoms
  - Kafka consumers log warnings like "queue full/timed out, not acknowledging" and do not ack messages.
  - Kafka consumer group lag increases.

- Diagnosis
  - Check logs for enqueue warnings.
  - Inspect `RTTM_QUEUE_CAPACITY` and current application memory/CPU usage.

- Remediation
  - Increase `RTTM_QUEUE_CAPACITY` or scale replicas to increase processing throughput.
  - Investigate the downstream processing speed or long-running operations blocking the processing threads.

5) WebSocket instability or heavy client load

- Symptoms
  - Frequent open/close logs for WebSocket sessions, high CPU due to scheduling tasks for many sessions.
  - Clients report missing telemetry updates.

- Diagnosis
  - Check WebSocket handler logs; inspect number of open connections and thread usage.

- Remediation
  - Limit the number of concurrent WebSocket clients per instance via ingress or apply rate limits.
  - Offload to a dedicated telemetry service or increase instance resources.

6) Alert threshold misfires or noisy alerts

- Symptoms
  - Repeated alerts for conditions that are transient (false positives), or missing alerts when expected.

- Diagnosis
  - Review alert threshold configuration (under `rttm.alerts`), check raw metric values in DB for the evaluation window.

- Remediation
  - Tune thresholds and evaluation intervals. Implement alert suppression or deduplication at the alerting layer.

Debugging checklist (quick)

1. Check pod logs (`kubectl logs`) for consumer and enqueue warnings.
2. Inspect Kafka consumer group lag and topic offsets.
3. Check DB tables for recent aggregates, DLQ counts, and any failed inserts.
4. Check Redis Sentinel health and connectivity from pod.
5. If WebSocket issues: verify ingress supports WebSocket, review client connectivity and server resource usage.

If a problem is unclear, gather logs, failing record identifiers (message keys, tradeId), and timestamps, and escalate to platform or Kafka/DB teams with that data.
