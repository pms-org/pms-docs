---
sidebar_position: 2
title: Architecture
---

# Simulation Service — Architecture

## High-Level Flow

Client -> API Gateway -> Simulation Service -> Portfolio Service
                                  |
                                  v
                            PostgreSQL (IDs)
                                  |
                                  v
                           RabbitMQ Stream

## Components

1. REST Controller
Handles portfolio creation requests.

2. Trade Generator
Creates valid, invalid and partial trade events.

3. Stream Producer
Publishes protobuf messages to RabbitMQ Streams.

4. Persistence Layer
Stores generated portfolio IDs.
