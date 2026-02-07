---
sidebar_position: 4
title: Configuration
---

# Simulation Service — Configuration

## Server

SERVER_PORT=8090

## RabbitMQ

RABBITMQ_HOST
RABBITMQ_STREAM_PORT
RABBITMQ_STREAM_NAME
RABBITMQ_USERNAME
RABBITMQ_PASSWORD

## Database

DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD

## Downstream Services

PORTFOLIO_SERVICE_HOST
PORTFOLIO_SERVICE_PORT
API_GATEWAY_HOST
API_GATEWAY_PORT

## Behavior

Missing RabbitMQ or DB connectivity will prevent service startup.
