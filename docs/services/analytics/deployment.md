# Deployment

## Deployment Model
- Kubernetes Deployment on EKS
- Stateless pods
- Rolling updates enabled

---

## Startup Dependencies
- Kafka must be reachable
- PMS DB must be reachable
- Redis recommended but not mandatory

---

## Health Checks
### Liveness Probe
- Confirms JVM is alive

### Readiness Probe
- Confirms DB and Kafka connectivity

---

## Scaling Behavior
- Horizontal Pod Autoscaler enabled
- Scaling triggered by CPU usage and Kafka lag

---

## Ingress / Gateway Flow

Frontend  
→ API Gateway  
→ Kubernetes Ingress  
→ Service  
→ Pods
