---
sidebar_position: 1
title: Overview
---

# Leaderboard Service — Overview

## Purpose

The Leaderboard Service maintains real-time portfolio performance rankings using Redis sorted sets. It consumes risk metrics from Kafka, computes composite scores, and provides leaderboard APIs for top performers and portfolio-specific rankings. The service includes WebSocket support for real-time updates and implements Redis sentinel for high availability.

## Responsibilities

- Consume portfolio risk metrics from Kafka
- Calculate composite performance scores
- Maintain sorted leaderboards in Redis
- Provide REST APIs for leaderboard queries
- Support WebSocket real-time updates
- Implement Redis health monitoring and recovery
- Handle batch processing of metrics updates

## Consumers

- Frontend applications (portfolio rankings display)
- Trading platforms (performance comparisons)
- Analytics dashboards (leaderboard widgets)
- Mobile applications (portfolio standings)

## Dependencies

- Redis (sorted set storage and caching)
- PostgreSQL (snapshot persistence)
- Kafka (metrics event consumption)
- Schema Registry (protobuf schema management)
