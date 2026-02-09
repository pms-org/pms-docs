# 🔌 WebSocket Handling Guide

## Overview
This guide explains how the PMS Frontend handles real-time WebSocket connections for live data updates across Analytics, Leaderboard, and RTTM services.

## 🏗️ WebSocket Architecture

### Connection Strategy
```
Frontend
├── Analytics WS    → STOMP over SockJS
├── Leaderboard WS  → Native WebSocket
└── RTTM WS        → Native WebSocket
```

### Service Responsibilities
- **Analytics**: Real-time portfolio positions and PnL updates
- **Leaderboard**: Live ranking updates and performance metrics
- **RTTM**: System monitoring, alerts, and telemetry data

## 📊 Analytics WebSocket (STOMP)

### Implementation
Uses STOMP protocol over SockJS for reliable messaging:

```typescript
@Injectable({ providedIn: 'root' })
export class AnalyticsStompService {
  private client?: Client;
  private readonly connectedSubject = new BehaviorSubject<boolean>(false);
  
  connect(): void {
    this.client = new Client({
      webSocketFactory: () => new SockJS(ENDPOINTS.analytics.wsEndpoint),
      reconnectDelay: 5000,
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
    });
  }
}
```

### Subscribed Topics
| Topic | Purpose | Data Type | Frequency |
|-------|---------|-----------|-----------|
| `/topic/position-update` | Portfolio position changes | `AnalysisEntityDto` | Real-time |
| `/topic/unrealized-pnl` | Live PnL calculations | `UnrealisedPnlWsDto[]` | Real-time |

### Data Normalization
Handles different backend data formats:
```typescript
private normalizePosition(raw: any): AnalysisEntityDto {
  const portfolioId = raw?.id?.portfolioId ?? raw?.portfolioId ?? raw?.portfolio_id ?? '';
  const symbol = raw?.id?.symbol ?? raw?.symbol ?? '';
  return {
    id: { portfolioId, symbol },
    holdings: Number(raw?.holdings ?? 0),
    totalInvested: Number(raw?.totalInvested ?? raw?.total_invested ?? 0),
    realizedPnl: Number(raw?.realizedPnl ?? raw?.realisedPnl ?? raw?.realized_pnl ?? 0),
  };
}
```

### Features:
- **Auto-reconnection**: 5-second retry interval
- **Heartbeat monitoring**: 10-second intervals
- **Error handling**: Graceful degradation
- **Data validation**: Type-safe normalization

## 🏆 Leaderboard WebSocket

### Implementation
Native WebSocket for leaderboard updates:

```typescript
@Injectable({ providedIn: 'root' })
export class LeaderboardWsService {
  private ws?: WebSocket;
  private readonly snapshotsSubject = new BehaviorSubject<LeaderboardSnapshot | null>(null);
  
  connect(): void {
    const wsUrl = wsUrl(ENDPOINTS.leaderboard.baseWs, ENDPOINTS.leaderboard.wsSnapshots);
    this.ws = new WebSocket(wsUrl);
    
    this.ws.onmessage = (event) => {
      const snapshot: LeaderboardSnapshot = JSON.parse(event.data);
      this.snapshotsSubject.next(snapshot);
    };
  }
}
```

### WebSocket Endpoints
| Endpoint | Purpose | Data Type | Update Frequency |
|----------|---------|-----------|------------------|
| `/ws/updates` | Complete leaderboard snapshots | `LeaderboardSnapshot` | Every 30 seconds |
| `/ws/leaderboard/top` | Top performer updates | `LeaderboardEntry[]` | Real-time |
| `/ws/leaderboard/around` | Around portfolio rankings | `LeaderboardEntry[]` | Real-time |

### Data Models
```typescript
interface LeaderboardSnapshot {
  generatedAt: string;        // ISO timestamp
  entries: LeaderboardEntry[]; // Complete rankings
}

interface LeaderboardEntry {
  portfolioId: string;
  portfolioName: string;
  pnl: number;
  rank: number;
}
```

## 📈 RTTM WebSocket Services

### Multiple WebSocket Connections
RTTM uses separate WebSocket connections for different data streams:

#### 1. Metrics WebSocket
```typescript
@Injectable({ providedIn: 'root' })
export class RttmWsMetricsService {
  private ws?: WebSocket;
  private readonly metricsSubject = new BehaviorSubject<MetricCard[]>([]);
  
  connect(): void {
    const wsUrl = wsUrl(ENDPOINTS.rttm.baseWs, ENDPOINTS.rttm.wsMetrics);
    this.ws = new WebSocket(wsUrl);
  }
}
```

#### 2. Pipeline WebSocket
```typescript
@Injectable({ providedIn: 'root' })
export class RttmWsPipelineService {
  private readonly pipelineSubject = new BehaviorSubject<PipelineStage[]>([]);
  // Similar implementation for pipeline updates
}
```

#### 3. Alerts WebSocket
```typescript
@Injectable({ providedIn: 'root' })
export class RttmWsAlertsService {
  private readonly alertsSubject = new BehaviorSubject<Alert[]>([]);
  // Real-time system alerts
}
```

### RTTM WebSocket Endpoints
| Service | Endpoint | Purpose | Data Type |
|---------|----------|---------|-----------|
| Metrics | `/ws/rttm/metrics` | System performance metrics | `MetricCard[]` |
| Pipeline | `/ws/rttm/pipeline` | Processing pipeline status | `PipelineStage[]` |
| Telemetry | `/ws/rttm/telemetry` | System telemetry data | `Alert[]` |
| DLQ | `/ws/rttm/dlq` | Dead letter queue updates | `DLQResponse[]` |
| Alerts | `/ws/rttm/alerts` | Critical system alerts | `Alert[]` |

## 🔄 Connection Management

### Connection Status Service
Centralized connection state management:

```typescript
export type ConnectionStatus = 'disconnected' | 'api' | 'websocket';

@Injectable({ providedIn: 'root' })
export class ConnectionStatusService {
  private _status = signal<ConnectionStatus>('disconnected');
  
  status = this._status.asReadonly();

  setWebSocketConnected() {
    this._status.set('websocket');
  }

  setDisconnected() {
    this._status.set('disconnected');
  }
}
```

### Connection Lifecycle
1. **Initial Connection**: Attempt WebSocket connection on service initialization
2. **Connection Monitoring**: Track connection status with heartbeats
3. **Auto-Reconnection**: Retry failed connections with exponential backoff
4. **Graceful Degradation**: Fall back to HTTP polling if WebSocket fails

## 🛡️ Error Handling & Resilience

### Connection Error Handling
```typescript
this.ws.onerror = (error) => {
  this.logger.error('WebSocket error', error);
  this.connectionStatus.setDisconnected();
};

this.ws.onclose = (event) => {
  this.logger.warn('WebSocket closed', { code: event.code, reason: event.reason });
  this.scheduleReconnect();
};
```

### Reconnection Strategy
```typescript
private scheduleReconnect(): void {
  if (this.reconnectAttempts < this.maxReconnectAttempts) {
    const delay = Math.pow(2, this.reconnectAttempts) * 1000; // Exponential backoff
    setTimeout(() => this.connect(), delay);
    this.reconnectAttempts++;
  }
}
```

### Features:
- **Exponential backoff**: Prevents server overload
- **Maximum retry limit**: Avoids infinite reconnection loops
- **Connection state tracking**: UI feedback for connection status
- **Error logging**: Detailed error information for debugging

## 🔧 Development Configuration

### Proxy WebSocket Support
Development proxy handles WebSocket connections:

```json
{
  "/ws": {
    "target": "ws://18.118.149.115:8082",
    "secure": false,
    "changeOrigin": true,
    "ws": true,
    "logLevel": "debug",
    "timeout": 60000,
    "proxyTimeout": 60000
  },
  "/ws/updates": {
    "target": "ws://localhost:8000",
    "ws": true,
    "secure": false,
    "changeOrigin": true
  }
}
```

### Key Configuration:
- **`ws: true`**: Enables WebSocket proxying
- **`timeout`**: Connection timeout settings
- **`logLevel: "debug"`**: Detailed logging for development

## 🌐 Environment-Specific Handling

### Development
- Mixed protocols: Some services remote, others local
- Proxy handles CORS and protocol differences
- Debug logging enabled

### Production
- All WebSocket connections use WSS (secure)
- Direct connections to backend services
- Connection pooling and load balancing

### Kubernetes
- Internal service discovery
- Service mesh integration
- Health checks and monitoring

## 📊 Data Flow Architecture

### Real-time Data Pipeline
```
Backend Services
    ↓ (WebSocket)
Frontend Services
    ↓ (RxJS Observables)
Component State
    ↓ (Angular Signals)
UI Components
```

### State Management
```typescript
// Service layer
readonly positionUpdate$ = this.positionUpdateSubject.asObservable();

// Component layer
private readonly analyticsService = inject(AnalyticsStompService);

ngOnInit() {
  this.analyticsService.positionUpdate$.subscribe(update => {
    if (update) {
      this.updatePortfolioData(update);
    }
  });
}
```

## 🔍 Monitoring & Debugging

### WebSocket Debugging
```typescript
// Enable debug logging
debug: (str: string) => this.logger.debug('[STOMP]', str),

// Connection status monitoring
this.client.onConnect = () => {
  this.logger.info('STOMP Connected');
  this.connectedSubject.next(true);
};
```

### Browser DevTools
- **Network tab**: Monitor WebSocket connections
- **Console**: View connection logs and errors
- **Application tab**: Inspect WebSocket frames

### Health Checks
```typescript
// Periodic connection health check
private healthCheck(): void {
  if (this.ws?.readyState === WebSocket.OPEN) {
    this.ws.send(JSON.stringify({ type: 'ping' }));
  }
}
```

## 🚀 Performance Optimization

### Connection Pooling
- Reuse WebSocket connections across components
- Lazy connection initialization
- Connection cleanup on component destroy

### Data Throttling
```typescript
// Throttle high-frequency updates
this.positionUpdate$.pipe(
  throttleTime(100), // Max 10 updates per second
  distinctUntilChanged()
).subscribe(update => {
  this.updateUI(update);
});
```

### Memory Management
```typescript
ngOnDestroy() {
  this.analyticsService.disconnect();
  this.subscriptions.forEach(sub => sub.unsubscribe());
}
```

## 🔧 Troubleshooting

### Common Issues:

1. **Connection Refused**
   - Check backend service availability
   - Verify WebSocket endpoint URLs
   - Confirm proxy configuration

2. **CORS Errors**
   - Ensure `changeOrigin: true` in proxy
   - Check backend CORS settings
   - Verify protocol matching (ws/wss)

3. **Message Parsing Errors**
   - Validate JSON format from backend
   - Check data normalization logic
   - Handle null/undefined values

4. **Memory Leaks**
   - Unsubscribe from observables
   - Close WebSocket connections
   - Clear intervals and timeouts

### Debug Commands:
```bash
# Enable WebSocket debugging
ng serve --proxy-config proxy.conf.json --verbose

# Monitor WebSocket traffic
# Use browser DevTools Network tab
# Filter by WS (WebSocket) connections
```

### Health Check Endpoints:
- Analytics: Check STOMP connection status
- Leaderboard: Monitor WebSocket readyState
- RTTM: Verify all service connections