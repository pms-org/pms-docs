# Failure Modes

## Duplicate Phone Number

Symptoms:
Portfolio creation fails.

Cause:
Phone number already exists.

Behavior:
PortfolioCreationException thrown.

---

## Database Connection Failure

Symptoms:
Service fails to start.

Cause:
Incorrect credentials or DB unavailable.

Debug:
Check logs and environment variables.

---

## Portfolio Not Found

Symptoms:
GET by ID fails.

Cause:
Invalid UUID.

Behavior:
Exception thrown.
