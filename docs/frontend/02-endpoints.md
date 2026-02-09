# 🌐 Endpoint Handling Guide

## Overview
This guide explains how the PMS Frontend handles API endpoints, routing, and service communication across different backend services.

## 🏗️ Architecture

### Service Architecture
```
Frontend (Angular)
├── Analytics Service    → Portfolio analysis, sectors, PnL
├── Leaderboard Service  → Rankings, performance metrics
└── RTTM Service        → Real-time monitoring, alerts
```

### Endpoint Configuration
All endpoints are centrally managed in `src/app/core/config/endpoints.ts`:

```typescript
export const ENDPOINTS = {
  analytics: {
    baseHttp: environment.analytics.baseHttp,
    baseWs: environment.analytics.baseWs,
    // REST endpoints
    analysisAll: '/api/analysis/all',
    sectorOverall: '/api/sectors/overall',
    // WebSocket topics
    topicPositions: '/topic/position-update',
    topicUnrealised: '/topic/unrealized-pnl',
  },
  // ... other services
};
```

## 📊 Analytics Service Endpoints

### REST API Endpoints
| Endpoint | Method | Purpose | Response |
|----------|--------|---------|----------|
| `/api/analysis/all` | GET | All portfolio analysis | `AnalysisEntityDto[]` |
| `/api/sectors/overall` | GET | Overall sector breakdown | `SectorMetricsDto[]` |
| `/api/analytics/initial-unrealized-pnl` | GET | Trigger PnL calculation | `void` |
| `/api/sectors/portfolio-wise/{id}` | GET | Portfolio sector analysis | `SectorMetricsDto[]` |
| `/api/analytics/sectors/{sector}/drilldown` | GET | Sector symbol breakdown | `SymbolMetricsDto[]` |
| `/api/portfolio_value/history/{id}` | GET | Portfolio value history | `PortfolioValueHistoryDto[]` |

### WebSocket Topics
| Topic | Purpose | Data Type |
|-------|---------|-----------|
| `/topic/position-update` | Real-time position updates | `AnalysisEntityDto` |
| `/topic/unrealized-pnl` | Live PnL updates | `UnrealisedPnlWsDto` |

### Data Models
```typescript
interface AnalysisEntityDto {
  id: { portfolioId: string; symbol: string };
  holdings: number;
  totalInvested: number;
  realizedPnl: number;
}

interface SectorMetricsDto {
  sector: string;
  percentage: number;
  totalHoldings?: number;
  totalInvested?: number;
  realizedPnl?: number;
}
```

## 🏆 Leaderboard Service Endpoints

### REST API Endpoints
| Endpoint | Method | Purpose | Response |
|----------|--------|---------|----------|
| `/api/leaderboard/portfolios` | GET | All portfolios | `Portfolio[]` |
| `/api/leaderboard/top` | GET | Top performers | `LeaderboardEntry[]` |
| `/api/leaderboard/around` | GET | Rankings around portfolio | `LeaderboardEntry[]` |

### WebSocket Endpoints
| Endpoint | Purpose | Data Type |
|----------|---------|-----------|
| `/ws/updates` | Leaderboard snapshots | `LeaderboardSnapshot` |
| `/ws/leaderboard/top` | Top performer updates | `LeaderboardEntry[]` |
| `/ws/leaderboard/around` | Around portfolio updates | `LeaderboardEntry[]` |

### Data Models
```typescript
interface Portfolio {
  rank: number;
  portfolioId: string;
  name?: string;
  compositeScore?: number;
  avgReturn?: number;
  sharpe?: string;
  sortino?: string;
}

interface LeaderboardSnapshot {
  generatedAt: string;
  entries: LeaderboardEntry[];
}
```

## 📈 RTTM Service Endpoints

### REST API Endpoints
| Endpoint | Method | Purpose | Response |
|----------|--------|---------|----------|
| `/api/rttm/metrics` | GET | System metrics | `MetricCard[]` |
| `/api/rttm/pipeline` | GET | Pipeline stages | `PipelineStage[]` |
| `/api/rttm/dlq` | GET | Dead letter queue data | `DLQResponse` |
| `/api/rttm/telemetry-snapshot` | GET | Telemetry snapshot | `TelemetrySnapshot` |

### WebSocket Endpoints
| Endpoint | Purpose | Data Type |
|----------|---------|-----------|
| `/ws/rttm/metrics` | Real-time metrics | `MetricCard[]` |
| `/ws/rttm/pipeline` | Pipeline updates | `PipelineStage[]` |
| `/ws/rttm/telemetry` | Telemetry alerts | `Alert[]` |
| `/ws/rttm/dlq` | DLQ updates | `DLQResponse[]` |
| `/ws/rttm/alerts` | System alerts | `Alert[]` |

### Data Models
```typescript
interface MetricCard {
  title: string;
  value: number | string;
  unit?: string;
  status: 'healthy' | 'warning' | 'critical';
}

interface PipelineStage {
  name: string;
  count: number;
  latencyMs: number;
  successRate: number;
}
```

## 🔧 Service Implementation

### HTTP Service Pattern
Each service follows a consistent pattern:

```typescript
@Injectable({ providedIn: 'root' })
export class AnalyticsApiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = ENDPOINTS.analytics.baseHttp;

  getAnalysisAll(): Observable<AnalysisEntityDto[]> {
    return this.http.get<AnalysisEntityDto[]>(
      httpUrl(this.baseUrl, ENDPOINTS.analytics.analysisAll)
    );
  }
}
```

### URL Helper Functions
```typescript
export const httpUrl = (base: string, path: string) => `${base}${path}`;
export const wsUrl = (base: string, path: string) => `${base}${path}`;
```

## 🔄 Proxy Configuration

### Development Routing
The proxy configuration routes requests during development:

```json
{
  "/api/analytics": {
    "target": "http://18.118.149.115:8082",
    "secure": false,
    "changeOrigin": true
  },
  "/api/leaderboard": {
    "target": "http://localhost:8000",
    "secure": false,
    "changeOrigin": true
  }
}
```

### Benefits:
- **CORS handling**: Eliminates cross-origin issues
- **Environment consistency**: Same URLs across environments
- **Development flexibility**: Easy backend switching

## 🌍 Environment-Based Routing

### Development
- Analytics: Remote server (`18.118.149.115:8082`)
- Leaderboard: Local (`localhost:8000`)
- RTTM: Local (`localhost:8085`)

### Production
- All services use HTTPS/WSS
- Domain-based routing
- Load balancer integration

### Kubernetes
- Service discovery via DNS
- Internal cluster communication
- No external dependencies

## 🔍 Error Handling

### HTTP Interceptor
```typescript
@Injectable()
export class ErrorRetryInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(req).pipe(
      retry(3),
      catchError(this.handleError)
    );
  }
}
```

### Features:
- **Automatic retry**: 3 attempts for failed requests
- **Error logging**: Centralized error tracking
- **User feedback**: Toast notifications for errors

## 📊 Monitoring & Logging

### Request Logging
```typescript
private readonly logger = inject(LoggerService);

getPortfolioSectorAnalysis(portfolioId: string): Observable<SectorMetricsDto[]> {
  const url = httpUrl(this.baseUrl, ENDPOINTS.analytics.portfolioSector(portfolioId));
  this.logger.info('API Call: Portfolio sector analysis', { portfolioId, url });
  return this.http.get<SectorMetricsDto[]>(url);
}
```

### Connection Status
```typescript
@Injectable({ providedIn: 'root' })
export class ConnectionStatusService {
  private _status = signal<ConnectionStatus>('disconnected');
  
  setApiConnected() { /* ... */ }
  setWebSocketConnected() { /* ... */ }
  setDisconnected() { /* ... */ }
}
```

## 🚀 Best Practices

### 1. Centralized Configuration
- All endpoints in one file
- Environment-based URLs
- Type-safe endpoint functions

### 2. Consistent Service Pattern
- Injectable services
- Observable-based APIs
- Error handling

### 3. Development Efficiency
- Proxy configuration
- Hot reload support
- Debug logging

### 4. Production Readiness
- HTTPS/WSS protocols
- Error retry logic
- Connection monitoring

## 🔧 Troubleshooting

### Common Issues:
1. **404 Errors**: Check endpoint paths and proxy config
2. **CORS Issues**: Verify `changeOrigin: true` in proxy
3. **Connection Refused**: Ensure backend services are running
4. **WebSocket Failures**: Check WebSocket proxy configuration

### Debug Tips:
```bash
# Enable proxy debugging
ng serve --proxy-config proxy.conf.json --verbose

# Check network requests in browser DevTools
# Monitor WebSocket connections in Network tab
```