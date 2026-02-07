## API contract — pms-validation

This service is primarily a Kafka consumer/producer. There are a small set of HTTP endpoints intended for testing and simulation only. There are no public WebSocket endpoints.

Important: The HTTP endpoints present in this codebase are intended for local testing or internal automation. In production they must be placed behind the API Gateway and protected by authentication and network controls.

REST endpoints

- POST /trade-simulator/simulate
  - Purpose: Send a single trade payload into the service's ingestion flow. The controller converts the incoming DTO to the ingestion protobuf and sends it to the ingestion topic.
  - Request body: JSON representation of `TradeDto` (see source `com.pms.validation.dto.TradeDto`).
  - Authentication: None implemented in this service. Must be protected by the gateway.

- POST /trade-simulator/simulate-batch
  - Purpose: Send a list of trades in one request (each trade will be published to the ingestion topic).
  - Request body: JSON array of `TradeDto`.
  - Authentication: None.

- POST /trade-simulator/simulate-generate
  - Purpose: Generate N random trades and send them to the ingestion topic. Useful for local/system testing.
  - Request body (optional): { "count": <int>, "portfolioId": "<uuid-or-string>" }
  - Authentication: None.

Kafka topics (external interface)

- Incoming (consumed by this service): configured via `app.incoming-trades-topic`.
- Outgoing valid trades: `app.outgoing-valid-trades-topic` — emits `TradeEventProto` messages for downstream consumers.
- Outgoing invalid trades: `app.outgoing-invalid-trades-topic` — invalid trades are persisted and published here.

Message format

- Protobuf messages are used. Producer/consumer configuration uses Confluent Protobuf serializers/deserializers and requires a Schema Registry (see `schema.registry.url`).

Authentication

- No application-level authentication is implemented for the REST endpoints. Kafka authentication and TLS are expected to be enforced at the platform level (broker/network/Schema Registry).

Notes

- Do not rely on the `/trade-simulator` endpoints for production traffic. They are for tests and offline generation only.
