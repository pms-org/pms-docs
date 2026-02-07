# Configuration

## Server

Default Spring Boot port configuration applies.

## Database

Configured via environment variables:

DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD

## Behavior

If database is unreachable, service will fail to start.

Duplicate phone numbers will be rejected at application and DB level.
