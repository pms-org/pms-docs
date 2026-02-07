# API Contract

## Role

The API Gateway proxies requests; it does not own business APIs.

## Public Routes

- /api/auth/**
- /fallback
- /actuator/**

## Protected Routes

SERVICE token:
- /simulation/**
- /portfolio/**

USER token:
- /api/leaderboard/**
- /api/rttm/**
- /api/analysis/**
- /api/sectors/**
- /api/transactions/**
- /api/portfolio_value/**
- /api/unrealized/**

## WebSocket Routes

- /ws/**
