## Deployment & runtime — pms-rttm

How the service is built

- The repository contains a `Dockerfile` and several `docker-compose` variants for local or single-node runs. CI should build the JAR and image using Maven and push to your container registry.

Container and ports

- Default server port: `8087` (configurable via `SERVER_PORT`).
- WebSocket endpoints are served on the same HTTP port under `/ws/rttm/*`.

Kubernetes deployment notes

- Provide configuration with `ConfigMap` (non-sensitive) and `Secret` (DB/Kafka/Redis credentials).
- Required platform services:
  - PostgreSQL
  - Kafka brokers and Schema Registry
  - Redis Sentinel cluster

Probes and health

- Actuator is present. Use `/actuator/health` (or readiness/liveness variants) for probes.
- Make readiness probe depend on DB accessibility if you want to avoid accepting traffic when DB is unreachable; otherwise the service will run and buffer until DB recovers.

Startup ordering and behavior

- The Kafka consumers enqueue into in-memory queues; the service will not acknowledge messages if the in-memory queue is full — this provides backpressure to Kafka via lack of ack.
- On DB connectivity failures, aggregation or persistence will fail — in many cases consumers will continue to accept messages into memory until capacity is reached.

Scaling

- Scale consumers horizontally by increasing replicas; ensure topic partitions match desired parallelism.
- Watch in-process queue capacity per replica; scaling horizontally increases aggregate queueing capacity.

Ingress / API Gateway

- Place REST and WebSocket routes behind the API Gateway. For WebSockets, ensure the ingress supports WebSocket proxying and keep-alives.
- Configure origin restrictions and authentication at the Gateway layer.

Operational notes

- If you deploy a new version, perform rolling restarts. Monitor Kafka consumer lags and DB insert rates to ensure aggregations resume.
- For heavy traffic bursts, increase `RTTM_QUEUE_CAPACITY` or scale replicas to avoid prolonged Kafka redelivery.
