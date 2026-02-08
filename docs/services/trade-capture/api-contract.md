---
sidebar_position: 3
title: API Contract
---

# Trade Capture Service — API Contract

## Base Path

/admin/replay

## Endpoints

### POST /admin/replay/hex

Injects a hex-encoded trade message into the processing pipeline for testing and replay purposes.

**Authentication**
Handled at Gateway layer (admin access required).

**Request Body**

```
<string> - Hex-encoded protobuf trade message
```

**Response**

Success (200):

```
"Replay injected into buffer."
```

Error (400):

```
"Invalid Hex"
```

**Example Request**

```bash
curl -X POST "http://localhost:8082/admin/replay/hex" \
  -H "Content-Type: text/plain" \
  -d "0a05636f696e31120a706f7274666f6c696f312807"
```

**Notes**

- This endpoint bypasses RabbitMQ streaming
- Messages are injected directly into the batching buffer
- Primarily used for testing and manual replay scenarios
- No authentication validation on the message content itself
