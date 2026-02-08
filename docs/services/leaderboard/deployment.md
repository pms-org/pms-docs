---
sidebar_position: 5
title: Deployment
---

# Leaderboard Service — Deployment

## Container Deployment

Deployed as Docker container in Kubernetes cluster behind API Gateway.

## Startup Dependencies

**Required Services (in order):**

1. PostgreSQL database (schema creation)
2. Redis sentinel cluster (high availability setup)
3. Kafka (topic availability)
4. Schema Registry (protobuf schemas)

## Health Checks

- **Readiness**: Redis connectivity and Kafka consumer initialization
- **Liveness**: Message processing thread health and Redis operations
- **Startup**: Database schema creation and Redis connection establishment

## Scaling

- **Horizontal Scaling**: Limited (single writer pattern for Redis)
- **Read Scaling**: Multiple read replicas supported via Redis cluster
- **Consumer Scaling**: Multiple pods can consume from same topic with different group IDs
- **WebSocket Scaling**: Sticky sessions required for WebSocket connections

## Resource Requirements

- **CPU**: Moderate (score calculations, Redis operations)
- **Memory**: High (Redis connection pooling, WebSocket sessions)
- **Storage**: Low (minimal local storage, relies on Redis/PostgreSQL)

## Environment Variables

All configuration via environment variables (no hardcoded values in production).

## Monitoring

- **Metrics**: Spring Boot actuator endpoints
- **Redis Monitoring**: Connection health, command latency
- **Kafka Monitoring**: Consumer lag, throughput metrics
- **WebSocket Monitoring**: Active connection counts

## Deployment Strategy

- **Rolling Updates**: Supported with proper draining of WebSocket connections
- **Graceful Shutdown**: Completes in-flight operations before termination
- **State Management**: Stateless except for WebSocket sessions (use sticky sessions)
