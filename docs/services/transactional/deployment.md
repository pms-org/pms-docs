**Kubernetes & Runtime**

How the service is built

- Standard Maven build using the included `Dockerfile`. The Dockerfile builds a fat JAR and runs it with `java -jar /app/app.jar` exposing port `8084` (default).

Image / container

- Build with `mvn -B -f pom.xml clean package -DskipTests` then build the image using the repo `Dockerfile`.

Suggested Kubernetes deployment (what to expect)

- Deploy as a Deployment with liveness/readiness probes pointing to Spring Boot Actuator endpoints: `/actuator/health` and `/actuator/health/readiness` (management endpoints are enabled in `application.yml`).
- Provide env from `ConfigMap` for non-sensitive settings and `Secret` for DB/Kafka credentials.
- Configure resource requests/limits matching JVM heap (`JAVA_OPTS`) and the expected batch processing throughput.

Startup dependencies

- PostgreSQL must be reachable at the configured JDBC URL. On DB unavailability the `BatchProcessor` will pause consumption and run a probe to resume when DB becomes available.
- Kafka + Schema Registry must be reachable for producers/consumers to work.
- RTTM client endpoints (if configured for Kafka) must be reachable to publish telemetry.

Health checks

- Actuator health endpoints are available (management endpoints exposed). Use:

```bash
GET /actuator/health
GET /actuator/metrics
```

Scaling

- The consumer factory config sets concurrency to 5. To scale horizontally, ensure Kafka partitioning uses portfolioId as routing key so ordering/portfolio locks remain effective.
- Outbox dispatcher keeps portfolio-ordered processing using advisory locks in `OutboxEventsDao.findPendingWithPortfolioXactLock` — avoid running multiple replicas processing the same portfolio concurrently if you bypass partitioning.

Ingress / API Gateway

- In production, front HTTP ingress through the API Gateway. The service itself performs no auth and should not be exposed publicly without gateway protections (JWT, mTLS, rate limits).

CI / CD notes

- A `Jenkinsfile` and `docker-compose` are present for local/test orchestration. Production delivery should push images to a registry and use K8s manifests/Helm chart to configure environment variables and secrets.
