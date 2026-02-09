---
sidebar_position: 2
title: Architecture
---

# Trade Capture Service — Architecture

## High-Level Flow

RabbitMQ Stream → Batching Ingest Service → Validation & Persistence → Outbox Pattern → Kafka Publishing

## Components

1. **Stream Consumer Manager**
   - Manages RabbitMQ stream connections
   - Handles offset tracking and consumer groups
   - Implements batching for efficient processing

2. **Batching Ingest Service**
   - Buffers incoming messages in memory
   - Performs batch validation and persistence
   - Routes valid/invalid messages appropriately

3. **Outbox Dispatcher**
   - Implements portfolio-level ordering guarantees
   - Publishes events to Kafka with retry logic
   - Handles poison pill vs system failure classification

4. **Batch Persistence Service**
   - Saves validated trades to PostgreSQL
   - Maintains audit trail in safe store
   - Manages dead letter queue for invalid messages

## Data Model

### Core Tables

**safe_store_trade**

- Raw trade data with validation status
- Audit trail for all ingested messages

**outbox_event**

- Pending events for Kafka publishing
- Portfolio-level ordering constraints

**dlq_entry**

- Invalid messages for manual investigation
- Error details and raw message bytes

### Key Design Patterns

1. **Outbox Pattern**: Guarantees reliable event publishing
2. **Portfolio Isolation**: Ensures trade ordering per portfolio
3. **Poison Pill Classification**: Distinguishes permanent vs transient failures
4. **Batch Processing**: Optimizes database and network I/O
