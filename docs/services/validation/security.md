## Security model — pms-validation

Summary

- The application itself does not implement any HTTP authentication or authorization for its controller endpoints. Security is expected to be enforced by the platform (API Gateway / Ingress, network policies).
- The service relies on secure infrastructure for sensitive systems: Kafka (TLS + auth), Schema Registry (auth), PostgreSQL credentials, and Redis Sentinel passwords.

Authentication & Authorization

- HTTP endpoints: no Spring Security configuration is present. If the service is exposed through the API Gateway, require authentication (e.g., mTLS or JWT) and only expose the simulator endpoints to internal/qa namespaces.
- Kafka: the code expects `spring.kafka.bootstrap-servers` (and a Schema Registry URL). In production Kafka brokers and Schema Registry must be configured to require TLS and client authentication (SASL/mTLS) depending on platform setup.
- Database: credentials are read from environment variables and must be stored in Kubernetes Secrets.

Token usage and headers

- The service does not consume JWTs or other tokens directly.
- RTTM client usage uses Kafka or configured client; authentication to RTTM should be configured via the RTTM client configuration (platform-side).

Public vs protected endpoints

- The only HTTP endpoints are the test/simulation endpoints (`/trade-simulator/*`). Treat these as protected:
  - In production, disable them or restrict to an internal network and authenticated roles.
  - The Kafka listener and outbox processing are internal processing flows and are not exposed directly over HTTP.

CORS / CSRF

- CORS and CSRF are not relevant because this service does not expose browser-facing APIs (no public endpoints intended for web UIs). If you add a browser-facing API later, implement CORS with a strict allowlist and enable CSRF protections for stateful endpoints.

Secrets management

- All sensitive runtime configuration must be provided via Kubernetes Secrets or a secrets manager:
  - DB_USERNAME, DB_PASSWORD
  - KAFKA credentials (if using SASL), SCHEMA_REGISTRY credentials
  - REDIS_SENTINEL_PASSWORD and REDIS_PASSWORD
  - Any RTTM client credentials

Why this model

- The service design offloads authentication/authorization and perimeter protections to the platform. That keeps the microservice lightweight and avoids duplicating policy logic inside the service.

Recommendations

- Ensure the API Gateway enforces auth for any HTTP endpoint that reaches this service.
- Use network policies and mTLS between services where supported.
- Rotate DB and Redis credentials regularly and store them as Secrets; do not bake secrets into images.
