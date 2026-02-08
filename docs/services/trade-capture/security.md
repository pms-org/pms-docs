---
sidebar_position: 6
title: Security
---

# Trade Capture Service — Security Model

## Authentication

This service does not implement internal authentication.
Security is enforced at the API Gateway layer for admin endpoints.

## Authorization

- **Admin Endpoints**: Require appropriate admin role
- **Stream Access**: No authentication (internal network)
- **Database**: Connection-level authentication via credentials
- **Message Sources**: Trusted internal RabbitMQ streams

## Data Protection

- **Message Encryption**: Protobuf messages (binary format)
- **Database**: SSL/TLS connections recommended
- **Audit Trail**: All messages logged with validation status
- **DLQ Security**: Sensitive data in dead letter queue

## Network Security

- **Internal Access**: Runs in private network segments
- **Stream Security**: RabbitMQ authentication for producers
- **Kafka Security**: SASL/SSL for production deployments
- **API Access**: Protected by API Gateway authentication

## Data Validation

- **Protobuf Schema**: Strict schema validation on ingress
- **Business Rules**: Portfolio ID and trade data validation
- **Poison Pill Detection**: Automatic classification of invalid messages
- **Safe Storage**: Invalid messages stored securely for analysis

## CORS

Not applicable - internal service with no direct browser access.

## CSRF

Not applicable - REST API with no session state.

## Security Considerations

1. **Message Integrity**: Protobuf schema validation prevents malformed data
2. **Audit Trail**: Complete history of all processed messages
3. **Failure Isolation**: Invalid messages don't compromise valid processing
4. **Access Control**: Admin endpoints protected at gateway level
5. **Data Encryption**: Database connections should use SSL/TLS
