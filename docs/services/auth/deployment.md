---
sidebar_position: 5
title: Deployment
---

# Auth Service — Deployment

## Container Ports

Host: 8085
Container: 8081

## Health Check

/actuator/health

## Scaling Notes

Multiple replicas will generate different JWT signing keys.
Use shared keystore in production.

## Traffic Flow

API Gateway -> Ingress -> Auth Service Pod
