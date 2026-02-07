---
sidebar_position: 2
title: Architecture
---

# Portfolio Service — Architecture

## High-Level Flow

Client -> API Gateway -> Portfolio Service -> PostgreSQL

## Components

1. REST Controller Layer
Handles portfolio create and read operations.

2. Service Layer
Business logic for validation and persistence.

3. Persistence Layer
Stores investor details with unique phone constraint.

## Data Model

Table: portfolio_investor_details

Fields:
- portfolioId (UUID, PK)
- name
- phoneNumber (unique)
- address
