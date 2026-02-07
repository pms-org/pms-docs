## Deployment & runtime — pms-validation

How the service is built

- The repository contains a `docker/Dockerfile` which builds the Spring Boot JAR with Maven and produces a runtime image using Temurin JRE.
- Build steps (CI):
  - `mvn -DskipTests clean package`
  - Build a container image from `docker/Dockerfile` and push to your registry.

Kubernetes deployment notes

- Container port: default `8083` (configurable via `SERVER_PORT`).
- Provide runtime configuration through `ConfigMap` and `Secret` objects.
- Required platform services at startup:
  - PostgreSQL (DB_HOST/DB_PORT/DB_NAME and credentials)
  - Kafka brokers and Schema Registry (KAFKA_BOOTSTRAP_SERVERS + SCHEMA_REGISTRY_URL)
  - Redis Sentinel cluster (REDIS_SENTINEL_NODES, REDIS_SENTINEL_MASTER)

Suggested Deployment manifest (conceptual)

- Deployment (multiple replicas) with:
  - envFrom: ConfigMap for non-sensitive values
  - envFrom: Secret for DB/Redis/Kafka credentials
  - resource limits and requests for CPU/memory (the rules engine can be CPU bound)
  - readinessProbe: HTTP GET /actuator/health (or /actuator/health/readiness) — ensure DB and required indicators are UP
  - livenessProbe: HTTP GET /actuator/health (or a dedicated /actuator/health/liveness)

Startup dependencies and ordering

- The service expects Kafka, Schema Registry, PostgreSQL, and Redis to be reachable at startup. If the DB is unreachable the service contains logic (DbHealthMonitor / ValidationBatchProcessor) that will pause consumers and attempt to resume when the DB returns.
- Because the service uses Spring Kafka consumers, ensure broker reachability and correct topics exist (topics are created using `NewTopic` beans but platform may restrict auto-create).

Health checks

- Actuator endpoints are available (dependency `spring-boot-starter-actuator`). Use `/actuator/health` as the readiness/liveness check.
- The service contains a `DbHealthMonitor` that will pause Kafka consumption when the DB is down. That means even when the app pod is `Running`, it may not be processing messages if the DB is down — check logs and buffer sizes.

Scaling behavior

- Horizontal scaling: the consumer group (`spring.kafka.consumer.group-id`) coordinates partition assignment across replicas.
- Increase replicas to increase parallel processing, assuming Kafka topic partitions sufficiently large.
- Batch processing uses an in-memory buffer—too many concurrent replicas with small input might cause more contention for Redis keys; rely on partitioning to distribute load.

Ingress / API Gateway

- This service does not expose public HTTP APIs for frontend consumption. If you do expose endpoints (e.g., the simulator), place them behind the API gateway/ingress and apply authentication.
- Typical ingress routes forward requests to the service cluster IP on port 8083.

Operational runbook snippets

- To restart after configuration changes:
  - Update ConfigMap/Secret and rollout restart the deployment.
  - Monitor the `validation_outbox` table for backlogs after a restart.
