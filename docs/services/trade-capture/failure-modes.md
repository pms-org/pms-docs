---
sidebar_position: 7
title: Failure Modes
---

# Trade Capture Service — Failure Modes

## Database Connection Failure

**Symptoms:**

- Service fails to start
- Liquibase migrations cannot run

**Cause:**

- Incorrect database credentials
- Database server unreachable
- Network connectivity issues

**Behavior:**

- Application startup fails
- Container restart loops

**Debug:**

- Check database connectivity
- Verify environment variables
- Review database server logs

---

## RabbitMQ Stream Unavailable

**Symptoms:**

- No message consumption
- Stream consumer manager errors

**Cause:**

- RabbitMQ server down
- Stream not created
- Network partition

**Behavior:**

- Graceful degradation (no crash)
- Automatic reconnection attempts
- Message processing paused

**Debug:**

- Check RabbitMQ cluster health
- Verify stream exists
- Review network connectivity

---

## Kafka Publishing Failure

**Symptoms:**

- Outbox events accumulate
- Publishing retries exhausted

**Cause:**

- Kafka brokers unreachable
- Topic authorization issues
- Schema registry unavailable

**Behavior:**

- Events remain in PENDING status
- Exponential backoff retry
- System failure classification

**Debug:**

- Check Kafka cluster health
- Verify topic permissions
- Review schema registry connectivity

---

## Invalid Message Processing

**Symptoms:**

- Messages moved to DLQ
- Safe store marked as invalid

**Cause:**

- Protobuf deserialization failure
- Schema validation errors
- Business rule violations

**Behavior:**

- Message processing continues
- Raw bytes stored for investigation
- No outbox event created

**Debug:**

- Review DLQ entries
- Check message format
- Validate protobuf schemas

---

## Batch Processing Deadlock

**Symptoms:**

- Message processing stalls
- Buffer fills without draining

**Cause:**

- Database transaction locks
- Concurrent portfolio processing conflicts

**Behavior:**

- Automatic retry with backoff
- FOR UPDATE SKIP LOCKED prevents deadlocks

**Debug:**

- Check database lock waits
- Review transaction isolation
- Monitor batch processing metrics

---

## Memory Pressure

**Symptoms:**

- OutOfMemoryError
- Buffer overflow

**Cause:**

- Large message batches
- Memory leaks in processing

**Behavior:**

- JVM crash and restart
- Message loss possible

**Debug:**

- Monitor heap usage
- Adjust batch size parameters
- Review garbage collection logs

---

## Portfolio Ordering Violation

**Symptoms:**

- Events published out of order
- Downstream processing errors

**Cause:**

- Race conditions in outbox processing
- Incorrect transaction boundaries

**Behavior:**

- Portfolio-level isolation prevents this
- Prefix-safe batch processing

**Debug:**

- Check outbox event ordering
- Review transaction logs
- Validate portfolio isolation logic
