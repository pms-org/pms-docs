# Architecture

## High-Level Flow

Client
  |
API Gateway (Spring Cloud Gateway)
  |
  +--> Auth Service
  +--> Simulation Service
  +--> Portfolio Service
  +--> Analytics Service
  +--> Leaderboard Service
  +--> RTTM Service

## Core Components

1. Routing Layer
2. Security Layer
3. Resilience Layer
4. Observability Layer
