---
sidebar_position: 2
title: Architecture
---

# Leaderboard Service — Architecture

## High-Level Flow

Kafka Metrics → Batch Processing → Score Calculation → Redis Storage → API/WebSocket Serving

## Components

1. **Kafka Consumer**
   - Consumes portfolio risk metrics events
   - Handles batch processing for efficiency
   - Manages consumer group coordination

2. **Score Calculation Engine**
   - Computes composite scores from multiple metrics
   - Applies time-based weighting
   - Handles portfolio-specific calculations

3. **Redis Storage Layer**
   - Maintains sorted sets for rankings
   - Implements Lua scripts for atomic operations
   - Supports sentinel configuration for HA

4. **API Layer**
   - REST endpoints for leaderboard queries
   - WebSocket support for real-time updates
   - Pagination and filtering capabilities

5. **Health Monitoring**
   - Redis connectivity checks
   - Kafka consumer lag monitoring
   - Automatic recovery orchestration

## Data Model

### Redis Structures

**Sorted Set: `leaderboard:global:daily`**

- Members: Portfolio UUIDs
- Scores: Composite performance scores
- Ordering: Highest score first

**Hash: `leaderboard:portfolio:{uuid}`**

- Stores detailed portfolio metrics
- Sharpe ratio, Sortino ratio, average return
- Last update timestamp

**Stream: `leaderboard:stream`**

- Real-time update notifications
- WebSocket broadcast source

### PostgreSQL Tables

**leaderboard_snapshot**

- Periodic snapshots of rankings
- Historical performance data
- Scheduled persistence via Spring @Scheduled
