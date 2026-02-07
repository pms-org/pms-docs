## Security model — pms-rttm

Summary

- The application does not implement HTTP authentication or authorization within the codebase. It relies on platform-level controls (API Gateway, Ingress, network policies) to protect endpoints and WebSocket routes.
- Kafka, PostgreSQL and Redis should be secured by the platform (TLS, SASL, credentials in Secrets).

Authentication & Authorization

- HTTP & WebSocket: no Spring Security configuration is present. The code configures WebSocket handlers with `setAllowedOrigins("*")` which is permissive — restrict origins and apply auth at the ingress/gateway for production.
- Kafka: configure TLS and client authentication on brokers and Schema Registry; client credentials must be injected at runtime through Secrets and environment variables.
- Database: credentials read from `DB_USERNAME` / `DB_PASSWORD` environment variables — store these in Kubernetes Secrets.

Public vs protected endpoints

- Treat all REST APIs and WebSocket endpoints as internal / protected. Expose them only to trusted networks or behind the API Gateway with authentication (JWT, mTLS).

Token usage and headers

- The service does not consume or validate JWTs itself. If the API Gateway injects a JWT or headers, downstream services that call these endpoints must validate them or rely on the Gateway to have done so.

CORS / CSRF

- CORS is effectively wide-open for WebSockets in the current configuration; restrict to specific origins in production.
- CSRF is not applicable for WebSocket telemetry endpoints, but if new state-changing REST endpoints are added, implement CSRF protections where applicable.

Secrets management

- Put sensitive runtime values in Kubernetes Secrets:
  - `DB_USERNAME`, `DB_PASSWORD`
  - `KAFKA` credentials and Schema Registry credentials
  - `REDIS_PASSWORD`, `REDIS_SENTINEL_PASSWORD`

Why this model

- RTTM focuses on aggregation and telemetry and delegates perimeter security to the platform to avoid duplicating policy logic. This keeps the service lightweight but requires the platform to enforce robust security controls.

Recommendations

- Restrict WebSocket origins in `WebSocketConfig` or via Ingress rules.
- Use mTLS between services where possible and ensure Kafka and Schema Registry are configured to require authentication and encryption.
- Rotate Secrets regularly and centralize secret management.
