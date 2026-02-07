# API Contract

## REST Endpoints

### GET /analytics/portfolio/{portfolioId}

Purpose: Portfolio analytics summary  
Authentication: Required

---

### GET /analytics/portfolio/{portfolioId}/positions

Purpose: Holdings + realised/unrealised PnL  
Authentication: Required

---

### GET /analytics/portfolio/{portfolioId}/sector-composition

Purpose: Sector allocation breakdown  
Authentication: Required

---

### GET /analytics/risk/{portfolioId}

Purpose: Risk metrics  
Authentication: Required

---

## WebSocket Topics

### position-update

- Holdings changes
- Realised PnL updates

### unrealised-pnl

- Price-driven PnL recalculations

Authentication required via gateway token propagation.
