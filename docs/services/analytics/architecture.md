# Internal Architecture

## Logical Layers

1. Event Consumer Layer
   - Kafka consumer for `transactions` topic

2. Computation Layer
   - Holdings calculator
   - Realised PnL engine
   - Unrealised PnL engine
   - Risk metrics calculator

3. State Management Layer
   - PMS DB (analytics tables, portfolio value history)
   - Redis cache (current prices)

4. API & WebSocket Layer
   - REST controllers
   - WebSocket publishers

5. Outbox & Publisher Layer
   - Risk metrics publisher
   - Position update publisher

---

## Transaction Event Flow

Kafka (transactions topic)  
↓  
Analytics Consumer  
↓  
Holdings & Realised PnL Calculation  
↓  
Persist to PMS DB  
↓  
Publish Position Update (WebSocket)

---

## Market Price Fetch Flow

Scheduler (every 20s)  
↓  
Finnhub API  
↓  
Redis Cache (Symbol → Current Price)

---

## Unrealised PnL Calculation Flow

Unrealised PnL is calculated periodically based on the latest cached prices and historical transactions.

### Flow

Scheduler Trigger  
↓  
Read Current Prices from Redis  
↓  
Load Transactions & Holdings from PMS DB  
↓  
Group by PortfolioId + Symbol  
↓  
Compute Unrealised PnL  
↓  
Publish to WebSocket Topic (unrealised-pnl)

### Computation Logic

- currentValue = currentPrice × quantityHeld
- investedAmount = Σ(buyPrice × quantity)
- unrealisedPnL = currentValue − investedAmount

### State Interaction

| Action        | Storage         |
| ------------- | --------------- |
| Read Prices   | Redis           |
| Read Holdings | PMS DB          |
| DB Writes     | None            |
| Publish       | WebSocket Topic |

### Failure Handling

- Finnhub unavailable → reuse last Redis value
- Redis empty → skip symbol
- No DB writes occur during this flow

---

## Risk Metrics Flow

Midnight Scheduler  
↓  
Portfolio Value Snapshot  
↓  
Risk Engine  
↓  
Outbox  
↓  
Kafka (portfolio_risk_metrics)

---

## Scaling Assumptions

- Stateless pods
- Horizontal scaling supported
- Kafka partition count affects throughput
- Redis is shared
- DB write contention is potential bottleneck
