---
sidebar_position: 3
title: API Contract
---

# Auth Service — API Contract

## Base Path

/api/auth

## Endpoints

### POST /api/auth/signup
Registers a new user.

Authentication: Not required

### POST /api/auth/login
Authenticates user and returns JWT.

Authentication: Not required

## OAuth2 Endpoints

POST /oauth2/token
Grant Type Supported: client_credentials

Authentication: HTTP Basic

## Discovery Endpoints

/.well-known/openid-configuration
/oauth2/jwks

## Actuator

/actuator/**
