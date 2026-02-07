---
sidebar_position: 6
title: Security
---

# Simulation Service — Security Model

## Authentication

This service forwards Authorization headers to downstream services.
No authentication is enforced internally.

## Authorization

All endpoints are currently publicly accessible.
Downstream services are responsible for enforcing authorization.

## CSRF

Disabled.

## Notes

Production deployment should restrict public access via API Gateway.
