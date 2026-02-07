# Deployment

## Container Ports

Host: 4000
Container: 8090

## Startup Dependencies

- RabbitMQ (healthy)
- PostgreSQL (healthy)

## Health Checks

RabbitMQ and Postgres health checks are defined in Docker Compose.

## Scaling

Simulation thread runs inside a single instance.
Multiple replicas will produce duplicate trade streams.
