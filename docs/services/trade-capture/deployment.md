---
sidebar_position: 5
title: Deployment
---

# Trade Capture Service — Deployment

## Container Deployment

Deployed as Docker container in Kubernetes cluster behind API Gateway.

## Startup Dependencies

**Required Services (in order):**

1. PostgreSQL database (schema migration via Liquibase)
2. RabbitMQ (stream creation)
3. Kafka (topic availability)
4. Schema Registry (protobuf schemas)

## Health Checks

- **Readiness**: Database connection and RabbitMQ stream access
- **Liveness**: Message processing thread health
- **Startup**: Liquibase migrations completion

## Scaling

- **Horizontal Scaling**: Supported (multiple pods can consume from same stream)
- **Consumer Groups**: Each pod uses unique consumer group for load balancing
- **State Management**: Stateless except for stream offsets (managed by RabbitMQ)
- **Database**: Connection pooling handles multiple instances

## Resource Requirements

- **CPU**: Moderate (protobuf parsing, batch processing)
- **Memory**: High (message buffering, batch accumulation)
- **Storage**: Low (minimal local storage, relies on database)

## Environment Variables

All configuration via environment variables (no hardcoded values).

## Monitoring

- **Metrics**: Micrometer integration for JVM and application metrics
- **Logging**: Structured logging with correlation IDs
- **Health**: Spring Boot actuator endpoints
- **Stream Monitoring**: Consumer lag and throughput metrics

## Deployment Strategy

- **Rolling Updates**: Zero-downtime deployments
- **Graceful Shutdown**: Completes in-flight batches before termination
- **Stream Continuity**: Offset management ensures no message loss during restarts
