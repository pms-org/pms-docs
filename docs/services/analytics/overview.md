# Analytics — Service Overview

## Purpose

`Analytics Service` is responsible for computing portfolio analytics, holdings, profit & loss metrics, unrealised PnL, and risk metrics within the PMS platform.  
It transforms transactional trade data into portfolio-level financial insights consumed by the frontend dashboard and downstream services such as Leaderboard.

## Responsibilities

- Maintain portfolio holdings per portfolio and symbol
- Calculate invested amount
- Calculate realised PnL
- Calculate unrealised PnL using current market prices
- Fetch and cache current market prices
- Publish real-time position updates via WebSocket topics
- Compute risk metrics (Average Rate of Return, Sharpe Ratio, Sortino Ratio)
- Expose analytics APIs for dashboards and reporting
- Produce risk events for downstream services

## Consumers

- Frontend UI — dashboards, portfolio views, sector composition
- Leaderboard Service — consumes risk metrics
- WebSocket clients — receive real-time updates
- API Gateway — routes external REST calls

## High-Level Dependencies

- Kafka — consumes transaction events and publishes analytics/risk events
- PMS DB — persistent storage for analytics and portfolio value history
- Redis — caching of current market prices
- Finnhub API — external price feed
- API Gateway & Auth Service — access control
- Kubernetes (EKS) — runtime environment
