---
sidebar_position: 4
title: Configuration
---

# Trade Capture Service — Configuration

## Server

- **Port**: 8082 (default)
- **Application Name**: pms-trade-capture

## Database (PostgreSQL)

| Variable                  | Default   | Description                 |
| ------------------------- | --------- | --------------------------- |
| `DB_HOST`                 | localhost | Database host               |
| `DB_PORT`                 | 5432      | Database port               |
| `DB_NAME`                 | pmsdb     | Database name               |
| `DB_USERNAME`             | pms       | Database username           |
| `DB_PASSWORD`             | pms       | Database password           |
| `TRADE_CAPTURE_POOL_SIZE` | 20        | Hikari connection pool size |
| `DB_DDL_AUTO`             | update    | Hibernate DDL auto mode     |

## Message Processing

| Variable                      | Default | Description                         |
| ----------------------------- | ------- | ----------------------------------- |
| `INGEST_BATCH_MAX_SIZE`       | 500     | Max buffer size before forced flush |
| `INGEST_BATCH_FLUSH_INTERVAL` | 100ms   | Max wait time before flushing       |
| `INGEST_BATCH_DRAIN_SIZE`     | 500     | Max messages drained per flush      |
| `TRADE_CAPTURE_BATCH_SIZE`    | 500     | Hibernate JDBC batch size           |

## RabbitMQ Stream

| Variable                       | Default             | Description         |
| ------------------------------ | ------------------- | ------------------- |
| `RABBITMQ_STREAM_NAME`         | trade-stream        | Stream name         |
| `RABBITMQ_HOST`                | localhost           | RabbitMQ host       |
| `RABBITMQ_STREAM_PORT`         | 5552                | Stream port         |
| `TRADE_CAPTURE_CONSUMER_GROUP` | trade-capture-group | Consumer group name |
| `RABBITMQ_USERNAME`            | guest               | RabbitMQ username   |
| `RABBITMQ_PASSWORD`            | guest               | RabbitMQ password   |

## Kafka

| Variable                       | Default                     | Description            |
| ------------------------------ | --------------------------- | ---------------------- |
| `KAFKA_BOOTSTRAP_SERVERS`      | kafka:9092                  | Bootstrap servers      |
| `SCHEMA_REGISTRY_URL`          | http://schema-registry:8081 | Schema registry URL    |
| `KAFKA_PRODUCER_MAX_IN_FLIGHT` | 5                           | Max in-flight requests |
| `KAFKA_PRODUCER_LINGER_MS`     | 20                          | Producer linger time   |
| `KAFKA_PRODUCER_BATCH_SIZE`    | 65536                       | Producer batch size    |

## RTTM Client

| Variable                   | Default | Description                  |
| -------------------------- | ------- | ---------------------------- |
| `RTTM_MODE`                | kafka   | Client mode (kafka/rabbitmq) |
| `RTTM_SEND_TIMEOUT_MS`     | 3000    | Send timeout                 |
| `RTTM_RETRY_MAX_ATTEMPTS`  | 3       | Max retry attempts           |
| `RTTM_RETRY_BACKOFF_MS`    | 100     | Retry backoff                |
| `RTTM_METRICS_INTERVAL_MS` | 30000   | Metrics reporting interval   |

## Behavior

- **Batch Processing**: Messages are buffered and processed in batches for efficiency
- **Portfolio Ordering**: Events are published in strict portfolio order via outbox pattern
- **Failure Classification**: Distinguishes between poison pills (permanent) and system failures (transient)
- **Stream Offsets**: Automatically managed and committed after successful processing
- **DLQ Handling**: Invalid messages are stored for investigation without blocking processing
