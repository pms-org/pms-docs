---
sidebar_position: 2
title: Architecture
---

# Analytics Service — Architecture

## Architectural Overview

The Analytics Service follows a **layered, event-driven architecture** designed for high throughput, scalability, and real-time responsiveness. The service operates primarily in an asynchronous, reactive manner with clearly separated concerns across multiple architectural layers.

## Logical Layers

### 1. Event Consumer Layer
**Purpose**: Ingest and buffer transactional events from Kafka

**Components**:
- `KafkaTransactionListener`: Listens to the `transactions` topic
- `TransactionBatch`: Wrapper for batched Kafka messages with acknowledgment
- `BlockingQueue<TransactionBatch>`: In-memory buffer for decoupling consumption from processing

**Characteristics**:
- **Batch Consumption**: Processes multiple messages per poll for efficiency
- **Manual Acknowledgment**: Controls when Kafka offsets are committed
- **Buffer Management**: Fills 80% threshold triggers batch processing
- **Backpressure Handling**: Bounded queue prevents memory overflow

**Key Configuration**:
```properties
spring.kafka.consumer.group-id=analytics-consumer-group
app.kafka.consumer-topic=transactions
app.buffer.size=1000
```

### 2. Computation Layer
**Purpose**: Transform raw transactions into financial metrics

**Components**:

#### A. Holdings Calculator
- **Input**: Transaction batch (buy/sell orders)
- **Processing**: 
  - Aggregates trades by portfolio and symbol
  - Maintains running quantity balances
  - Tracks invested amount using weighted average cost
- **Output**: Updated holdings in `analytics` table

#### B. Realised P&L Engine
- **Method**: FIFO (First-In-First-Out)
- **Logic**:
  - Matches sell transactions with earliest buy transactions
  - Calculates profit/loss as `(sellPrice - buyPrice) × quantity`
  - Accounts for partial position closures
- **Persistence**: Stores in `analytics.realised_pnl` column

#### C. Unrealised P&L Engine
- **Trigger**: Scheduled every 30 seconds
- **Calculation**:
  ```
  currentValue = currentMarketPrice × openQuantity
  investedAmount = Σ(purchasePrice × quantity) for open positions
  unrealisedPnL = currentValue - investedAmount
  ```
- **Broadcasting**: Publishes results via WebSocket

#### D. Risk Metrics Calculator
- **Trigger**: Daily at midnight (00:00 UTC)
- **Metrics Computed**:
  - **Sharpe Ratio**: `(avgReturn - riskFreeRate) / standardDeviation`
  - **Sortino Ratio**: `(avgReturn - riskFreeRate) / downsideDeviation`
  - **Average Rate of Return**: `(currentValue - initialInvestment) / initialInvestment`
- **Data Source**: 30-day portfolio value history
- **Output**: Risk events to Kafka `risk-events` topic

### 3. State Management Layer
**Purpose**: Persistent and temporary storage for analytics data

#### PostgreSQL Database (PMS DB)

**Table**: `analytics`
- **Primary Key**: Composite (portfolio_id, symbol)
- **Columns**:
  - `portfolio_id` (UUID)
  - `symbol` (VARCHAR)
  - `quantity` (DECIMAL)
  - `invested_amount` (DECIMAL)
  - `realised_pnl` (DECIMAL)
  - `avg_buy_price` (DECIMAL)
  - `sector` (VARCHAR)
  - `last_updated` (TIMESTAMP)

**Table**: `portfolio_value_history`
- **Purpose**: Daily snapshots for risk calculations
- **Columns**:
  - `id` (BIGINT AUTO_INCREMENT)
  - `portfolio_id` (UUID)
  - `total_value` (DECIMAL)
  - `date` (DATE)
- **Retention**: Last 30 days queried for metrics

**Table**: `transactions`
- **Purpose**: Complete trade history
- **Columns**:
  - `transaction_id` (VARCHAR)
  - `portfolio_id` (UUID)
  - `symbol` (VARCHAR)
  - `side` (ENUM: BUY/SELL)
  - `quantity` (DECIMAL)
  - `price` (DECIMAL)
  - `timestamp` (TIMESTAMP)

**Table**: `analysis_outbox`
- **Purpose**: Outbox pattern for reliable Kafka publishing
- **Columns**:
  - `id` (BIGINT AUTO_INCREMENT)
  - `portfolio_id` (UUID)
  - `event_type` (VARCHAR)
  - `payload` (JSONB)
  - `published` (BOOLEAN)
  - `created_at` (TIMESTAMP)

#### Redis Cache

**Data Structure**: String key-value pairs
- **Key Format**: `price:{symbol}` (e.g., `price:AAPL`)
- **Value**: Current market price (BigDecimal as String)
- **TTL**: 30 seconds (auto-expiry)

**Usage Pattern**:
```java
String cacheKey = "price:" + symbol;
BigDecimal price = redisTemplate.opsForValue().get(cacheKey);
if (price == null) {
    price = finnhubClient.fetchPriceSync(symbol);
    redisTemplate.opsForValue().set(cacheKey, price, 30, TimeUnit.SECONDS);
}
```

**Fallback Strategy**:
- If Redis is unavailable, service continues with degraded performance
- Directly queries Finnhub API without caching
- Logs warnings but does not fail requests

### 4. API & WebSocket Layer
**Purpose**: Expose data and real-time updates to clients

#### REST Controllers

**ApiController** (`/api`)
- `GET /api/analysis/all`: Returns all analytics records
- `GET /api/unrealized`: Triggers unrealised P&L calculation
- `GET /api/portfolio_value/history/{portfolioId}`: Returns value history

**SectorAnalyticsController** (`/api/sectors`)
- `GET /api/sectors/overall`: Overall sector composition
- `GET /api/sectors/sector-wise/{sector}`: Symbol breakdown per sector
- `GET /api/sectors/portfolio-wise/{portfolioId}`: Portfolio sector analysis
- `GET /api/sectors/portfolio-wise/{portfolioId}/sector-wise/{sector}`: Detailed drilldown
- `GET /api/sectors/sector-catalog`: List of all sectors

**TransactionController** (`/api/transactions`)
- `POST /api/transactions`: Manually publish transaction to Kafka (testing)

#### WebSocket Configuration

**Protocol**: STOMP over SockJS
**Endpoint**: `/ws` (connection point)

**Topics**:
- `/topic/position-update`: Broadcasts `AnalysisEntity` on trade processing
- `/topic/unrealised-pnl`: Streams `UnrealisedPnlWsDto` every 30 seconds

**Message Flow**:
```
Client connects to /ws
   ↓
Client subscribes to /topic/position-update
   ↓
Service processes transaction
   ↓
Service publishes to /topic/position-update
   ↓
All subscribed clients receive update
```

**Broadcasting Logic**:
```java
@Autowired
private SimpMessagingTemplate messagingTemplate;

public void broadcastPositionUpdate(AnalysisEntity entity) {
    messagingTemplate.convertAndSend("/topic/position-update", entity);
}
```

### 5. Outbox & Publisher Layer
**Purpose**: Reliable event publishing to downstream services

**Components**:

#### OutboxEventProcessor
- Polls `analysis_outbox` table every 5 seconds
- Fetches unpublished events (`published = false`)
- Publishes to Kafka `risk-events` topic
- Marks events as published upon success

#### OutboxDispatcher
- Async Kafka producer with retries
- Protocol Buffer serialization
- Guarantees at-least-once delivery

**Reliability Pattern**:
```
Transaction Processing
   ↓
DB Transaction Start
   ├─→ Update analytics table
   └─→ Insert into analysis_outbox
        ↓
DB Transaction Commit
        ↓
(Separate Process)
Outbox Processor reads outbox
        ↓
Publishes to Kafka
        ↓
Updates outbox.published = true
```

**Advantages**:
- Transactional consistency (analytics + outbox)
- Decoupled from Kafka availability
- Automatic retries on failure
- Exactly-once semantics per database transaction

---

## Detailed Flow Diagrams

### Transaction Event Processing Flow

```
1. Kafka Consumer receives batch
      ↓
2. Buffer receives TransactionBatch
      ↓
3. BatchProcessor checks buffer threshold (80%)
      ↓
4. If threshold met:
      ├─→ Drain buffer
      ├─→ Start DB Transaction
      ├─→ For each transaction:
      │      ├─→ Check idempotency (transaction_id exists?)
      │      ├─→ If duplicate: Skip
      │      ├─→ If new:
      │             ├─→ Update/Insert analytics table
      │             ├─→ Calculate realised P&L (if SELL)
      │             ├─→ Insert into transactions table
      │             └─→ Create outbox entry (if needed)
      ├─→ Commit DB Transaction
      ├─→ Broadcast to WebSocket /topic/position-update
      └─→ Acknowledge Kafka batch
```

**Idempotency Mechanism**:
- Each transaction has unique `transaction_id`
- Before processing, check if `transaction_id` exists in DB
- If exists, skip processing (duplicate message)
- Prevents double-counting on Kafka replays

**Error Handling**:
- DB transaction rollback on any failure
- Kafka offset NOT acknowledged on failure
- Message will be reprocessed on next poll
- Dead Letter Queue (future enhancement) for persistent failures

### Market Price Fetch Flow

```
Scheduler Trigger (every 20 seconds)
   ↓
PriceUpdateScheduler.fetchAndCachePrices()
   ↓
Query analytics table for distinct symbols
   ↓
For each symbol:
   ├─→ Check Redis cache (price:{symbol})
   ├─→ If cache HIT: Skip Finnhub call
   └─→ If cache MISS:
          ├─→ Call Finnhub API /quote?symbol={symbol}&token={key}
          ├─→ Parse FinnhubQuoteResponseDTO
          ├─→ Extract current price
          ├─→ Store in Redis with 30s TTL
          └─→ Log price update
```

**Rate Limiting Awareness**:
- Finnhub free tier: 60 calls/minute
- With 100 symbols and 20s interval:
  - 3 calls/minute per symbol
  - Total: 300 calls/minute without cache
  - **With Redis**: ~5-10 calls/minute (cache misses + new symbols)

**Reactive Implementation**:
```java
public Mono<BigDecimal> fetchPriceAsync(String symbol) {
    return finnhubClient.get()
        .uri(uriBuilder -> uriBuilder
            .path("/quote")
            .queryParam("symbol", symbol)
            .queryParam("token", apiKey)
            .build())
        .retrieve()
        .bodyToMono(FinnhubQuoteResponseDTO.class)
        .map(FinnhubQuoteResponseDTO::getCost);
}
```

### Unrealised PnL Calculation Flow

**Trigger**: Scheduled `@Scheduled(fixedDelay = 30000)` (every 30 seconds)

```
1. UnrealizedPnlCalculator.computeUnRealisedPnlAndBroadcast()
      ↓
2. Query: SELECT DISTINCT portfolio_id FROM transactions WHERE quantity > 0
      ↓
3. For each portfolio_id:
      ↓
   A. UnrealizedPnlService.computeUnrealizedPnlForSinglePortfolio(portfolioId)
      ↓
   B. Query: SELECT symbol, SUM(quantity) FROM analytics WHERE portfolio_id = ? GROUP BY symbol
      ↓
   C. For each (symbol, quantity):
      ├─→ Fetch currentPrice from Redis (price:{symbol})
      ├─→ If Redis miss: Skip symbol (avoid blocking on Finnhub)
      ├─→ Calculate: currentValue = price × quantity
      ├─→ Fetch investedAmount from analytics table
      ├─→ Calculate: unrealisedPnL = currentValue - investedAmount
      └─→ Create UnrealisedPnlWsDto
      ↓
   D. Aggregate all symbols for portfolio
      ↓
   E. Broadcast to WebSocket: /topic/unrealised-pnl
```

**Data Transfer Object**:
```java
public class UnrealisedPnlWsDto {
    private UUID portfolioId;
    private String symbol;
    private BigDecimal quantity;
    private BigDecimal currentPrice;
    private BigDecimal currentValue;
    private BigDecimal investedAmount;
    private BigDecimal unrealisedPnL;
    private Double pnlPercentage;
}
```

**No Database Writes**: This is a read-only operation for streaming purposes

### Risk Metrics Computation Flow

**Trigger**: Daily at midnight `@Scheduled(cron = "0 0 0 * * ?")`

```
1. PortfolioValueScheduler triggers snapshot
      ↓
2. For each portfolio:
      ├─→ Calculate total_value = SUM(current_price × quantity)
      └─→ INSERT INTO portfolio_value_history (portfolio_id, total_value, date)
      ↓
3. RiskMetricsCalculator.computeRiskMetricsForAllPortfolios()
      ↓
4. Query: SELECT DISTINCT portfolio_id FROM analytics
      ↓
5. For each portfolio_id:
      ↓
   A. Query last 30 days from portfolio_value_history
      ↓
   B. RiskMetricsService.computeRiskForSinglePortfolio()
      ├─→ Calculate daily returns: (value[i] - value[i-1]) / value[i-1]
      ├─→ Compute avgReturn = mean(dailyReturns)
      ├─→ Compute stdDev = standardDeviation(dailyReturns)
      ├─→ Compute downsideDeviation (only negative returns)
      ├─→ Calculate Sharpe Ratio = (avgReturn - 0.02/365) / stdDev
      ├─→ Calculate Sortino Ratio = (avgReturn - 0.02/365) / downsideDeviation
      └─→ Calculate Avg Rate of Return = (finalValue - initialValue) / initialValue
      ↓
   C. Create AnalysisOutbox entry
      ├─→ portfolio_id
      ├─→ event_type = "RISK_METRICS"
      ├─→ payload = RiskEvent (Protocol Buffer)
      └─→ published = false
      ↓
6. Batch save all outbox entries
      ↓
7. OutboxEventProcessor (separate thread)
      ├─→ Polls outbox WHERE published = false
      ├─→ Publishes to Kafka topic: risk-events
      └─→ Updates published = true
```

**Risk-Free Rate**: Assumed 2% annually (0.02/365 daily)

---

## Concurrency & Thread Management

### Thread Pools

1. **Kafka Consumer Thread Pool**
   - Managed by Spring Kafka
   - Concurrency: Configurable (default: 3)
   - Each thread processes one batch at a time

2. **Scheduler Thread Pool**
   - Spring `@EnableScheduling` with default single thread
   - Executes price fetch, unrealised P&L, and risk metrics

3. **WebSocket Messaging Thread Pool**
   - Spring STOMP with default thread pool
   - Handles broadcast operations asynchronously

4. **Batch Processor ExecutorService**
   - Custom executor for batch processing
   - Decouples Kafka consumption from business logic

### Synchronization Points

- **Buffer Access**: `BlockingQueue` provides thread-safe operations
- **Database Transactions**: ACID guarantees prevent race conditions
- **Kafka Offset Commits**: Manual acknowledgment ensures exactly-once consumption

---

## Scaling Considerations

### Horizontal Scaling

**Stateless Design**:
- No in-memory session state
- All state in database or cache
- Multiple pod replicas can run concurrently

**Kafka Partitioning**:
- `transactions` topic partitioned by portfolio_id
- Each partition assigned to one consumer in group
- Adding pods increases parallelism (up to partition count)

**Database Connection Pooling**:
```properties
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
```

### Vertical Scaling

**Memory Requirements**:
- Buffer size: Configurable (default 1000 batches × 100 msgs × 1KB ≈ 100MB)
- JVM Heap: Recommended 1-2GB per pod

**CPU Utilization**:
- Computation-heavy during batch processing
- I/O-bound during price fetching and database operations

---

## Failure Modes & Resilience

### Redis Unavailability
**Impact**: Increased Finnhub API calls, potential rate limiting
**Handling**:
- Service continues to function
- Direct Finnhub calls without caching
- Logs warning messages

### Finnhub API Failure
**Impact**: Unrealised P&L becomes stale
**Handling**:
- Reuse last cached Redis values (if within TTL)
- Skip unrealised P&L updates if no prices available
- Alert monitoring system

### Database Connection Loss
**Impact**: Critical failure, service cannot process transactions
**Handling**:
- Readiness probe fails → Kubernetes stops routing traffic
- Kafka messages remain uncommitted → replay on recovery
- Exponential backoff for connection retry

### Kafka Broker Down
**Impact**: Cannot consume transactions or publish risk events
**Handling**:
- Consumer pauses polling
- Messages accumulate in Kafka
- Service resumes upon broker recovery
- No data loss due to Kafka durability

---

## Observability & Monitoring

### Logging

**Structured Logging** (SLF4J + Logback):
```java
log.info("Transaction processed: portfolioId={} symbol={} quantity={}", 
    portfolioId, symbol, quantity);
```

**Key Log Events**:
- Kafka batch received
- Transaction processing started/completed
- Price fetch success/failure
- WebSocket broadcast sent
- Database transaction committed/rolled back

### Health Checks

**Liveness Probe**: `/actuator/health/liveness`
- Checks if JVM is alive
- Returns 200 if service can respond

**Readiness Probe**: `/actuator/health/readiness`
- Checks database connectivity
- Checks Kafka broker connectivity
- Returns 503 if dependencies unavailable

### Metrics (Future Enhancement)

Planned Prometheus metrics:
- `analytics_transactions_processed_total`: Counter
- `analytics_batch_processing_duration_seconds`: Histogram
- `analytics_unrealised_pnl_calculations_total`: Counter
- `analytics_redis_cache_hit_ratio`: Gauge
- `analytics_finnhub_api_calls_total`: Counter

---

## Security Architecture

### Authentication
- All REST endpoints secured via JWT
- Validation performed at API Gateway
- User context propagated via HTTP headers

### Authorization
- Portfolio-level access control (future)
- Currently, all authenticated users can access all data

### Data Protection
- Database credentials stored in Kubernetes Secrets
- Finnhub API key externalized via ConfigMap/Secret
- No sensitive data in logs

---

## Technology Choices Rationale

### Why Kafka?
- **High Throughput**: Handles thousands of transactions per second
- **Durability**: Replayability for data consistency
- **Decoupling**: Producers and consumers evolve independently

### Why Redis?
- **Speed**: Sub-millisecond lookups
- **Simplicity**: No complex caching logic needed
- **TTL Support**: Automatic expiry aligns with price refresh

### Why Protocol Buffers?
- **Efficiency**: 3-10x smaller than JSON
- **Schema Evolution**: Backward compatibility
- **Cross-Language**: Java → Java (future: other languages)

### Why WebSocket (STOMP)?
- **Real-Time**: Push model for live updates
- **Bi-directional**: Potential for client interactions
- **Standards-Based**: STOMP widely supported

---

## Future Architectural Enhancements

1. **Event Sourcing**: Store all events for audit and replay
2. **CQRS**: Separate read/write models for optimization
3. **Distributed Tracing**: Jaeger/Zipkin for request flow visibility
4. **Circuit Breaker**: Resilience4j for Finnhub API calls
5. **GraphQL**: Flexible querying for frontend
6. **Materialized Views**: Pre-computed sector analytics


- Horizontal scaling supported
- Kafka partition count affects throughput
- Redis is shared
- DB write contention is potential bottleneck
