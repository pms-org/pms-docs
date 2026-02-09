---
sidebar_position: 4
title: WebSocket Integration
---

# Frontend WebSocket Integration

This guide explains how the PMS Frontend handles real-time WebSocket connections for live data updates across Analytics, Leaderboard, and RTTM services.

## WebSocket Architecture Overview

### Multi-Protocol Implementation

The application uses different WebSocket protocols for different services:

| Service         | Protocol          | Library         | Purpose                              |
| --------------- | ----------------- | --------------- | ------------------------------------ |
| **Analytics**   | STOMP over SockJS | @stomp/rx-stomp | Portfolio positions, P&L updates     |
| **Leaderboard** | Native WebSocket  | WebSocket API   | Ranking updates, performance metrics |
| **RTTM**        | Native WebSocket  | WebSocket API   | System monitoring, alerts            |

### Connection Management

**Key Features:**

- **Auto-reconnection**: 5-second retry intervals
- **Heartbeat monitoring**: 10-second keepalive signals
- **Connection status tracking**: Real-time connection state
- **Graceful degradation**: Fallback to polling when WebSocket fails
- **Error handling**: Comprehensive error recovery

## Analytics WebSocket (STOMP)

### Service Architecture

**Location:** `src/app/core/services/analytics-stomp.service.ts`

```typescript
@Injectable({ providedIn: "root" })
export class AnalyticsStompService {
  private client?: Client;

  // Connection status tracking
  private readonly connectedSubject = new BehaviorSubject<boolean>(false);
  readonly connected$ = this.connectedSubject.asObservable();

  // Data streams
  private readonly positionUpdateSubject =
    new BehaviorSubject<AnalysisEntityDto | null>(null);
  readonly positionUpdate$: Observable<AnalysisEntityDto | null> =
    this.positionUpdateSubject.asObservable();

  private readonly unrealisedSubject =
    new BehaviorSubject<UnrealisedPnlWsDto | null>(null);
  readonly unrealised$: Observable<UnrealisedPnlWsDto | null> =
    this.unrealisedSubject.asObservable();
}
```

### Connection Establishment

```typescript
connect(): void {
  if (this.connectedSubject.value) return;

  const sockJsUrl = this.runtimeConfig.analytics.baseWs;

  this.client = new Client({
    webSocketFactory: () => new SockJS(sockJsUrl),
    reconnectDelay: 5000,
    heartbeatIncoming: 10000,
    heartbeatOutgoing: 10000,
    debug: (str) => console.log('[STOMP]', str),
  });

  this.client.onConnect = () => {
    console.log('✅ STOMP Connected');
    this.connectedSubject.next(true);
    this.subscribeToTopics();
  };

  this.client.onWebSocketClose = () => {
    console.warn('⚠️ WebSocket Closed');
    this.connectedSubject.next(false);
  };

  this.client.activate();
}
```

### Topic Subscriptions

**Subscribed Topics:**
| Topic | Purpose | Data Type | Update Frequency |
|-------|---------|-----------|------------------|
| `/topic/position-update` | Portfolio position changes | `AnalysisEntityDto` | Real-time |
| `/topic/unrealized-pnl` | Live P&L calculations | `UnrealisedPnlWsDto[]` | Real-time |

```typescript
private subscribeToTopics(): void {
  // Position updates
  this.client?.subscribe('/topic/position-update', (msg: IMessage) => {
    try {
      const raw = JSON.parse(msg.body);
      if (Array.isArray(raw)) {
        raw.forEach(item => this.positionUpdateSubject.next(this.normalizePosition(item)));
      } else {
        this.positionUpdateSubject.next(this.normalizePosition(raw));
      }
    } catch (e) {
      console.error('Error parsing position update', e);
    }
  });

  // Unrealized P&L updates
  this.client?.subscribe('/topic/unrealized-pnl', (msg: IMessage) => {
    try {
      const raw = JSON.parse(msg.body);
      this.unrealisedSubject.next(this.normalizeUnrealised(raw));
    } catch (e) {
      console.error('Error parsing unrealized pnl', e);
    }
  });
}
```

### Data Normalization

**Position Data Normalization:**

```typescript
private normalizePosition(raw: any): AnalysisEntityDto {
  const portfolioId = raw?.id?.portfolioId ?? raw?.portfolioId ?? raw?.portfolio_id ?? '';
  const symbol = raw?.id?.symbol ?? raw?.symbol ?? '';

  return {
    id: { portfolioId, symbol },
    holdings: Number(raw?.holdings ?? 0),
    totalInvested: Number(raw?.totalInvested ?? raw?.total_invested ?? 0),
    realizedPnl: Number(raw?.realizedPnl ?? raw?.realisedPnl ?? raw?.realized_pnl ?? 0),
    createdAt: raw?.createdAt,
    updatedAt: raw?.updatedAt,
  };
}
```

**Unrealized P&L Normalization:**

```typescript
private normalizeUnrealised(raw: any): UnrealisedPnlWsDto {
  return {
    symbol: raw?.symbol ?? {},
    overallUnrealised_Pnl: Number(raw?.overallUnrealised_Pnl ?? raw?.overallUnrealisedPnl ?? 0),
    portfolio_id: raw?.portfolio_id ?? raw?.portfolioId ?? '',
  };
}
```

### Connection Lifecycle

**Disconnect Method:**

```typescript
disconnect(): void {
  this.client?.deactivate();
  this.connectedSubject.next(false);
  this.positionUpdateSubject.next(null);
  this.unrealisedSubject.next(null);
}
```

## Leaderboard WebSocket

### Service Implementation

**Location:** `src/app/core/services/leaderboard-ws.service.ts`

```typescript
@Injectable({ providedIn: "root" })
export class LeaderboardWsService {
  private ws?: WebSocket;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 5000;

  // Connection status
  private readonly connectedSubject = new BehaviorSubject<boolean>(false);
  readonly connected$ = this.connectedSubject.asObservable();

  // Data streams
  private readonly snapshotsSubject =
    new BehaviorSubject<LeaderboardSnapshot | null>(null);
  readonly snapshots$ = this.snapshotsSubject.asObservable();

  private readonly topPerformersSubject = new BehaviorSubject<
    LeaderboardEntry[] | null
  >(null);
  readonly topPerformers$ = this.topPerformersSubject.asObservable();
}
```

### Connection Management

```typescript
connect(): void {
  if (this.connectedSubject.value) return;

  const wsUrl = `${this.runtimeConfig.leaderboard.baseWs}/ws/updates`;

  try {
    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = () => {
      console.log('✅ Leaderboard WS Connected');
      this.connectedSubject.next(true);
      this.reconnectAttempts = 0;
    };

    this.ws.onmessage = (event) => {
      this.handleMessage(event.data);
    };

    this.ws.onclose = () => {
      console.warn('⚠️ Leaderboard WS Disconnected');
      this.connectedSubject.next(false);
      this.attemptReconnect();
    };

    this.ws.onerror = (error) => {
      console.error('❌ Leaderboard WS Error:', error);
    };

  } catch (error) {
    console.error('Failed to create WebSocket connection:', error);
    this.attemptReconnect();
  }
}
```

### Message Handling

```typescript
private handleMessage(data: string): void {
  try {
    const message = JSON.parse(data);

    switch (message.type) {
      case 'snapshot':
        this.snapshotsSubject.next(message.data as LeaderboardSnapshot);
        break;
      case 'top-performers':
        this.topPerformersSubject.next(message.data as LeaderboardEntry[]);
        break;
      case 'update':
        this.handleIncrementalUpdate(message.data);
        break;
      default:
        console.warn('Unknown message type:', message.type);
    }
  } catch (error) {
    console.error('Error parsing WebSocket message:', error);
  }
}
```

### Reconnection Logic

```typescript
private attemptReconnect(): void {
  if (this.reconnectAttempts >= this.maxReconnectAttempts) {
    console.error('Max reconnection attempts reached');
    return;
  }

  this.reconnectAttempts++;
  console.log(`Attempting reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts}`);

  setTimeout(() => {
    this.connect();
  }, this.reconnectDelay);
}
```

### WebSocket Endpoints

| Endpoint      | Purpose                        | Data Type             | Update Frequency |
| ------------- | ------------------------------ | --------------------- | ---------------- |
| `/ws/updates` | Complete leaderboard snapshots | `LeaderboardSnapshot` | Every 30 seconds |
| `/ws/top`     | Top performer updates          | `LeaderboardEntry[]`  | Real-time        |
| `/ws/around`  | Around portfolio rankings      | `LeaderboardEntry[]`  | Real-time        |

## RTTM WebSocket Services

### Multiple RTTM WebSocket Services

The RTTM service uses multiple specialized WebSocket connections:

1. **RTTM Alerts Service** - System alerts and notifications
2. **RTTM Metrics Service** - Performance metrics
3. **RTTM Pipeline Service** - Data pipeline monitoring
4. **RTTM Telemetry Service** - System telemetry data
5. **RTTM DLQ Service** - Dead letter queue monitoring

### Base RTTM WebSocket Service

**Location:** `src/app/core/services/rttm-ws-alerts.service.ts`

```typescript
@Injectable({ providedIn: "root" })
export class RttmWsAlertsService {
  private ws?: WebSocket;
  private readonly connectedSubject = new BehaviorSubject<boolean>(false);
  readonly connected$ = this.connectedSubject.asObservable();

  private readonly alertsSubject = new BehaviorSubject<Alert[] | null>(null);
  readonly alerts$ = this.alertsSubject.asObservable();

  connect(): void {
    const wsUrl = `${this.runtimeConfig.rttm.baseWs}/ws/alerts`;

    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = () => {
      console.log("✅ RTTM Alerts WS Connected");
      this.connectedSubject.next(true);
    };

    this.ws.onmessage = (event) => {
      const alerts = JSON.parse(event.data) as Alert[];
      this.alertsSubject.next(alerts);
    };

    this.ws.onclose = () => {
      console.warn("⚠️ RTTM Alerts WS Disconnected");
      this.connectedSubject.next(false);
    };
  }

  disconnect(): void {
    this.ws?.close();
    this.connectedSubject.next(false);
  }
}
```

### Data Models

**Alert Model:**

```typescript
interface Alert {
  id: string;
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW";
  message: string;
  timestamp: string;
  source: string;
  resolved: boolean;
}
```

**Metrics Model:**

```typescript
interface SystemMetrics {
  timestamp: string;
  cpu: {
    usage: number;
    cores: number;
  };
  memory: {
    used: number;
    total: number;
    percentage: number;
  };
  disk: {
    used: number;
    total: number;
    percentage: number;
  };
  network: {
    bytesIn: number;
    bytesOut: number;
  };
}
```

## Connection Status Service

### Centralized Connection Monitoring

**Location:** `src/app/core/services/connection-status.service.ts`

```typescript
@Injectable({ providedIn: "root" })
export class ConnectionStatusService {
  // Individual service connections
  readonly analyticsConnected$ = this.analyticsWs.connected$;
  readonly leaderboardConnected$ = this.leaderboardWs.connected$;
  readonly rttmConnected$ = this.rttmWs.connected$;

  // Overall connection status
  readonly allConnected$ = combineLatest([
    this.analyticsConnected$,
    this.leaderboardConnected$,
    this.rttmConnected$,
  ]).pipe(
    map((connections) => connections.every((connected) => connected)),
    distinctUntilChanged(),
  );

  constructor(
    private analyticsWs: AnalyticsStompService,
    private leaderboardWs: LeaderboardWsService,
    private rttmWs: RttmWsAlertsService,
  ) {}

  connectAll(): void {
    this.analyticsWs.connect();
    this.leaderboardWs.connect();
    this.rttmWs.connect();
  }

  disconnectAll(): void {
    this.analyticsWs.disconnect();
    this.leaderboardWs.disconnect();
    this.rttmWs.disconnect();
  }
}
```

## Error Handling and Recovery

### WebSocket Error Scenarios

**Connection Failures:**

```typescript
private handleConnectionError(error: Event): void {
  console.error('WebSocket connection error:', error);

  // Attempt reconnection with exponential backoff
  const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
  setTimeout(() => this.attemptReconnect(), delay);
}
```

**Message Parsing Errors:**

```typescript
private safeParseMessage(data: string): void {
  try {
    const message = JSON.parse(data);
    this.processMessage(message);
  } catch (error) {
    console.error('Failed to parse WebSocket message:', error);
    // Continue processing other messages
  }
}
```

**Network Interruptions:**

```typescript
// Automatic reconnection on network recovery
window.addEventListener("online", () => {
  console.log("Network connection restored, reconnecting WebSocket...");
  this.connect();
});
```

## Performance Optimization

### Message Batching

**Analytics Service Batching:**

```typescript
private batchUpdates: AnalysisEntityDto[] = [];
private batchTimeout?: number;

private addToBatch(update: AnalysisEntityDto): void {
  this.batchUpdates.push(update);

  if (this.batchTimeout) {
    clearTimeout(this.batchTimeout);
  }

  this.batchTimeout = window.setTimeout(() => {
    this.positionUpdateSubject.next(this.batchUpdates);
    this.batchUpdates = [];
  }, 100); // Batch updates within 100ms
}
```

### Connection Pooling

**Multiple Connection Management:**

```typescript
private connectionPool: WebSocket[] = [];
private activeConnectionIndex = 0;

private getNextConnection(): WebSocket {
  this.activeConnectionIndex = (this.activeConnectionIndex + 1) % this.connectionPool.length;
  return this.connectionPool[this.activeConnectionIndex];
}
```

## Testing WebSocket Connections

### Unit Testing

**WebSocket Service Testing:**

```typescript
describe("AnalyticsStompService", () => {
  let service: AnalyticsStompService;
  let mockClient: jasmine.SpyObj<Client>;

  beforeEach(() => {
    mockClient = jasmine.createSpyObj("Client", [
      "activate",
      "deactivate",
      "subscribe",
    ]);

    TestBed.configureTestingModule({
      providers: [AnalyticsStompService],
    });

    service = TestBed.inject(AnalyticsStompService);
  });

  it("should connect successfully", (done) => {
    service.connected$.subscribe((connected) => {
      if (connected) {
        expect(connected).toBeTrue();
        done();
      }
    });

    service.connect();
    mockClient.onConnect();
  });
});
```

### Integration Testing

**End-to-End WebSocket Testing:**

```typescript
describe("WebSocket Integration", () => {
  let testServer: WebSocket.Server;

  beforeEach(() => {
    // Start test WebSocket server
    testServer = new WebSocket.Server({ port: 8081 });
  });

  afterEach(() => {
    testServer.close();
  });

  it("should receive real-time updates", (done) => {
    testServer.on("connection", (ws) => {
      ws.send(JSON.stringify({ type: "position-update", data: mockPosition }));
    });

    service.connect();

    service.positionUpdate$.subscribe((update) => {
      expect(update).toEqual(mockPosition);
      done();
    });
  });
});
```

## Configuration

### Environment Configuration

**Development Environment:**

```typescript
// environment.ts
export const environment = {
  analytics: {
    baseWs: "http://localhost:8086", // SockJS endpoint
  },
  leaderboard: {
    baseWs: "ws://localhost:8000", // Native WebSocket
  },
  rttm: {
    baseWs: "ws://localhost:8087", // Native WebSocket
  },
};
```

**Production Environment:**

```typescript
// environment.prod.ts
export const environment = {
  analytics: {
    baseWs: "wss://analytics.yourdomain.com",
  },
  leaderboard: {
    baseWs: "wss://leaderboard.yourdomain.com",
  },
  rttm: {
    baseWs: "wss://rttm.yourdomain.com",
  },
};
```

### Runtime Configuration

**Dynamic WebSocket URLs:**

```typescript
// RuntimeConfigService
get analytics(): { baseHttp: string; baseWs: string } {
  const envJs = (window as any).__ENV__;
  return {
    baseHttp: envJs?.ANALYTICS_HTTP || 'http://localhost:8080',
    baseWs: envJs?.ANALYTICS_WS || 'ws://localhost:8086',
  };
}
```

## Troubleshooting

### Common WebSocket Issues

**1. Connection Refused**

```typescript
// Check WebSocket URL
console.log('Attempting connection to:', wsUrl);

// Verify server is running
curl -I http://localhost:8086
```

**2. CORS Issues**

```typescript
// Check server CORS configuration
// For SockJS, ensure allowed origins include frontend domain
const corsConfig = {
  origin: ["http://localhost:4200", "https://yourdomain.com"],
  methods: ["GET", "POST"],
  allowedHeaders: ["Content-Type"],
};
```

**3. Protocol Mismatch**

```typescript
// Ensure protocol matches environment
const isSecure = window.location.protocol === "https:";
const protocol = isSecure ? "wss:" : "ws:";

// For STOMP over SockJS, use http/https
const stompProtocol = isSecure ? "https:" : "http:";
```

**4. Message Format Issues**

```typescript
// Debug incoming messages
this.ws.onmessage = (event) => {
  console.log("Raw message:", event.data);
  try {
    const parsed = JSON.parse(event.data);
    console.log("Parsed message:", parsed);
  } catch (e) {
    console.error("Failed to parse:", e);
  }
};
```

**5. Connection Drops**

```typescript
// Monitor connection stability
let connectionCount = 0;
this.ws.onopen = () => {
  connectionCount++;
  console.log(`Connection #${connectionCount} established`);
};

// Check network conditions
navigator.onLine; // Browser online status
```

### Debug Tools

**Browser Developer Tools:**

```javascript
// Monitor WebSocket frames
// Network tab -> WS connection -> Frames

// Check console for connection logs
console.log("WebSocket state:", ws.readyState);
// 0 = CONNECTING, 1 = OPEN, 2 = CLOSING, 3 = CLOSED
```

**WebSocket Testing Tools:**

```bash
# Test WebSocket connection
wscat -c ws://localhost:8086

# Test STOMP connection
stomp -H localhost -P 8086
```

## Security Considerations

### WebSocket Security

**Secure Protocols:**

```typescript
// Production: Always use WSS
const wsUrl = "wss://secure-endpoint.com/ws";

// Development: Use WS for localhost
const wsUrl = "ws://localhost:8086/ws";
```

**Authentication:**

```typescript
// Include auth token in WebSocket URL or headers
const wsUrl = `wss://endpoint.com/ws?token=${authToken}`;

// Or send auth message after connection
ws.onopen = () => {
  ws.send(JSON.stringify({ type: "auth", token: authToken }));
};
```

**Origin Validation:**

```typescript
// Server-side origin checking
const allowedOrigins = ["https://yourdomain.com", "http://localhost:4200"];

if (!allowedOrigins.includes(origin)) {
  ws.close(1008, "Origin not allowed");
}
```

## Performance Monitoring

### WebSocket Metrics

**Connection Metrics:**

```typescript
interface WebSocketMetrics {
  connectionAttempts: number;
  successfulConnections: number;
  failedConnections: number;
  averageConnectionTime: number;
  messageCount: number;
  errorCount: number;
  reconnectCount: number;
}
```

**Message Throughput:**

```typescript
private messageMetrics = {
  received: 0,
  processed: 0,
  errors: 0,
  averageProcessingTime: 0,
};

private trackMessageMetrics(startTime: number): void {
  const processingTime = Date.now() - startTime;
  this.messageMetrics.processed++;
  this.messageMetrics.averageProcessingTime =
    (this.messageMetrics.averageProcessingTime + processingTime) / 2;
}
```

## Future Enhancements

### Planned Improvements

**Connection Pooling:**

```typescript
// Multiple connections for high-throughput scenarios
@Injectable({ providedIn: "root" })
export class WebSocketPoolService {
  private connections: WebSocket[] = [];

  createConnection(url: string): WebSocket {
    const ws = new WebSocket(url);
    this.connections.push(ws);
    return ws;
  }

  getBalancedConnection(): WebSocket {
    // Round-robin load balancing
    return this.connections[this.index++ % this.connections.length];
  }
}
```

**Message Compression:**

```typescript
// Enable WebSocket compression
const ws = new WebSocket(url, [], {
  compress: true,
  compressionOptions: {
    threshold: 1024, // Compress messages > 1KB
  },
});
```

**Binary Message Support:**

```typescript
// Support for binary WebSocket messages
ws.binaryType = "arraybuffer";

ws.onmessage = (event) => {
  if (event.data instanceof ArrayBuffer) {
    // Handle binary data
    this.processBinaryMessage(event.data);
  } else {
    // Handle text data
    this.processTextMessage(event.data);
  }
};
```

## Deployment Checklist

### Development Setup

- [ ] WebSocket endpoints configured in environment files
- [ ] Proxy configuration includes WebSocket routes
- [ ] CORS settings allow WebSocket connections
- [ ] Development servers running on correct ports

### Production Deployment

- [ ] WSS protocol enforced for all WebSocket connections
- [ ] SSL certificates configured for WebSocket endpoints
- [ ] Load balancer WebSocket support enabled
- [ ] Connection limits configured appropriately

### Monitoring Setup

- [ ] WebSocket connection metrics collected
- [ ] Error logging and alerting configured
- [ ] Performance monitoring enabled
- [ ] Connection pool sizing appropriate for load

### Security Validation

- [ ] Origin validation working correctly
- [ ] Authentication tokens validated
- [ ] Secure protocols (WSS) enforced
- [ ] Rate limiting configured for WebSocket endpoints
