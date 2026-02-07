# Failure Modes

## Login Failure (401)

Causes:
- Wrong credentials
- User not found

Debug:
- Check logs
- Verify database data

## OAuth Token Failure

Causes:
- Invalid client credentials
- Incorrect grant type

Debug:
- Verify Authorization header

## JWT Validation Errors

Causes:
- Multiple pods with different RSA keys

Debug:
- Check JWKS endpoint
- Reduce replicas

## Startup Failure

Causes:
- Database unreachable
- Environment variables missing

Debug:
- Inspect pod logs
