---
sidebar_position: 3
title: API Contract
---

# Simulation Service — API Contract

## Base Path

/simulation

## Endpoints

### POST /simulation/create-portfolio

Creates a new portfolio via Portfolio Service and stores the generated portfolio ID.

**Authentication**  
Authorization header required (Bearer token).

**Request Body**

```text
PortfolioCreateRequest
```

**Response**

```json
{
  "portfolioId": "UUID"
}
```
