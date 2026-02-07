# API Contract — pms-analytics

This document describes the **public REST APIs** exposed by the `pms-analytics` service.

All endpoints are routed through the API Gateway and require authentication unless explicitly configured otherwise at the gateway level.

Base Path: `/api`

---

# 1. Analysis APIs

## 1.1 Get All Analysis Records

**Endpoint**
GET /api/analysis/all

**Purpose**
Returns all analytics records stored in the analytics table.

**Response**

- HTTP 200 OK
- Body: `List<AnalysisEntity>`

**Authentication**
Required

**Used By**

- Internal dashboards
- Admin/inspection tools

---

## 1.2 Trigger Unrealised PnL Calculation

**Endpoint**
GET /api/unrealized

**Purpose**
Triggers unrealised PnL recalculation logic.  
This endpoint does not return a body. It is primarily used to manually invoke recalculation.

**Response**

- HTTP 200 OK
- No response body

**Authentication**
Required

**Notes**

- This is an execution endpoint, not a data retrieval endpoint.
- WebSocket topics are used to push updated values to clients.

---

## 1.3 Get Portfolio Value History

**Endpoint**
GET /api/portfolio_value/history/{portfolioId}

**Path Parameters**

| Name        | Type | Description          |
| ----------- | ---- | -------------------- |
| portfolioId | UUID | Portfolio identifier |

**Purpose**
Returns historical portfolio value snapshots for a given portfolio.

**Response**

- HTTP 200 OK
- Body: `List<PortfolioValueHistoryEntity>`

**Authentication**
Required

**Used By**

- Portfolio performance charts
- Risk and trend analysis dashboards

---

# 2. Sector Analysis APIs

Base Path: `/api/sectors`

---

## 2.1 Overall Sector Analysis

**Endpoint**
GET /api/sectors/overall

**Purpose**
Returns sector-level aggregated metrics across all portfolios.

**Response**

- HTTP 200 OK
- Body: `List<SectorMetricsDto>`

**Authentication**
Required

---

## 2.2 Sector-wise Symbol Analysis

**Endpoint**
GET /api/sectors/sector-wise/{sector}

**Path Parameters**

| Name   | Type   | Description |
| ------ | ------ | ----------- |
| sector | String | Sector name |

**Purpose**
Returns symbol-level metrics for a specific sector.

**Response**

- HTTP 200 OK
- Body: `List<SymbolMetricsDto>`

**Authentication**
Required

---

## 2.3 Portfolio-wise Sector Analysis

**Endpoint**
GET /api/sectors/portfolio-wise/{portfolioId}

**Path Parameters**

| Name        | Type | Description          |
| ----------- | ---- | -------------------- |
| portfolioId | UUID | Portfolio identifier |

**Purpose**
Returns sector metrics limited to a specific portfolio.

**Response**

- HTTP 200 OK
- Body: `List<SectorMetricsDto>`

**Authentication**
Required

---

## 2.4 Portfolio + Sector Symbol Analysis

**Endpoint**
GET /api/sectors/portfolio-wise/{portfolioId}/sector-wise/{sector}

**Path Parameters**

| Name        | Type   | Description          |
| ----------- | ------ | -------------------- |
| portfolioId | UUID   | Portfolio identifier |
| sector      | String | Sector name          |

**Purpose**
Returns symbol-level analytics for a given portfolio within a specific sector.

**Response**

- HTTP 200 OK
- Body: `List<SymbolMetricsDto>`

**Authentication**
Required

---

## 2.5 Sector Catalog

**Endpoint**
GET /api/sectors/sector-catalog

**Purpose**
Returns a catalog of all supported sectors and related metadata.

**Response**

- HTTP 200 OK
- Body: `List<SectorCatalogDto>`

**Authentication**
Required

---

# WebSocket Topics

This service **publishes** but does not expose WebSocket endpoints directly.

## Topics Published

| Topic           | Description                     |
| --------------- | ------------------------------- |
| position-update | Holdings & realised PnL updates |
| unrealised-pnl  | Unrealised PnL recalculations   |

Authentication and subscription management are handled at the API Gateway layer.
