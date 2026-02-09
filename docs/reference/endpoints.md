---
sidebar_position: 1
title: API Endpoints
---

---
sidebar_position: 1
title: API Endpoints
---

# API Endpoints Reference

## Overview

This document provides a comprehensive reference for all PMS platform API endpoints, organized by service. All endpoints require appropriate authentication tokens (USER or SERVICE) as specified in the security requirements.

## Authentication Endpoints

### Auth Service
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com/api/auth`

#### POST /api/auth/login
Authenticate user and obtain JWT token.

**Request**:
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

**Response**:
```json
{
  "accessToken": "eyJraWQiOiI...",
  "tokenType": "Bearer",
  "expiresIn": 3600
}
```

**Security**: None required
**Rate Limit**: 10 requests/minute

#### POST /oauth2/token
Obtain service token for machine-to-machine authentication.

**Request**:
```http
POST /oauth2/token
Authorization: Basic <base64(client_id:client_secret)>
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=service
```

**Response**:
```json
{
  "access_token": "eyJraWQiOiI...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**Security**: Basic Authentication
**Rate Limit**: 100 requests/minute

## Portfolio Service Endpoints

### Portfolio Management
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com/api/portfolio`

#### POST /api/portfolio/create
Create a new portfolio.

**Request**:
```http
POST /api/portfolio/create
Authorization: Bearer <USER_TOKEN>
Content-Type: application/json

{
  "name": "John Doe Portfolio",
  "phoneNumber": "1234567890",
  "address": "123 Main St, New York, NY"
}
```

**Response**:
```json
{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Portfolio created successfully"
}
```

**Security**: USER token required
**Rate Limit**: 5 requests/minute per user

#### GET /api/portfolio/{portfolioId}
Retrieve portfolio details by ID.

**Request**:
```http
GET /api/portfolio/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <USER_TOKEN>
```

**Response**:
```json
{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe Portfolio",
  "phoneNumber": "1234567890",
  "address": "123 Main St, New York, NY",
  "createdAt": "2026-02-09T10:30:00Z",
  "updatedAt": "2026-02-09T10:30:00Z"
}
```

**Security**: USER token required
**Rate Limit**: 60 requests/minute

#### GET /api/portfolio/list
List all portfolios (paginated).

**Request**:
```http
GET /api/portfolio/list?page=0&size=20&sort=createdAt,desc
Authorization: Bearer <USER_TOKEN>
```

**Response**:
```json
{
  "content": [
    {
      "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Doe Portfolio",
      "phoneNumber": "1234567890",
      "createdAt": "2026-02-09T10:30:00Z"
    }
  ],
  "pageable": {
    "page": 0,
    "size": 20,
    "sort": ["createdAt,desc"]
  },
  "totalElements": 150,
  "totalPages": 8
}
```

**Security**: USER token required
**Rate Limit**: 30 requests/minute

## Simulation Service Endpoints

### Portfolio Simulation
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com/simulation`

#### POST /simulation/create-portfolio
Create portfolio via simulation service.

**Request**:
```http
POST /simulation/create-portfolio
Authorization: Bearer <USER_TOKEN>
Content-Type: application/json

{
  "name": "Simulation Portfolio",
  "phoneNumber": "9876543210",
  "address": "456 Simulation Ave, Test City"
}
```

**Response**:
```json
{
  "portfolioId": "7c9e6679-7425-40de-944b-e07fc1f90ae7"
}
```

**Security**: USER token required
**Rate Limit**: 5 requests/minute per user

#### POST /simulation/run-scenario
Execute portfolio simulation scenario.

**Request**:
```http
POST /simulation/run-scenario
Authorization: Bearer <USER_TOKEN>
Content-Type: application/json

{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "scenario": {
    "name": "Market Crash Scenario",
    "parameters": {
      "marketDrop": 0.3,
      "duration": 90
    }
  }
}
```

**Response**:
```json
{
  "simulationId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "RUNNING",
  "estimatedCompletion": "2026-02-09T11:15:00Z"
}
```

**Security**: USER token required
**Rate Limit**: 10 requests/minute per user

#### GET /simulation/status/{simulationId}
Check simulation execution status.

**Request**:
```http
GET /simulation/status/a1b2c3d4-e5f6-7890-abcd-ef1234567890
Authorization: Bearer <USER_TOKEN>
```

**Response**:
```json
{
  "simulationId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "COMPLETED",
  "results": {
    "finalValue": 85000.50,
    "pnl": -15000.00,
    "maxDrawdown": 0.25
  },
  "completedAt": "2026-02-09T11:10:00Z"
}
```

**Security**: USER token required
**Rate Limit**: 60 requests/minute

## Analytics Service Endpoints

### Risk Analytics
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com/api/analytics`

#### GET /api/analytics/portfolio/{portfolioId}/risk
Get portfolio risk metrics.

**Request**:
```http
GET /api/analytics/portfolio/550e8400-e29b-41d4-a716-446655440000/risk
Authorization: Bearer <SERVICE_TOKEN>
```

**Response**:
```json
{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "riskMetrics": {
    "valueAtRisk": 0.15,
    "expectedShortfall": 0.22,
    "sharpeRatio": 1.8,
    "maxDrawdown": 0.12,
    "volatility": 0.18
  },
  "calculatedAt": "2026-02-09T10:45:00Z"
}
```

**Security**: SERVICE token required
**Rate Limit**: 100 requests/minute

#### GET /api/analytics/portfolio/{portfolioId}/pnl
Get unrealized PnL data.

**Request**:
```http
GET /api/analytics/portfolio/550e8400-e29b-41d4-a716-446655440000/pnl?period=1D
Authorization: Bearer <SERVICE_TOKEN>
```

**Response**:
```json
{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "pnl": {
    "unrealized": 2500.75,
    "realized": 15000.00,
    "total": 17500.75
  },
  "period": "1D",
  "timestamp": "2026-02-09T10:45:00Z"
}
```

**Security**: SERVICE token required
**Rate Limit**: 200 requests/minute

## Trade Capture Service Endpoints

### Trade Management
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com/api/trade`

#### POST /api/trade/capture
Capture a new trade.

**Request**:
```http
POST /api/trade/capture
Authorization: Bearer <SERVICE_TOKEN>
Content-Type: application/json

{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "symbol": "AAPL",
  "quantity": 100,
  "price": 150.25,
  "tradeType": "BUY",
  "timestamp": "2026-02-09T10:30:00Z"
}
```

**Response**:
```json
{
  "tradeId": "t123456789",
  "status": "CAPTURED",
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Security**: SERVICE token required
**Rate Limit**: 500 requests/minute

#### GET /api/trade/portfolio/{portfolioId}
Get trade history for portfolio.

**Request**:
```http
GET /api/trade/portfolio/550e8400-e29b-41d4-a716-446655440000?startDate=2026-01-01&endDate=2026-02-09
Authorization: Bearer <SERVICE_TOKEN>
```

**Response**:
```json
{
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "trades": [
    {
      "tradeId": "t123456789",
      "symbol": "AAPL",
      "quantity": 100,
      "price": 150.25,
      "tradeType": "BUY",
      "timestamp": "2026-02-09T10:30:00Z",
      "status": "SETTLED"
    }
  ],
  "totalCount": 1
}
```

**Security**: SERVICE token required
**Rate Limit**: 100 requests/minute

## Leaderboard Service Endpoints

### Performance Rankings
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com/api/leaderboard`

#### GET /api/leaderboard/top-performers
Get top performing portfolios.

**Request**:
```http
GET /api/leaderboard/top-performers?period=1M&limit=10
Authorization: Bearer <USER_TOKEN>
```

**Response**:
```json
{
  "period": "1M",
  "rankings": [
    {
      "rank": 1,
      "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
      "performance": 0.156,
      "pnl": 15600.00
    }
  ],
  "totalPortfolios": 500
}
```

**Security**: USER token required
**Rate Limit**: 30 requests/minute

## Health Check Endpoints

### Service Health
**Base URL**: `http://k8s-pms-pmsingre-*.elb.amazonaws.com`

#### GET /actuator/health
Service health check.

**Request**:
```http
GET /actuator/health
```

**Response**:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "SELECT 1"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 1073741824,
        "free": 536870912,
        "threshold": 10485760
      }
    }
  }
}
```

**Security**: None required
**Rate Limit**: 60 requests/minute

## WebSocket Endpoints

### Real-time Data
**Base URL**: `ws://k8s-pms-pmsingre-*.elb.amazonaws.com/ws`

#### /ws/portfolio/{portfolioId}
Portfolio real-time updates.

**Connection**:
```javascript
const ws = new WebSocket('ws://k8s-pms-pmsingre-*.elb.amazonaws.com/ws/portfolio/550e8400-e29b-41d4-a716-446655440000');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Portfolio update:', data);
};
```

**Message Format**:
```json
{
  "type": "PORTFOLIO_UPDATE",
  "portfolioId": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "currentValue": 125000.50,
    "pnl": 25000.50,
    "lastUpdate": "2026-02-09T11:00:00Z"
  }
}
```

**Security**: USER token in query parameter
**Rate Limit**: 100 messages/minute per connection

## Error Response Format

All endpoints return standardized error responses:

```json
{
  "timestamp": "2026-02-09T11:00:00.000+00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Invalid portfolio data",
  "path": "/api/portfolio/create",
  "requestId": "abc123"
}
```

## Common HTTP Status Codes

| Status Code | Description | Common Causes |
|-------------|-------------|---------------|
| 200 | Success | Request processed successfully |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request data or parameters |
| 401 | Unauthorized | Missing or invalid authentication token |
| 403 | Forbidden | Insufficient permissions or wrong token type |
| 404 | Not Found | Resource or endpoint not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | Service temporarily unavailable |

## Rate Limiting

Rate limits are enforced per client IP and user token:

- **Authentication**: 10 req/min (login), 100 req/min (service tokens)
- **Portfolio Operations**: 5 req/min per user
- **Read Operations**: 60 req/min
- **Analytics**: 100-200 req/min
- **Trade Capture**: 500 req/min
- **Health Checks**: 60 req/min

Rate limit headers are included in responses:
```
X-RateLimit-Remaining: 9
X-RateLimit-Requested-Tokens: 1
X-RateLimit-Burst-Capacity: 10
X-RateLimit-Replenish-Rate: 5
```

## Versioning

API versioning is handled through URL paths:
- **Current Version**: v1 (implied, no version prefix)
- **Future Versions**: `/v2/portfolio/create`

## Content Types

- **Request**: `application/json`
- **Response**: `application/json`
- **File Uploads**: `multipart/form-data`

## Pagination

List endpoints support pagination:
- `page`: Page number (0-based)
- `size`: Page size (default: 20, max: 100)
- `sort`: Sort criteria (e.g., `createdAt,desc`)

## Filtering

Advanced filtering supported on list endpoints:
- `startDate`: ISO 8601 date string
- `endDate`: ISO 8601 date string
- `status`: Status filter
- `type`: Type filter
