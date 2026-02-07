## Failure modes & debugging — pms-validation

This file lists common failure scenarios, how they appear, quick diagnostics, and remediation steps. It’s written for on-call engineers.

1) Database unavailable (Postgres down or network issue)

- Symptoms
  - Logs show DB exceptions (e.g., `SELECT 1` failures) or `DataAccessResourceFailureException`.
  - ValidationBatchProcessor will log "DB Connection failure. Pausing consumer and returning batches to buffer." and pause the Kafka consumer.
  - `validationBuffer` size grows and no new messages are processed.
  - Readiness probe may fail if actuator health checks include DB.

- Diagnosis
  - Check pod logs for DB connection errors.
  - Verify network connectivity from pod to DB host (kubectl exec + psql or `telnet` to host:port) — platform permitted.
  - Check DB instance health, replication status, and connection limits.

- Remediation
  - Restore DB (start/repair network/security groups) and ensure credentials are valid.
  - The service will attempt to resume consumption automatically via `DbHealthMonitor` / recovery scheduler.
  - If buffer has grown large, monitor consumer resume and verify batch processing completes; consider scaling replicas temporarily to drain backlog.

2) Redis failure / Sentinel misconfiguration

- Symptoms
  - Errors from `TradeIdempotencyService` (Redis exceptions) in logs; idempotency reservations failing.
  - High duplicate processing or inability to mark DONE in Redis.

- Diagnosis
  - Check `spring.data.redis.sentinel.*` config and that sentinel nodes are reachable.
  - Inspect Redis Sentinel state and logs.
  - Use `kubectl exec` to run redis-cli against sentinel/masters (platform permitting).

- Remediation
  - Fix Sentinel/Redis cluster (restart pods, correct passwords).
  - If Redis TTLs are lost, be careful: trades may be reprocessed; deduplicate downstream if needed.

3) Kafka broker or Schema Registry unavailable

- Symptoms
  - Producer or consumer errors in logs (timeouts, connection exceptions).
  - Outbox dispatch failures when publishing; ValidationOutboxEventProcessor may classify serialization errors as poison or cause systemFailure.

- Diagnosis
  - Check broker and schema registry connectivity.
  - Confirm `KAFKA_BOOTSTRAP_SERVERS` and `SCHEMA_REGISTRY_URL` are correct and reachable.

- Remediation
  - Restore Kafka/Schema Registry.
  - If poison messages are observed due to schema mismatch, inspect DLQ entries (`validation_dlq_entry`) and address schema/versioning issues.

4) Serialization / schema errors (poison messages)

- Symptoms
  - Outbox dispatcher logs serialization exceptions or `IllegalArgumentException`.
  - The code persists those outbox entries to `validation_dlq_entry` and marks outbox as FAILED.

- Diagnosis
  - Query `validation_dlq_entry` for payloads and `error_detail`.
  - Try to deserialize payload with current protobuf definitions.

- Remediation
  - If payload is corrupted, leave it for offline analysis. If schema mismatch, coordinate with producers/consumers to align schema versions or perform migration.
  - For non-recoverable payloads, remove DLQ entries after analysis.

5) Long-running Drools evaluation or resource exhaustion

- Symptoms
  - Long processing times; thread pool saturation; high CPU usage.
  - Batch processing slows, `validationBuffer` grows.

- Diagnosis
  - Check application CPU/memory metrics and GC logs.
  - Profile or sample thread dumps to find blocked threads inside Drools evaluation.

- Remediation
  - Increase CPU/memory for pods, optimize Drools rules (simplify or split rulesets), or increase batch parallelism by scaling replicas and partitions.

6) Outbox stuck / dispatcher looping on same rows

- Symptoms
  - `validation_outbox` has many rows with `sent_status = 'PENDING'` and dispatcher logs repeated attempts.
  - If an entry is marked FAILED or persisted to DLQ, dispatcher will skip or treat as poison.

- Diagnosis
  - Inspect `validation_outbox` rows for a portfolio-level lock contention (the repository uses `pg_try_advisory_xact_lock` per portfolio).
  - Check dispatcher logs for repeated serialization exceptions.

- Remediation
  - Fix downstream Kafka connectivity or serialization issues.
  - If a particular outbox row is poison, it will be moved to DLQ; inspect DLQ table and address the root cause.

7) Consumer group rebalances / partition assignment issues

- Symptoms
  - Sudden pause/stop in processing during rebalance; `KafkaConsumerService` logs partition info.

- Diagnosis
  - Check Kafka broker logs and consumer group state (`kafka-consumer-groups` tool) to see lag and partition assignment.

- Remediation
  - Increase session timeouts or tune the consumer, ensure broker stability, or adjust number of partitions relative to replicas.

Debugging checklist (quick)

1. Check pod logs (`kubectl logs`) for stack traces and periodic warnings from `ValidationBatchProcessor`/`ValidationOutboxEventProcessor`.
2. Check Redis key for a specific trade: `trade:{tradeId}`. If state is PROCESSING and worker crashed, `clearProcessing` may be needed after investigation.
3. Examine DB tables: `validation_outbox`, `validation_invalid_trades`, `validation_dlq_entry` for stuck messages.
4. Check Kafka consumer group lag and partition assignments.
5. Check Schema Registry and broker connectivity (errors about `specific.protobuf.value.type` or schema registry will show in logs).
6. For poison messages, export payload bytes from `validation_dlq_entry` and attempt local deserialization with current protobuf definitions.

If you are unsure about a remediation step, escalate to the platform/Kafka or DBA teams with the logs and failing record identifiers (tradeId, outbox id, DLQ id).
