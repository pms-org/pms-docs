# Security Model

## Authentication

This service does not enforce authentication internally.
Security is expected to be handled by API Gateway.

## Authorization

No role-based restrictions implemented.

## CORS

Allowed Origin:
http://localhost:4200

Allows credentials and all headers.

## CSRF

Not explicitly enabled.
Relies on stateless API usage.
