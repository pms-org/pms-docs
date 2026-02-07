# API Gateway — Overview

## Purpose

The API Gateway is the single entry point for all external traffic into the PMS platform.
It handles routing, authentication enforcement, rate limiting, resiliency, and cross-cutting concerns.

## Responsibilities

- Route requests to appropriate backend services
- Enforce authentication and token-type based authorization
- Apply rate limiting, retries, and circuit breakers
- Handle CORS for browser clients
- Provide centralized logging and correlation IDs

## Consumers

- Frontend (browser-based clients)
- External API consumers
- Internal PMS services via routed paths

## Dependencies

- Auth Service (JWT issuer)
- Redis (rate limiting)
- Downstream PMS services
