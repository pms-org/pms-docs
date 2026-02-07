---
sidebar_position: 3
title: API Contract
---

# Analytics Service — API Contract

## Overview

This document provides comprehensive documentation for all **public REST APIs and WebSocket endpoints** exposed by the `pms-analytics` service. All REST endpoints are routed through the API Gateway and require JWT authentication.

**Service Base URL**: `http://pms-analytics:8086`  
**External Access**: Via API Gateway at `/api/*` and `/ws`  
**Protocol**: HTTP/1.1 REST + WebSocket (STOMP over SockJS)  
**Content-Type**: `application/json`  
**Authentication**: Bearer JWT token in `Authorization` header

---

## API Categories

1. [Analysis APIs](#1-analysis-apis) - Core portfolio analytics and holdings
2. [Sector Analysis APIs](#2-sector-analysis-apis) - Sector composition and breakdown
3. [Transaction APIs](#3-transaction-apis) - Manual transaction publishing (testing)
4. [WebSocket Topics](#4-websocket-topics) - Real-time data streams

---

# 1. Analysis APIs

Base Path: `/api`

## 1.1 Get All Analysis Records

Retrieves all portfolio holdings and analytics records across all portfolios and symbols.

### Endpoint
```
GET /api/analysis/all
```

### Purpose
Returns complete analytics dataset including holdings, invested amounts, realised P&L, and average buy prices for all active positions.

### Request

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Query Parameters**: None

**Request Body**: None

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "id": {
      "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
      "symbol": "AAPL"
    },
    "quantity": 100.00,
    "investedAmount": 15000.00,
    "realisedPnl": 2500.00,
    "avgBuyPrice": 150.00,
    "sector": "Technology",
    "lastUpdated": "2026-02-07T10:30:00Z"
  },
  {
    "id": {
      "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
      "symbol": "GOOGL"
    },
    "quantity": 50.00,
    "investedAmount": 7000.00,
    "realisedPnl": 0.00,
    "avgBuyPrice": 140.00,
    "sector": "Technology",
    "lastUpdated": "2026-02-07T09:15:00Z"
  }
]
```

**Response Schema**:
| Field | Type | Description |
|-------|------|-------------|
| `id.portfolioId` | UUID | Unique portfolio identifier |
| `id.symbol` | String | Stock ticker symbol |
| `quantity` | Decimal | Current holding quantity (open positions) |
| `investedAmount` | Decimal | Total amount invested in this symbol |
| `realisedPnl` | Decimal | Profit/loss from closed positions |
| `avgBuyPrice` | Decimal | Weighted average purchase price |
| `sector` | String | Industry sector classification |
| `lastUpdated` | DateTime | Last modification timestamp (ISO 8601) |

**Error Responses**:
- **401 Unauthorized**: Missing or invalid JWT token
- **500 Internal Server Error**: Database connection failure

### Usage Examples

**cURL**:
```bash
curl -X GET "https://api.pms-platform.com/api/analysis/all" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**JavaScript (Fetch)**:
```javascript
fetch('https://api.pms-platform.com/api/analysis/all', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
.then(res => res.json())
.then(data => console.log(data));
```

### Use Cases
- Admin dashboard showing all platform holdings
- Portfolio overview displaying all positions
- Data export for reporting and analysis
- Internal monitoring and inspection tools

### Performance Considerations
- **Response Time**: < 200ms for p95
- **Data Volume**: Can return 10,000+ records for large platforms
- **Caching**: Not cached (real-time data)
- **Pagination**: Not implemented (future enhancement)

---

## 1.2 Trigger Unrealised PnL Calculation

Manually triggers the unrealised P&L computation and WebSocket broadcast.

### Endpoint
```
GET /api/unrealized
```

### Purpose
Forces immediate recalculation of unrealised profit/loss for all portfolios and publishes results to WebSocket subscribers. Useful for testing or manual refresh scenarios.

### Request

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

**Query Parameters**: None

**Request Body**: None

### Response

**Success Response** (HTTP 200 OK):
```
(Empty response body)
```

**Error Responses**:
- **401 Unauthorized**: Missing or invalid JWT token
- **500 Internal Server Error**: Calculation failure or database error
- **503 Service Unavailable**: Redis cache unavailable

### Side Effects
1. Queries all portfolios with open positions
2. Fetches current market prices from Redis cache
3. Calculates unrealised P&L for each portfolio-symbol combination
4. Broadcasts results to WebSocket topic `/topic/unrealised-pnl`
5. **Does NOT modify database** - read-only operation

### Usage Examples

**cURL**:
```bash
curl -X GET "https://api.pms-platform.com/api/unrealized" \
  -H "Authorization: Bearer ${TOKEN}"
```

**JavaScript**:
```javascript
await fetch('https://api.pms-platform.com/api/unrealized', {
  headers: { 'Authorization': `Bearer ${token}` }
});
// Listen for updates on WebSocket
stompClient.subscribe('/topic/unrealised-pnl', (message) => {
  const data = JSON.parse(message.body);
  console.log('Unrealised PnL update:', data);
});
```

### Use Cases
- Frontend "Refresh" button for P&L data
- Testing WebSocket broadcast functionality
- Manual trigger after price data updates
- Debugging unrealised P&L calculations

### Performance Considerations
- **Execution Time**: 1-5 seconds depending on portfolio count
- **Concurrent Calls**: Endpoint is not idempotent-safe; avoid rapid successive calls
- **Redis Dependency**: Requires Redis for price lookups
- **Scheduler Alternative**: Automated execution every 30 seconds via scheduler

---

## 1.3 Get Portfolio Value History

Retrieves historical portfolio value snapshots for trend analysis and risk calculations.

### Endpoint
```
GET /api/portfolio_value/history/{portfolioId}
```

### Purpose
Returns daily portfolio value snapshots (up to last 30 days) used for performance tracking, charting, and risk metric calculations.

### Request

**Path Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `portfolioId` | UUID | Yes | Unique portfolio identifier |

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

**Query Parameters**: None

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "id": 12345,
    "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
    "totalValue": 125000.50,
    "date": "2026-02-07"
  },
  {
    "id": 12344,
    "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
    "totalValue": 123500.25,
    "date": "2026-02-06"
  },
  // ... up to 30 records
]
```

**Response Schema**:
| Field | Type | Description |
|-------|------|-------------|
| `id` | Long | Auto-increment primary key |
| `portfolioId` | UUID | Portfolio identifier (matches path parameter) |
| `totalValue` | Decimal | Total portfolio value on that date |
| `date` | Date | Snapshot date (YYYY-MM-DD) |

**Ordering**: Descending by date (most recent first)  
**Limit**: Last 30 days

**Error Responses**:
- **400 Bad Request**: Invalid UUID format
- **401 Unauthorized**: Missing or invalid JWT token
- **404 Not Found**: Portfolio ID does not exist
- **500 Internal Server Error**: Database error

### Usage Examples

**cURL**:
```bash
curl -X GET "https://api.pms-platform.com/api/portfolio_value/history/550e8400-e29b-41d4-a716-446655440000" \
  -H "Authorization: Bearer ${TOKEN}"
```

**JavaScript**:
```javascript
const portfolioId = '550e8400-e29b-41d4-a716-446655440000';
const response = await fetch(
  `https://api.pms-platform.com/api/portfolio_value/history/${portfolioId}`,
  { headers: { 'Authorization': `Bearer ${token}` } }
);
const history = await response.json();
// Use for charting
const chartData = history.map(h => ({ date: h.date, value: h.totalValue }));
```

### Use Cases
- Portfolio performance line charts
- Return calculations (daily, weekly, monthly)
- Risk metrics computation (Sharpe, Sortino)
- Historical trend analysis

### Performance Considerations
- **Query Optimization**: Indexed on `portfolio_id` and `date`
- **Data Volume**: Fixed 30 records maximum
- **Caching**: Cacheable for 1 hour (data changes daily)
- **Response Time**: < 50ms

---

# 2. Sector Analysis APIs

Base Path: `/api/sectors`

## 2.1 Overall Sector Analysis

Returns platform-wide sector composition and performance metrics.

### Endpoint
```
GET /api/sectors/overall
```

### Purpose
Provides aggregated sector-level analytics across all portfolios, showing total invested amount, unrealised P&L, and holding distribution by sector.

### Request

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "sector": "Technology",
    "totalInvestedAmount": 500000.00,
    "totalUnrealisedPnl": 75000.00,
    "totalQuantity": 5000.00,
    "symbolCount": 25,
    "portfolioCount": 150
  },
  {
    "sector": "Finance",
    "totalInvestedAmount": 300000.00,
    "totalUnrealisedPnl": -15000.00,
    "totalQuantity": 3000.00,
    "symbolCount": 15,
    "portfolioCount": 120
  }
]
```

**Response Schema**:
| Field | Type | Description |
|-------|------|-------------|
| `sector` | String | Sector name (e.g., Technology, Finance, Healthcare) |
| `totalInvestedAmount` | Decimal | Sum of invested amounts across all portfolios in sector |
| `totalUnrealisedPnl` | Decimal | Aggregated unrealised P&L for sector |
| `totalQuantity` | Decimal | Total shares/units held in sector |
| `symbolCount` | Integer | Number of distinct symbols in sector |
| `portfolioCount` | Integer | Number of portfolios holding assets in sector |

### Use Cases
- Platform-wide sector composition dashboard
- Risk management: sector concentration analysis
- Marketing analytics: popular sectors
- Portfolio rebalancing insights

---

## 2.2 Sector-wise Symbol Analysis

Returns symbol-level breakdown for a specific sector.

### Endpoint
```
GET /api/sectors/sector-wise/{sector}
```

### Purpose
Drills down into a sector to show per-symbol metrics including holdings, invested amounts, and P&L.

### Request

**Path Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `sector` | String | Yes | Sector name (case-sensitive) |

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "symbol": "AAPL",
    "sector": "Technology",
    "totalInvestedAmount": 150000.00,
    "totalUnrealisedPnl": 25000.00,
    "totalQuantity": 1000.00,
    "portfolioCount": 50
  },
  {
    "symbol": "GOOGL",
    "sector": "Technology",
    "totalInvestedAmount": 100000.00,
    "totalUnrealisedPnl": 15000.00,
    "totalQuantity": 750.00,
    "portfolioCount": 40
  }
]
```

**Response Schema**:
| Field | Type | Description |
|-------|------|-------------|
| `symbol` | String | Stock ticker symbol |
| `sector` | String | Sector classification |
| `totalInvestedAmount` | Decimal | Aggregate invested amount across all portfolios |
| `totalUnrealisedPnl` | Decimal | Total unrealised P&L for symbol |
| `totalQuantity` | Decimal | Sum of holdings across portfolios |
| `portfolioCount` | Integer | Number of portfolios holding this symbol |

### Use Cases
- Sector drilldown in dashboards
- Symbol popularity within sector
- Concentration risk analysis

---

## 2.3 Portfolio-wise Sector Analysis

Returns sector breakdown for a specific portfolio.

### Endpoint
```
GET /api/sectors/portfolio-wise/{portfolioId}
```

### Purpose
Shows how a single portfolio is distributed across sectors.

### Request

**Path Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `portfolioId` | UUID | Yes | Portfolio identifier |

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "sector": "Technology",
    "totalInvestedAmount": 50000.00,
    "totalUnrealisedPnl": 7500.00,
    "totalQuantity": 500.00,
    "symbolCount": 5
  },
  {
    "sector": "Finance",
    "totalInvestedAmount": 30000.00,
    "totalUnrealisedPnl": -2000.00,
    "totalQuantity": 300.00,
    "symbolCount": 3
  }
]
```

### Use Cases
- Portfolio composition pie chart
- Diversification analysis
- Sector allocation recommendations

---

## 2.4 Portfolio + Sector Symbol Drilldown

Returns symbol-level details for a portfolio within a specific sector.

### Endpoint
```
GET /api/sectors/portfolio-wise/{portfolioId}/sector-wise/{sector}
```

### Purpose
Provides the most granular view: symbols held by a specific portfolio within a specific sector.

### Request

**Path Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `portfolioId` | UUID | Yes | Portfolio identifier |
| `sector` | String | Yes | Sector name |

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "symbol": "AAPL",
    "sector": "Technology",
    "investedAmount": 15000.00,
    "unrealisedPnl": 2500.00,
    "quantity": 100.00
  },
  {
    "symbol": "MSFT",
    "sector": "Technology",
    "investedAmount": 20000.00,
    "unrealisedPnl": 3000.00,
    "quantity": 75.00
  }
]
```

### Use Cases
- Detailed portfolio drilldown UI
- Symbol-level P&L within sector context
- Portfolio rebalancing decisions

---

## 2.5 Sector Catalog

Returns list of all available sectors.

### Endpoint
```
GET /api/sectors/sector-catalog
```

### Purpose
Provides enumeration of all sector classifications used in the platform.

### Response

**Success Response** (HTTP 200 OK):
```json
[
  {
    "sectorName": "Technology",
    "description": "Software, hardware, and IT services"
  },
  {
    "sectorName": "Finance",
    "description": "Banking, insurance, and financial services"
  },
  {
    "sectorName": "Healthcare",
    "description": "Pharmaceuticals, biotech, and medical devices"
  }
]
```

### Use Cases
- Sector dropdown filters in UI
- Validation of sector parameters
- Sector metadata display

---

# 3. Transaction APIs

Base Path: `/api/transactions`

## 3.1 Publish Transaction (Testing Only)

Manually publishes a transaction event to Kafka for testing purposes.

### Endpoint
```
POST /api/transactions
```

### Purpose
**Testing and development only**. Allows manual injection of transaction events into the Kafka stream. In production, transactions originate from the Simulation or Trade Capture services.

### Request

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Request Body**:
```json
{
  "transactionId": "TXN-123456",
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "symbol": "AAPL",
  "side": "BUY",
  "quantity": 100,
  "price": 150.50,
  "timestamp": "2026-02-07T10:30:00Z"
}
```

**Request Schema**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `transactionId` | String | Yes | Unique transaction identifier |
| `portfolioId` | UUID | Yes | Target portfolio |
| `symbol` | String | Yes | Stock ticker symbol |
| `side` | Enum | Yes | `BUY` or `SELL` |
| `quantity` | Decimal | Yes | Number of shares (> 0) |
| `price` | Decimal | Yes | Execution price per share (> 0) |
| `timestamp` | DateTime | Yes | Transaction timestamp (ISO 8601) |

### Response

**Success Response** (HTTP 200 OK):
```json
{
  "message": "Transaction sent to Kafka"
}
```

**Error Responses**:
- **400 Bad Request**: Invalid request body or missing required fields
- **401 Unauthorized**: Missing JWT token
- **500 Internal Server Error**: Kafka publishing failure

### Security Warning
**This endpoint should be disabled or restricted in production environments**. It bypasses normal transaction validation and authorization flows.

---

# 4. WebSocket Topics

The Analytics Service publishes real-time updates via WebSocket using the STOMP protocol over SockJS.

## Connection Endpoint

```
ws://pms-analytics:8086/ws
or
wss://api.pms-platform.com/ws (via API Gateway)
```

**Protocol**: STOMP over SockJS  
**Fallback**: Long-polling if WebSocket unavailable

## Client Connection Flow

```javascript
// 1. Create SockJS connection
const socket = new SockJS('https://api.pms-platform.com/ws');

// 2. Create STOMP client
const stompClient = Stomp.over(socket);

// 3. Connect with optional headers
stompClient.connect(
  { Authorization: `Bearer ${token}` },
  (frame) => {
    console.log('Connected:', frame);
    
    // 4. Subscribe to topics
    stompClient.subscribe('/topic/position-update', (message) => {
      const update = JSON.parse(message.body);
      console.log('Position update:', update);
    });
    
    stompClient.subscribe('/topic/unrealised-pnl', (message) => {
      const pnlData = JSON.parse(message.body);
      console.log('Unrealised PnL:', pnlData);
    });
  },
  (error) => {
    console.error('Connection error:', error);
  }
);

// 5. Disconnect when done
stompClient.disconnect(() => {
  console.log('Disconnected');
});
```

## Topic 4.1: Position Updates

**Topic**: `/topic/position-update`

### Purpose
Broadcasts real-time holding updates whenever transactions are processed.

### Message Format
```json
{
  "id": {
    "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
    "symbol": "AAPL"
  },
  "quantity": 150.00,
  "investedAmount": 22500.00,
  "realisedPnl": 1000.00,
  "avgBuyPrice": 150.00,
  "sector": "Technology",
  "lastUpdated": "2026-02-07T10:35:15Z"
}
```

### Trigger Events
- Transaction processed (buy or sell)
- Holdings recalculated
- Database persistence completed

### Broadcast Frequency
- Immediate (event-driven)
- Multiple messages possible in burst scenarios

### Use Cases
- Live portfolio dashboard updates
- Real-time holdings tracking
- Trade confirmation notifications

---

## Topic 4.2: Unrealised PnL

**Topic**: `/topic/unrealised-pnl`

### Purpose
Streams live unrealised profit/loss calculations as market prices update.

### Message Format
```json
[
  {
    "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
    "symbol": "AAPL",
    "quantity": 100.00,
    "currentPrice": 175.50,
    "currentValue": 17550.00,
    "investedAmount": 15000.00,
    "unrealisedPnl": 2550.00,
    "pnlPercentage": 17.0
  },
  {
    "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
    "symbol": "GOOGL",
    "quantity": 50.00,
    "currentPrice": 135.00,
    "currentValue": 6750.00,
    "investedAmount": 7000.00,
    "unrealisedPnl": -250.00,
    "pnlPercentage": -3.57
  }
]
```

**Note**: Message contains array of all symbols for each portfolio.

### Trigger Events
- Scheduled calculation (every 30 seconds)
- Manual trigger via `/api/unrealized` endpoint
- Market price updates in Redis cache

### Broadcast Frequency
- Every 30 seconds (automated)
- On-demand via API trigger

### Use Cases
- Live P&L ticker in dashboard
- Real-time gain/loss monitoring
- Portfolio value updates

---

## WebSocket Best Practices

### Reconnection Strategy
```javascript
let reconnectAttempts = 0;
const maxReconnectAttempts = 5;

function connect() {
  const socket = new SockJS('/ws');
  const stompClient = Stomp.over(socket);
  
  stompClient.connect({}, 
    () => {
      reconnectAttempts = 0; // Reset on success
      subscribe(stompClient);
    },
    (error) => {
      if (reconnectAttempts < maxReconnectAttempts) {
        reconnectAttempts++;
        const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 30000);
        setTimeout(connect, delay);
      }
    }
  );
}
```

### Message Throttling
To avoid UI performance issues with high-frequency updates:
```javascript
let latestMessage = null;
let throttleTimer = null;

stompClient.subscribe('/topic/position-update', (message) => {
  latestMessage = JSON.parse(message.body);
  
  if (!throttleTimer) {
    throttleTimer = setTimeout(() => {
      updateUI(latestMessage);
      throttleTimer = null;
    }, 100); // Update UI max once per 100ms
  }
});
```

### Authentication
Include JWT token in connection headers:
```javascript
stompClient.connect(
  { Authorization: `Bearer ${jwtToken}` },
  onConnect,
  onError
);
```

---

## Error Handling

### Common HTTP Error Codes

| Code | Meaning | Common Causes | Recommended Action |
|------|---------|---------------|---------------------|
| 400 | Bad Request | Invalid UUID, malformed JSON | Validate input parameters |
| 401 | Unauthorized | Missing/expired JWT token | Refresh authentication token |
| 404 | Not Found | Portfolio ID doesn't exist | Verify resource exists |
| 500 | Internal Server Error | Database failure, Kafka down | Retry with exponential backoff |
| 503 | Service Unavailable | Redis cache unavailable | Retry after delay |

### Retry Strategy

**Transient Errors** (500, 503):
```javascript
async function fetchWithRetry(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return response;
      if (response.status < 500) throw new Error('Client error');
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, i)));
    }
  }
}
```

**Client Errors** (400, 401, 404): Do not retry, fix request

---

## Rate Limiting

### Current Limits
- **No explicit rate limiting** on Analytics Service
- Rate limiting enforced at API Gateway level
- Typical limit: 100 requests/minute per user

### Future Enhancements
- Per-endpoint rate limiting
- Portfolio-specific quotas
- WebSocket connection limits

---

## Versioning

### Current Version
- **API Version**: v1 (implicit in path `/api`)
- **Breaking Changes**: Not expected in minor releases

### Future Versioning Strategy
- Major version in path: `/api/v2/analysis/all`
- Deprecation notices 90 days before removal
- Backward compatibility for 2 major versions

---

## Testing & Development

### Swagger/OpenAPI Documentation
Available at: `http://pms-analytics:8086/swagger-ui.html`

### Postman Collection
Available in repository: `/pms-analytics/docs/postman/`

### Sample Data
Use `/api/transactions` POST endpoint to generate test data

---

## Performance SLAs

| Endpoint Category | p50 | p95 | p99 |
|-------------------|-----|-----|-----|
| Analysis APIs | < 50ms | < 200ms | < 500ms |
| Sector APIs | < 100ms | < 300ms | < 1s |
| WebSocket Latency | < 20ms | < 50ms | < 100ms |

---

## Support & Troubleshooting

### Common Issues

**Issue**: 401 Unauthorized on all requests  
**Solution**: Verify JWT token is valid and not expired

**Issue**: Empty array returned from `/api/analysis/all`  
**Solution**: No transactions processed yet, use `/api/transactions` to seed data

**Issue**: WebSocket disconnects frequently  
**Solution**: Check network stability, verify SockJS fallback is working

**Issue**: Unrealised PnL not updating  
**Solution**: Verify Redis cache is populated with prices, check scheduler logs

### Debugging Tools
- Check service health: `GET /actuator/health`
- View metrics: `GET /actuator/metrics`
- Enable debug logging: Set `logging.level.com.pms.analytics=DEBUG`


|----|----|
| `position-update` | Holdings and realised PnL updates |
| `unrealised-pnl` | Unrealised PnL recalculations |

Authentication and subscription management are handled at the API Gateway layer.
