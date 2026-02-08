**Common Failure Scenarios & Debugging**

1. Database connectivity failure

- How it appears: errors in logs from `BatchProcessor.flushBatch()` / `JdbcTemplate` errors; logs show "DB Connection failure. Pausing consumer." or repeated DB probe warnings from the recovery daemon.
- Diagnosis steps:
  - Check connectivity: run `SELECT 1` against the configured JDBC URL.
  - Check application logs for stack traces referencing `DataAccessResourceFailureException` or "Database is up! Resuming consumer" messages.
  - Inspect K8s readiness probes; when DB is down the service may pause consumption but keep running.
- Recovery: restore DB connectivity. `BatchProcessor` starts a background probe (`dbRecoveryScheduler`) and will resume the Kafka consumer automatically when `SELECT 1` succeeds.

2. Kafka publish/send failures (outbox dispatch)

- How it appears: Outbox dispatcher logs: "Kafka send timeout after Xms" or `SystemFailureException`; `OutboxDispatcher` increases backoff and retries.
- Diagnosis steps:
  - Check broker connectivity (`spring.kafka.bootstrap-servers`) and Schema Registry URL.
  - Inspect `outbox_events` rows for `PENDING` items (they will be retried by the dispatcher).
  - Check `OutboxEventProcessor` logs for `PoisonPillException` (serialization problems) or `RecordTooLargeException`.
- Remediation:
  - Fix Schema Registry mismatch or broker connectivity.
  - For poison-pill (invalid payload) the code moves the event to `invalid_trades` and marks outbox FAILED; inspect `invalid_trades.error_message`.

3. Poison pill / invalid protobuf payload

- How it appears: `OutboxEventProcessor` logs "Poison pill detected" and the event is moved to DLQ (`invalid_trades`) with an error message.
- Diagnosis: query `invalid_trades` table and inspect `error_message` and `payload`.

4. Buffer overload / backpressure

- How it appears: `BatchProcessor` logs "Buffer reached 80 percent. Pausing and clearing 50 percent" and will pause the Kafka consumer.
- Diagnosis: check buffer size config (`app.buffer.size`) and `app.batch.size`. Inspect application logs printing buffer warnings.
- Remediation: scale consumers (more partitions + replicas), increase buffer size, or tune `app.batch.size` and flush interval.

5. Inconsistent matching / invalid sells

- How it appears: the system writes rows to `invalid_trades` with messages like "No eligible previous buys available" or "Insufficient quantity for ...".
- Diagnosis: query `invalid_trades` and inspect `payload` and `error_message`. The `TransactionService.handleInvalid(...)` records these.

Debugging queries (Postgres)

- Check pending outbox events:

```sql
SELECT * FROM outbox_events WHERE status = 'PENDING' ORDER BY created_at LIMIT 100;
```

- Check invalid trades (DLQ):

```sql
SELECT * FROM invalid_trades ORDER BY invalid_trade_id DESC LIMIT 50;
```

- Check transactions for a portfolio/symbol:

```sql
SELECT * FROM transactions t JOIN trades tr ON t.trade_id = tr.trade_id WHERE tr.portfolio_id = '<uuid>' AND tr.symbol = '<SYM>' ORDER BY tr.timestamp;
```

Useful log messages to search

- "DB Connection failure. Pausing consumer." (DB problems)
- "Kafka send timeout" or "Kafka system failure" (outbox/kafka send faults)
- "Poison pill detected" (bad payload)
- "Buffer reached 80 percent" (backpressure)

When on-call

- Check service logs and Kubernetes pod status first.
- Validate DB and Kafka network access.
- Inspect `outbox_events` and `invalid_trades` tables using SQL; moving a poison pill to DLQ is automatic but requires investigation of the source trade.
