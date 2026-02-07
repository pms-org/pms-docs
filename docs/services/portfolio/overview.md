---
sidebar_position: 1
title: Overview
---

# Portfolio Service — Overview

## Purpose

The Portfolio Service is responsible for creating and managing investor portfolio identifiers and related investor metadata.
It acts as the authoritative source for portfolio identity within the PMS platform.

## Responsibilities

- Generate unique portfolio IDs
- Persist investor profile information
- Enforce uniqueness on phone numbers
- Provide portfolio lookup APIs

## Consumers

- Simulation Service (portfolio creation proxy)
- Frontend via API Gateway
- Internal PMS services requiring portfolio metadata

## Dependencies

- PostgreSQL database
- API Gateway / Ingress
