# Leaderboard Service — Overview

## Purpose

The Leaderboard Service provides near real-time ranking capabilities for the PMS platform. It ingests player score events, computes rankings, and exposes the current leaderboard to downstream consumers.

This service is designed for high-throughput event processing with low-latency read access.

## Responsibilities

The service is responsible for:

- Consuming score events from Kafka
- Buffering and batching events to control write pressure
- Updating rankings in Redis using atomic operations
- Serving leaderboard data via REST APIs
- Broadcasting updates over WebSockets
- Maintaining operational resilience during transient infrastructure failures

The service does **not** act as the system of record for historical data. Persistent storage, if present, is treated as secondary to real-time leaderboard availability.

## Consumers

The service is consumed by:

- Frontend clients (via API Gateway + Ingress) for leaderboard views
- Backend services that require ranking data
- Real-time UI components through WebSocket updates

## High-Level Dependencies

- **Kafka** — Event ingestion
- **Redis (Sentinel / HA)** — Primary data store for rankings
- **Kubernetes (EKS)** — Runtime platform
- **API Gateway + Ingress** — External routing
- **Schema Registry / Protobuf** — Event schema enforcement

The service is horizontally scalable and designed to tolerate partial infrastructure degradation without fully interrupting leaderboard reads.
