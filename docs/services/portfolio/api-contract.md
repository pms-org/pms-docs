# API Contract

## Base Path

/api/portfolio

## Endpoints

### POST /api/portfolio/create

Creates a new portfolio.

Authentication:
Handled at Gateway layer

Request Body:
```json
{
  "name": "string",
  "phoneNumber": number,
  "address": "string"
}
```

Response:
```json
{
  "portfolioId": "UUID"
}
```

---

### GET `/api/portfolio/{id}`

Returns portfolio details.

---

### GET /api/portfolio/all

Returns all portfolios.
