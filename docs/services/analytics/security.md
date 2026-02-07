---
sidebar_position: 6
title: Security
---

# Analytics Service — Security Model

## Authentication

- JWT-based via Auth Service
- Verified at API Gateway
- User context forwarded in headers

## Authorization

- Portfolio access restricted to owner
- Backend services allowed internally

## Public vs Protected Endpoints

- No public endpoints
- All REST and WebSocket endpoints are protected

## Token Usage

Authorization header format:

Authorization: Bearer `<JWT>`

## CORS / CSRF

- CORS restricted to approved frontend origins
- CSRF not applicable due to stateless JWT

## Rationale

Portfolio analytics contains sensitive financial data.  
All endpoints are protected to prevent unauthorized access or data leakage.
