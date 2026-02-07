# Deployment

## Container Deployment

Exposed behind API Gateway.

## Startup Dependencies

- PostgreSQL database must be reachable.

## Health

Spring Boot actuator can be enabled for readiness/liveness.

## Scaling

Service is stateless.
Horizontal scaling is supported.
Database handles uniqueness enforcement.
