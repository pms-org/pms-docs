# Security Model

## Authentication

User Authentication:
- Username and password
- BCrypt hashing

Service Authentication:
- OAuth2 Client Credentials

## JWT

- RSA signed
- token_type claim added
- roles claim added

## CORS

Allowed origin:
http://localhost:4200

## CSRF

Disabled since token-based auth is used.

## Public Endpoints

- /api/auth/login
- /api/auth/signup
- /swagger-ui/**
- /v3/api-docs/**
- /actuator/**
