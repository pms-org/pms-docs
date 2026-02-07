---
sidebar_position: 1
title: Overview
---

# Analytics Service — Overview

## Purpose

The `Analytics Service` is the computational engine of the PMS platform, responsible for transforming raw transactional data into actionable financial insights. It serves as the central hub for portfolio analytics, holdings tracking, profit & loss calculations, and risk assessment.

### Core Value Proposition

- **Real-time Portfolio Tracking**: Maintains up-to-the-second holdings and position data for all portfolios
- **Financial Metrics Computation**: Calculates both realised and unrealised P&L with market price integration
- **Risk Analytics**: Computes sophisticated risk metrics including Sharpe Ratio, Sortino Ratio, and Average Rate of Return
- **Sector Analysis**: Provides granular sector-level breakdowns and composition analysis
- **Event-Driven Architecture**: Processes transactional events asynchronously via Kafka for scalability
- **Real-time Broadcasting**: Publishes live updates via WebSocket for immediate dashboard reflection

## Responsibilities

### Data Processing & Computation

- **Holdings Management**: Track quantity, invested amount, and current value per portfolio per symbol
- **Realised P&L Calculation**: Compute profit/loss on closed positions using FIFO methodology
- **Unrealised P&L Calculation**: Calculate paper gains/losses on open positions using current market prices
- **Position Aggregation**: Maintain accurate position data across multiple trades and symbols

### Market Data Integration

- **Price Fetching**: Periodic retrieval of current market prices from Finnhub API
- **Price Caching**: Redis-based caching to reduce external API calls and improve performance
- **Price Update Scheduling**: Automated price refresh every 20 seconds during market hours

### Risk Metrics Computation

- **Sharpe Ratio**: Risk-adjusted return metric accounting for volatility
- **Sortino Ratio**: Downside risk-adjusted return metric focusing on negative volatility
- **Average Rate of Return**: Portfolio performance metric over time
- **Daily Snapshotting**: Portfolio value history for trend analysis

### Sector Analytics

- **Sector Composition**: Breakdown of holdings by industry sector
- **Sector Performance**: P&L and metrics aggregated at sector level
- **Cross-Portfolio Analysis**: Overall platform-wide sector distribution
- **Drilldown Capabilities**: Symbol-level metrics within each sector

### Event Publishing

- **Position Updates**: Real-time WebSocket broadcasts of holding changes
- **Unrealised P&L Updates**: Live streaming of unrealised gains/losses
- **Risk Event Publishing**: Kafka-based distribution of risk metrics to downstream services
- **Transaction Acknowledgment**: Outbox pattern implementation for reliable event delivery

## Consumers

### Frontend Application
- **Dashboard Views**: Real-time portfolio summaries and metrics
- **Portfolio Details**: Holding positions, P&L, and performance charts
- **Sector Analysis UI**: Composition breakdowns and sector performance
- **Performance Charts**: Historical value trends and returns visualization

### Leaderboard Service
- **Risk Metrics Consumption**: Receives Sharpe, Sortino, and return metrics via Kafka
- **Rankings Computation**: Uses metrics for portfolio performance rankings
- **Real-time Updates**: Processes risk events for live leaderboard updates

### WebSocket Clients
- **Position Subscribers**: Receive immediate holding update notifications
- **P&L Subscribers**: Get live unrealised P&L calculations
- **Multi-tenant Support**: Portfolio-specific subscriptions and filtering

### API Gateway
- **Request Routing**: Routes external REST calls to analytics endpoints
- **Authentication Enforcement**: JWT validation before request forwarding
- **Rate Limiting**: Prevents API abuse and ensures fair usage

## High-Level Dependencies

### Event Streaming
- **Kafka (Primary)**: 
  - Consumes: `transactions` topic (trade execution events)
  - Produces: `risk-events` topic (risk metrics for downstream services)
  - Batch Processing: Configurable batch sizes for optimal throughput
  - Consumer Groups: Dedicated group for transaction processing

### Data Storage
- **PostgreSQL (PMS DB)**:
  - `analytics` table: Core holdings and metrics data
  - `portfolio_value_history` table: Daily value snapshots
  - `transactions` table: Trade history for P&L calculations
  - `analysis_outbox` table: Outbox pattern for reliable event publishing
  - ACID transactions for data consistency

### Caching Layer
- **Redis**:
  - Key Pattern: `price:{symbol}` → Current market price
  - TTL: 30 seconds (aligned with scheduler refresh)
  - Fallback Strategy: Service continues without cache if Redis is down
  - Performance Benefit: Reduces Finnhub API calls by ~95%

### External APIs
- **Finnhub API**:
  - Endpoint: `https://finnhub.io/api/v1/quote`
  - Rate Limit: 60 calls/minute (free tier)
  - Authentication: API key via query parameter
  - Response: Real-time stock quote data including current price

### Infrastructure Services
- **API Gateway**: Single entry point, authentication, rate limiting
- **Auth Service**: JWT token validation and user context
- **Kubernetes (EKS)**: Container orchestration, scaling, health management
- **Ingress Controller**: External traffic routing and load balancing

## Technology Stack

### Core Framework
- **Spring Boot 3.x**: Application framework
- **Spring WebFlux**: Reactive WebSocket support
- **Spring Kafka**: Event streaming integration
- **Spring Data JPA**: Database access layer

### Communication
- **Protocol Buffers**: Efficient binary serialization for Kafka messages
- **STOMP over WebSocket**: Real-time bi-directional communication
- **REST/HTTP**: Synchronous API endpoints

### Observability
- **SLF4J + Logback**: Structured logging
- **Spring Actuator**: Health checks and metrics exposure
- **Prometheus**: Metrics collection (future enhancement)

## Service Characteristics

### Scalability
- **Horizontal Scaling**: Stateless design allows multiple pod replicas
- **Batch Processing**: Configurable batch sizes for throughput optimization
- **Async Processing**: Non-blocking operations for high concurrency
- **Buffer Management**: In-memory queue for Kafka message buffering

### Reliability
- **Idempotency**: Duplicate transaction detection and handling
- **Outbox Pattern**: Reliable event publishing with guaranteed delivery
- **Graceful Degradation**: Continues operation if Redis is unavailable
- **Retry Logic**: Automatic retries for transient failures

### Performance
- **Redis Caching**: Sub-millisecond price lookups
- **Batch Database Operations**: Reduced DB roundtrips
- **Connection Pooling**: Efficient resource utilization
- **Async Finnhub Calls**: Non-blocking external API integration

## Key Metrics & SLAs

### Performance Targets
- **Transaction Processing**: < 100ms per batch of 100 transactions
- **API Response Time**: < 200ms for p95
- **WebSocket Latency**: < 50ms from event to client delivery
- **Price Update Interval**: 20 seconds during market hours

### Availability
- **Target Uptime**: 99.5% during market hours
- **Graceful Degradation**: Service continues without Redis or Finnhub
- **Health Checks**: Liveness (JVM) and Readiness (DB + Kafka)

## Data Flow Summary

```
Trade Execution
    ↓
Kafka (transactions topic)
    ↓
Analytics Consumer (Batch Processing)
    ↓
    ├─→ Holdings Calculation
    ├─→ Realised P&L Calculation
    └─→ Database Persistence
         ↓
         ├─→ WebSocket Broadcast (Position Update)
         └─→ Outbox Table (Risk Events)
              ↓
         Outbox Processor
              ↓
         Kafka (risk-events topic)
              ↓
         Downstream Services (Leaderboard)
```

