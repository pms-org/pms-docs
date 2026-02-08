# Deployment

## Platform

The service runs on Kubernetes (EKS).

It is exposed through:

API Gateway → Ingress → Service → Pods

## Startup Dependencies

The service expects:

- Kafka reachable
- Redis reachable
- Network policies allowing traffic

If dependencies are unavailable, the service may start but remain degraded.

## Health Checks

**Liveness:** ensures the JVM/process is running.  
**Readiness:** should reflect Redis connectivity.

Pods not ready should not receive traffic.

## Scaling

Horizontal Pod Autoscaling is recommended based on:

- CPU
- Consumer lag
- Request latency

Because the service is stateless, scaling does not require coordination.

## Rolling Deployments

Safe due to consumer group rebalancing.

Temporary lag during rollout is expected but should recover automatically.
