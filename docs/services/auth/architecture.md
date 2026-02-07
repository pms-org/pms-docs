# Architecture

## High-Level Flow

Client -> API Gateway -> Ingress -> Auth Service -> Database

## Components

1. Authorization Server Layer
Handles OAuth2 endpoints and token issuance.

2. REST Authentication Layer
Handles /api/auth login and signup endpoints.

3. Persistence Layer
Stores users in pms_users table.

4. JWT Infrastructure
Generates RSA keys and signs tokens.

## Scaling

Service is stateless except JWT keys.

Important:
Each pod generates its own RSA key pair. Horizontal scaling requires shared key storage.
