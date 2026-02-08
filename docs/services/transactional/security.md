**Security Model**

Current implementation: there is no application-level authentication or authorization in the code. Controllers do not validate tokens and there is no Spring Security configuration present. The service relies on infrastructure controls to enforce access.

Recommended deployment-side protections (what to expect in production):

- API Gateway / Ingress: require authentication (JWT or mTLS) and only allow authorized services to call `/trades/publish*`.
- Network controls: deploy the service into a private Kubernetes namespace and restrict access with network policies.
- Secrets: DB credentials, Kafka bootstrap URL and schema registry URL must be supplied from Kubernetes Secrets (never stored in plaintext in repo).

Authentication & tokens

- The code does not consume or validate JWTs or other tokens. If the platform exposes this service publicly, the API Gateway must validate tokens and propagate only trusted requests to this workload.

Authorization rules

- There are no role checks in-service. Any authorization decision must be enforced upstream (gateway or ingress controller).

CORS / CSRF

- No explicit CORS or CSRF configuration is present. If an HTTP public UI will call these endpoints, configure CORS on the gateway. Since controllers accept JSON POSTs, CSRF is not handled in the application and should be handled by the gateway.

Why this is acceptable today

- This service is an internal backend processor primarily consuming Kafka; the tiny HTTP endpoints are convenience/test endpoints. Production hardening should be performed at the perimeter (gateway/ingress) and via K8s network policies and secrets.
