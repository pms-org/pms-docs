# Failure Modes & Debugging

## Redis Unavailable

**Symptoms**
- Increased latency
- Write failures
- Read errors

**Diagnosis**
- Check Redis health
- Inspect connection pool exhaustion
- Review network policies

**Expected Behavior**
Backpressure should slow ingestion rather than crash the service.

---

## Kafka Lag Growing

**Symptoms**
- Leaderboard delays
- Consumer metrics rising

**Diagnosis**
- Inspect consumer group lag
- Verify batch processor throughput
- Check Redis write times

---

## Event Buffer Saturation

**Symptoms**
- Consumer pauses
- Throughput drops

**Cause**
Write path slower than ingest rate.

**Action**
Scale pods or evaluate Redis capacity.

---

## WebSocket Disconnects

**Symptoms**
- Clients reconnect frequently

**Diagnosis**
- Inspect ingress timeouts
- Check load balancer idle settings

---

## Abnormal vs Expected

| Behavior | Expected |
|--------|-----------|
| Short Kafka lag during deploy | Yes |
| Temporary Redis reconnect | Yes |
| Persistent buffer exhaustion | No |
| Continuous readiness failures | No |

On-call engineers should prioritize infrastructure health before suspecting application defects.
