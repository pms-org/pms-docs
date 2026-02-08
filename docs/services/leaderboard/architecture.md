# Architecture

## Internal Design

The service follows an event-driven architecture optimized for write bursts and read-heavy traffic.

### Core Components

**Kafka Consumer**  
Receives score events and ensures offsets are committed only after successful buffering.

**Event Buffer**  
A bounded blocking queue that provides backpressure. Prevents Redis overload during spikes.

**Batch Processor**  
Aggregates events and performs bulk writes to Redis to reduce network overhead.

**Redis Score Layer**  
Uses sorted sets for rankings and hashes for metadata. Atomic Lua scripts ensure rank consistency.

**WebSocket Broadcaster**  
Pushes leaderboard updates to connected clients.

---

## Request / Event Flow

```
Kafka → Consumer → EventBuffer → Batch Processor
      → Redis (ZSET + HASH via Lua)
      → WebSocket Broadcast
      → REST Reads
```

### Read Path

```
Client → API Gateway → Ingress → Leaderboard Service → Redis → Response
```

Reads are served directly from Redis to minimize latency.

---

## State Management

| Component | Purpose |
|--------|------------|
| Redis ZSET | Ranking by score |
| Redis HASH | Player metadata |
| Streams (optional) | Event replay / durability |

Redis is treated as the operational data store for leaderboard state.

---

## Scaling Assumptions

The service scales horizontally under the assumption that:

- Kafka partitions distribute load evenly
- Consumers operate within a consumer group
- Redis can sustain concurrent writes

Backpressure protects Redis from sudden spikes.

Stateless application pods allow rapid scaling without coordination overhead.
