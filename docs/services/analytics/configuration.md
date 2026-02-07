# Runtime Configuration

## Environment Variables

| Variable               | Purpose             | Required |
| ---------------------- | ------------------- | -------- |
| KAFKA_BROKERS          | Kafka endpoints     | Yes      |
| DB_URL                 | Database connection | Yes      |
| DB_USERNAME            | DB username         | Yes      |
| DB_PASSWORD            | DB password         | Yes      |
| REDIS_HOST             | Redis host          | Yes      |
| FINNHUB_API_KEY        | Market price API    | Yes      |
| PRICE_REFRESH_INTERVAL | Scheduler interval  | No       |

---

## ConfigMaps / Secrets

- Secrets: DB credentials, Finnhub API key
- ConfigMaps: Kafka topics, scheduler intervals

---

## Missing Values Behavior

- DB or Kafka missing → service fails to start
- Redis missing → degraded performance
- Finnhub missing → unrealised PnL disabled

---

## Dev vs Production Differences

- Dev may use mocked Finnhub responses
- Lower Kafka partition counts in dev
- Production uses full rate-limited Finnhub API
