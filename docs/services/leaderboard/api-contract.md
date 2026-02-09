---
sidebar_position: 3
title: API Contract
---

# Leaderboard Service — API Contract

## Base Path

/api/leaderboard

## Endpoints

### GET /api/leaderboard/top

Returns the top N portfolios by performance score.

**Authentication**
Handled at Gateway layer (USER token required).

**Query Parameters**

| Name  | Type    | Required | Default | Description                                   |
| ----- | ------- | -------- | ------- | --------------------------------------------- |
| `top` | integer | No       | 50      | Number of top portfolios to return (max 1000) |

**Response**

```json
{
  "rankings": [
    {
      "portfolioId": "uuid",
      "rank": 1,
      "score": 95.67,
      "sharpeRatio": 2.34,
      "sortinoRatio": 1.89,
      "avgRateOfReturn": 0.156
    }
  ],
  "totalCount": 1250,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

### GET /api/leaderboard/around

Returns portfolios around a specific portfolio's ranking position.

**Authentication**
Handled at Gateway layer (USER token required).

**Query Parameters**

| Name          | Type    | Required | Default | Description                                 |
| ------------- | ------- | -------- | ------- | ------------------------------------------- |
| `portfolioId` | string  | Yes      | -       | UUID of the portfolio                       |
| `range`       | integer | No       | 5       | Number of portfolios above/below to include |

**Response**

```json
{
  "targetPortfolio": {
    "portfolioId": "uuid",
    "rank": 45,
    "score": 87.23
  },
  "rankings": [
    {
      "portfolioId": "uuid",
      "rank": 40,
      "score": 89.12
    }
  ],
  "totalCount": 1250,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

## WebSocket Support

**Endpoint:** `/ws/leaderboard`

**Message Types:**

- `LEADERBOARD_UPDATE`: Real-time ranking changes
- `PORTFOLIO_UPDATE`: Specific portfolio score updates

**Authentication:** Same as REST APIs (USER token)
