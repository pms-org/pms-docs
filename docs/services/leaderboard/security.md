# Security

## Authentication

Authentication is enforced upstream by the API Gateway before requests reach the service.

Typical mechanism:

- JWT bearer tokens
- Identity propagated via headers

The service trusts the gateway as the authentication boundary.

## Authorization

Authorization is coarse-grained:

- Authenticated users may read leaderboard data.
- Write access occurs through Kafka, not public APIs.

This reduces the attack surface.

## Public vs Protected

There are no intentionally public endpoints.

All traffic should pass through gateway controls.

## Token Handling

Tokens are not generated or validated locally.  
The service relies on verified identity headers.

This simplifies the runtime and avoids duplicated auth logic.

## CORS / CSRF

Handled at the gateway layer.

The service assumes traffic originates from trusted infrastructure.
