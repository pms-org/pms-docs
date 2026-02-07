# Simulation Service — Overview

## Purpose

The Simulation Service generates synthetic trade events and forwards them to the PMS streaming pipeline.
It also acts as a proxy to create portfolios via downstream Portfolio Service.

## Responsibilities

- Generate realistic and faulty trade events
- Persist portfolio IDs locally
- Publish trade events to RabbitMQ Streams
- Forward portfolio creation requests to Portfolio Service

## Consumers

- Internal PMS services (stream consumers)
- API Gateway for triggering portfolio creation

## Dependencies

- RabbitMQ Streams
- PostgreSQL database
- Portfolio Service
- API Gateway
