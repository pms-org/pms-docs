# Failure Modes

## RabbitMQ Connection Failure

Symptoms:
Service fails during startup.

Cause:
RabbitMQ stream plugin not enabled or wrong credentials.

Debug:
Check logs and stream availability.

## Database Connection Failure

Symptoms:
Application startup failure.

Cause:
Wrong credentials or DB unreachable.

Debug:
Verify environment variables and network.

## Empty Trade Generation

Symptoms:
IllegalStateException thrown.

Cause:
Symbol or Portfolio tables empty.

Debug:
Populate base data.

## Stream Publish Failure

Symptoms:
Runtime exception thrown.

Cause:
Stream unavailable or broker overload.

Debug:
Check RabbitMQ management UI.
