---
sidebar_position: 1
title: Overview
---

# Auth Service — Overview

## Purpose

The Auth Service is responsible for authentication and token issuance inside the PMS platform. It provides:

- User registration and login for frontend users
- OAuth2 client credentials token issuance for service-to-service communication
- JWT signing and public key exposure via JWKS

It acts as the central identity and token authority for PMS.

## Responsibilities

- User credential validation
- Secure password storage (BCrypt hashing)
- JWT token generation for users and services
- OAuth2 Authorization Server functionality
- Token claim customization

## Consumers

Frontend Application:
- Uses /api/auth/signup
- Uses /api/auth/login

Backend Services:
- Uses OAuth2 Client Credentials flow
- Requests tokens from /oauth2/token

## High-Level Dependencies

- Database (User storage)
- Spring Authorization Server
- JWT (Nimbus)
- API Gateway / Ingress
