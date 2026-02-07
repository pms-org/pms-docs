# API Contract

## Base Path

/simulation

## Endpoints

### POST /simulation/create-portfolio

Creates a new portfolio via Portfolio Service and stores the ID.

Authentication:
Authorization header required (Bearer token)

Request Body:
PortfolioCreateRequest object

Response:
{
  "portfolioId": "UUID"
}
