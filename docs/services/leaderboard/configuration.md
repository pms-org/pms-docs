---
sidebar_position: 4
title: Configuration
---

# Leaderboard Service — Configuration

## Server

- **Port**: 8000 (configurable via `SERVER_PORT`)
- **Application Name**: wsdemo

## Database (PostgreSQL)

| Variable      | Default | Description       |
| ------------- | ------- | ----------------- |
| `DB_HOST`     | -       | Database host     |
| `DB_PORT`     | -       | Database port     |
| `DB_NAME`     | -       | Database name     |
| `DB_USERNAME` | -       | Database username |
| `DB_PASSWORD` | -       | Database password |

## Redis

| Variable               | Default           | Description                    |
| ---------------------- | ----------------- | ------------------------------ |
| `REDIS_HOST`           | -                 | Redis sentinel master name     |
| `REDIS_SENTINEL_NODES` | -                 | Comma-separated sentinel nodes |
| `REDIS_READ_FROM`      | REPLICA_PREFERRED | Read preference                |
| `REDIS_TIMEOUT`        | 10s               | Connection timeout             |

## Kafka

| Variable                            | Default                | Description          |
| ----------------------------------- | ---------------------- | -------------------- |
| `KAFKA_BOOTSTRAP_SERVERS`           | -                      | Bootstrap servers    |
| `SCHEMA_REGISTRY_URL`               | -                      | Schema registry URL  |
| `KAFKA_CONSUMER_GROUP_ID`           | -                      | Consumer group ID    |
| `KAFKA_CONSUMER_MAX_POLL_RECORDS`   | -                      | Max records per poll |
| `KAFKA_CONSUMER_ENABLE_AUTO_COMMIT` | -                      | Auto commit setting  |
| `KAFKA_CONSUMER_AUTO_OFFSET_RESET`  | -                      | Offset reset policy  |
| `KAFKA_RISK_TOPIC`                  | portfolio-risk-metrics | Risk metrics topic   |

## Behavior

- **Batch Processing**: Metrics updates processed in batches for efficiency
- **Score Calculation**: Composite scoring based on Sharpe ratio, Sortino ratio, and average return
- **Real-time Updates**: WebSocket broadcasting for live leaderboard changes
- **Health Monitoring**: Continuous Redis connectivity and Kafka consumer health checks
- **Snapshot Scheduling**: Periodic persistence of rankings to PostgreSQL
