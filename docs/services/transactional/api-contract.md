**Exposed REST Endpoints**

All endpoints are plain HTTP POST endpoints (no authentication enforced in this codebase). Payloads are JSON DTOs that the controller converts to the compiled `Trade` protobuf before publishing to Kafka.

- **POST /trades/publish**
  - Purpose: Publish a single trade message to the trades topic (used for manual ingestion/testing).
  - Body: `TradeDTO` (JSON) with fields: `tradeId` (UUID), `portfolioId` (UUID), `symbol` (string), `side` ("BUY"|"SELL"), `pricePerStock` (decimal), `quantity` (number), `timestamp` (ISO datetime).
  - Response: 200 OK with text "Trade Message published successfully" or 500 on failure.
  - Authentication: none implemented in code — protect behind API gateway.

- **POST /trades/publish/multi**
  - Purpose: Publish multiple trade messages in one call (batch ingestion).
  - Body: JSON array of `TradeDTO` objects (same fields as above).
  - Response: 200 OK with text "Trade messages published successfully" or 500 on failure.
  - Authentication: none implemented in code — protect behind API gateway.

Notes

- Endpoints are implemented in `EventController` and `EventControllerMulti`.
- These endpoints are conveniences for pushing `Trade` protos into Kafka via the service's configured producer; the primary production ingestion is expected to be via Kafka consumers/producers outside this service.

WebSocket: none.
