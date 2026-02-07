---
sidebar_position: 3
title: API Contract
---

# Portfolio Service — API Contract

## Base Path

/api/portfolio

## Endpoints

### POST /api/portfolio/create

Creates a new portfolio.

**Authentication**  
Handled at Gateway layer.

**Request Body**

```json
{
  "name": "string",
  "phoneNumber": 1234567890,
  "address": "string"
}
```

**Response**

```json
{
  "portfolioId": "UUID"
}
```

---

### GET /api/portfolio/`{id}`

Returns portfolio details for a given portfolio ID.

**Authentication**  
Handled at Gateway layer.

**Path Parameters**

| Name | Type | Description |
|----|----|----|
| `id` | UUID | Portfolio identifier |


### GET /api/portfolio/all

Returns all portfolios.

**Authentication**  
Handled at Gateway layer.
