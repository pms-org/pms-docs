---
sidebar_position: 1
title: Overview
---

# Trade Capture Service — Overview

## Purpose

The Trade Capture Service is responsible for ingesting raw trade data from streaming sources (RabbitMQ streams), validating and transforming the data, and publishing processed trade events to downstream systems via Kafka. It implements a production-grade outbox pattern to ensure reliable event publishing with guaranteed ordering.

## Responsibilities

- Consume trade data from RabbitMQ streams
- Validate and transform protobuf-encoded trade messages
- Persist trades to PostgreSQL with audit trail
- Publish validated trades to Kafka topics
- Handle message replay for testing and recovery
- Implement dead letter queue (DLQ) for invalid messages
- Ensure portfolio-level trade ordering in event publishing

## Consumers

- Analytics Service (trade event processing)
- Simulation Service (portfolio performance calculation)
- Risk Management Service (RTTM)
- Internal monitoring and reporting systems

## Dependencies

- PostgreSQL database (trade storage and outbox)
- RabbitMQ (stream ingestion)
- Kafka (event publishing)
- Schema Registry (protobuf schema management)
- RTTM Client (trade event routing)
