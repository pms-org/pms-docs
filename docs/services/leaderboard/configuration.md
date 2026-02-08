# Configuration

## Environment Variables

Typical runtime configuration includes:

- `KAFKA_BOOTSTRAP_SERVERS`
- `KAFKA_CONSUMER_GROUP`
- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_SENTINEL_NODES`
- `SERVER_PORT`STY`
- `WEBSOCKET_ENABLED`

## Secrets

Expected via Kubernetes Secrets:

- Redis credentials
- Kafka authentication (if enabled)
- TLS materials

Secret values must never be embedded in images.

## Missing Configuration

Startup should fail fast if critical infrastructure settings are absent.  
Partial configuration is treated as misdeployment.

## Environment Differences

**Development**
- Reduced Kafka partitions
- Single Redis instance

**Production**
- HA Redis via Sentinel
- Multi-partition Kafka
- Autoscaling enabled
