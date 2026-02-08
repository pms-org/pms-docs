# API Contract

## External Endpoints

### GET /leaderboard

**Purpose:**  
Returns the current leaderboard rankings.

**Authentication:** Required

**Typical Usage:**  
Frontend leaderboard screens or backend ranking checks.

---

### GET /leaderboard/{playerId}

**Purpose:**  
Returns the rank and score for a specific player.

**Authentication:** Required

---

## WebSocket

### /ws/leaderboard

**Purpose:**  
Streams real-time leaderboard updates to connected clients.

**Authentication:** Expected via gateway before upgrade.

**Behavior:**  
Clients receive incremental updates rather than polling.

---

## Notes

- No internal-only endpoints are documented here.
- Rate limiting is expected to be enforced upstream at the gateway.
