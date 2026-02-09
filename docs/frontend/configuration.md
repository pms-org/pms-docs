---
sidebar_position: 2
title: Configuration
---

# Frontend Configuration

This guide explains how to configure the PMS Frontend application for different environments and deployment scenarios.

## Environment Configuration

### Environment Files Structure

The application uses multiple environment configurations located in `src/environments/`:

```
src/environments/
├── environment.ts           # Development (default)
├── environment.prod.ts      # Production deployment
├── environment.k8s.ts       # Kubernetes deployment
├── environment.eks.ts       # AWS EKS deployment
└── environment.docker.ts    # Docker deployment
```

### Environment File Format

Each environment file exports a configuration object:

```typescript
export const environment = {
  production: boolean,
  analytics: {
    baseHttp: string, // REST API base URL
    baseWs: string, // WebSocket base URL
  },
  leaderboard: {
    baseHttp: string,
    baseWs: string,
  },
  rttm: {
    baseHttp: string,
    baseWs: string,
  },
  portfolio: {
    baseHttp: string,
  },
  auth: {
    baseHttp: string,
  },
};
```

## Build Configurations

### Development Build

**Command:**

```bash
ng serve
```

**Configuration:**

- Uses: `environment.ts`
- Features: Hot reload, source maps, development optimizations
- Proxy: `proxy.conf.json` for API routing

### Production Build

**Command:**

```bash
ng build --configuration=production
```

**Configuration:**

- Uses: `environment.prod.ts`
- Features: AOT compilation, minification, tree-shaking
- Output: Optimized bundles in `dist/` directory

### Kubernetes Build

**Command:**

```bash
ng build --configuration=k8s
```

**Configuration:**

- Uses: `environment.k8s.ts`
- Features: Internal service discovery URLs
- Networking: Service-to-service communication

### Docker Build

**Command:**

```bash
ng build --configuration=docker
```

**Configuration:**

- Uses: `environment.docker.ts`
- Features: Container-optimized settings
- Networking: Docker network service discovery

## Runtime Configuration

### Dynamic Configuration Loading

The application supports runtime configuration overrides via `env.js`:

```javascript
// public/env.js
window.__ENV__ = {
  API_GATEWAY_HTTP: "https://api.yourdomain.com",
  API_GATEWAY_WS: "wss://api.yourdomain.com",
  AUTH_HTTP: "https://auth.yourdomain.com",
  ANALYTICS_HTTP: "https://analytics.yourdomain.com",
  ANALYTICS_WS: "wss://analytics.yourdomain.com",
  LEADERBOARD_HTTP: "https://leaderboard.yourdomain.com",
  LEADERBOARD_WS: "wss://leaderboard.yourdomain.com",
  RTTM_HTTP: "https://rttm.yourdomain.com",
  RTTM_WS: "wss://rttm.yourdomain.com",
  PORTFOLIO_HTTP: "https://portfolio.yourdomain.com",
};
```

### RuntimeConfigService

The `RuntimeConfigService` transforms flat `env.js` configuration into nested structure:

```typescript
@Injectable({ providedIn: "root" })
export class RuntimeConfigService {
  private config: RuntimeConfig;

  constructor() {
    const envJs = (window as any).__ENV__ as EnvJsConfig | undefined;
    this.config = envJs
      ? this.transformEnvJsConfig(envJs)
      : this.getDefaultConfig();
  }

  get analytics(): { baseHttp: string; baseWs: string } {
    return this.config.analytics;
  }
  // ... other service getters
}
```

## Service Endpoints Configuration

### Development Environment

```typescript
// environment.ts
export const environment = {
  production: false,
  analytics: {
    baseHttp: "http://localhost:8080",
    baseWs: "http://localhost:8086",
  },
  leaderboard: {
    baseHttp: "http://localhost:8080",
    baseWs: "ws://localhost:8000",
  },
  rttm: {
    baseHttp: "http://localhost:8082",
    baseWs: "ws://localhost:8087",
  },
  portfolio: {
    baseHttp: "http://localhost:8095",
  },
  auth: {
    baseHttp: "http://localhost:8085",
  },
};
```

### Production Environment

```typescript
// environment.prod.ts
export const environment = {
  production: true,
  analytics: {
    baseHttp: "https://analytics.yourdomain.com",
    baseWs: "wss://analytics.yourdomain.com",
  },
  leaderboard: {
    baseHttp: "https://leaderboard.yourdomain.com",
    baseWs: "wss://leaderboard.yourdomain.com",
  },
  rttm: {
    baseHttp: "https://rttm.yourdomain.com",
    baseWs: "wss://rttm.yourdomain.com",
  },
  portfolio: {
    baseHttp: "https://portfolio.yourdomain.com",
  },
  auth: {
    baseHttp: "https://auth.yourdomain.com",
  },
};
```

### Kubernetes Environment

```typescript
// environment.k8s.ts
export const environment = {
  production: true,
  analytics: {
    baseHttp: "http://analytics-service:8082",
    baseWs: "ws://analytics-service:8082",
  },
  leaderboard: {
    baseHttp: "http://leaderboard-service:8080",
    baseWs: "ws://leaderboard-service:8080",
  },
  rttm: {
    baseHttp: "http://rttm-service:8087",
    baseWs: "ws://rttm-service:8087",
  },
  portfolio: {
    baseHttp: "http://portfolio-service:8095",
  },
  auth: {
    baseHttp: "http://auth-service:8085",
  },
};
```

## Proxy Configuration

### Development Proxy Setup

**File:** `proxy.conf.json`

```json
{
  "/api/analytics": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  },
  "/api/leaderboard": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  },
  "/api/rttm": {
    "target": "http://localhost:8082",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  },
  "/api/portfolio": {
    "target": "http://localhost:8095",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  },
  "/api/auth": {
    "target": "http://localhost:8085",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  },
  "/ws": {
    "target": "ws://localhost:8086",
    "secure": false,
    "changeOrigin": true,
    "ws": true,
    "logLevel": "debug"
  }
}
```

### Production Proxy (Nginx)

**File:** `nginx.conf`

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # API proxy
    location /api/ {
        proxy_pass http://backend-service:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket proxy
    location /ws/ {
        proxy_pass http://analytics-service:8086;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location / {
        try_files $uri $uri/ /index.html;
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
```

## Docker Configuration

### Multi-stage Dockerfile

```dockerfile
# Build stage
FROM node:18-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build -- --configuration=docker

# Production stage
FROM nginx:alpine

# Copy built application
COPY --from=build /app/dist/pms-frontend /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy runtime configuration
COPY env.js /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Docker Compose Configuration

```yaml
version: "3.8"
services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "4200:80"
    environment:
      - API_GATEWAY_HTTP=http://api-gateway:8080
      - ANALYTICS_HTTP=http://analytics:8080
      - ANALYTICS_WS=ws://analytics:8086
    depends_on:
      - api-gateway
      - analytics
```

## Kubernetes Configuration

### Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pms-frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pms-frontend
  template:
    metadata:
      labels:
        app: pms-frontend
    spec:
      containers:
        - name: frontend
          image: your-registry/pms-frontend:latest
          ports:
            - containerPort: 80
          env:
            - name: API_GATEWAY_HTTP
              value: "http://api-gateway:8080"
            - name: ANALYTICS_HTTP
              value: "http://analytics-service:8082"
            - name: ANALYTICS_WS
              value: "ws://analytics-service:8082"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
```

### ConfigMap for Environment Variables

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  API_GATEWAY_HTTP: "http://api-gateway.pms.svc.cluster.local:8080"
  ANALYTICS_HTTP: "http://analytics.pms.svc.cluster.local:8082"
  ANALYTICS_WS: "ws://analytics.pms.svc.cluster.local:8082"
  LEADERBOARD_HTTP: "http://leaderboard.pms.svc.cluster.local:8080"
  LEADERBOARD_WS: "ws://leaderboard.pms.svc.cluster.local:8080"
  RTTM_HTTP: "http://rttm.pms.svc.cluster.local:8087"
  RTTM_WS: "ws://rttm.pms.svc.cluster.local:8087"
  PORTFOLIO_HTTP: "http://portfolio.pms.svc.cluster.local:8095"
  AUTH_HTTP: "http://auth.pms.svc.cluster.local:8085"
```

## Security Configuration

### HTTPS Configuration

**Production Environment Security:**

```typescript
// environment.prod.ts
export const environment = {
  production: true,
  // Force HTTPS/WSS protocols
  analytics: {
    baseHttp: "https://analytics.yourdomain.com",
    baseWs: "wss://analytics.yourdomain.com",
  },
  // ... other services
};
```

### Content Security Policy

**Nginx Configuration:**

```nginx
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; connect-src 'self' wss://analytics.yourdomain.com ws://localhost:* https://api.yourdomain.com;" always;
```

### CORS Configuration

**Development Proxy:**

```json
{
  "/api/*": {
    "target": "https://api.yourdomain.com",
    "secure": true,
    "changeOrigin": true,
    "headers": {
      "Origin": "https://frontend.yourdomain.com"
    }
  }
}
```

## Monitoring Configuration

### Application Monitoring

**Performance Monitoring:**

```typescript
// Performance tracking
@Injectable({ providedIn: "root" })
export class PerformanceService {
  trackApiCall(endpoint: string, duration: number): void {
    // Send metrics to monitoring service
  }

  trackWebSocketConnection(
    service: string,
    status: "connected" | "disconnected",
  ): void {
    // Track WebSocket health
  }
}
```

### Error Tracking

**Global Error Handler:**

```typescript
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  handleError(error: any): void {
    // Log errors to monitoring service
    console.error("Global error:", error);
    // Send to error tracking service
  }
}
```

## Troubleshooting Configuration Issues

### Common Configuration Problems

**1. WebSocket Connection Issues**

```typescript
// Check WebSocket URLs in environment files
console.log("Analytics WS URL:", this.runtimeConfig.analytics.baseWs);

// Verify protocol (ws vs wss)
const isSecure = window.location.protocol === "https:";
const expectedProtocol = isSecure ? "wss:" : "ws:";
```

**2. API Endpoint Mismatch**

```typescript
// Debug API calls
this.http.get("/api/analytics/health").subscribe({
  next: (response) => console.log("API reachable:", response),
  error: (error) => console.error("API error:", error),
});
```

**3. Runtime Configuration Loading**

```typescript
// Check if env.js is loaded
console.log("Runtime config:", window.__ENV__);

// Verify service URLs
console.log("Analytics HTTP:", this.runtimeConfig.analytics.baseHttp);
```

### Configuration Validation

**Startup Validation:**

```typescript
@Injectable({ providedIn: "root" })
export class ConfigValidatorService {
  validateConfiguration(): Observable<boolean> {
    // Test API connectivity
    // Validate WebSocket connections
    // Check required environment variables
    return this.testAllConnections();
  }
}
```

## Environment Variable Reference

| Variable           | Description                       | Default | Required |
| ------------------ | --------------------------------- | ------- | -------- |
| `API_GATEWAY_HTTP` | API Gateway HTTP URL              | -       | Yes      |
| `API_GATEWAY_WS`   | API Gateway WebSocket URL         | -       | No       |
| `AUTH_HTTP`        | Authentication service URL        | -       | Yes      |
| `ANALYTICS_HTTP`   | Analytics service HTTP URL        | -       | Yes      |
| `ANALYTICS_WS`     | Analytics service WebSocket URL   | -       | Yes      |
| `LEADERBOARD_HTTP` | Leaderboard service HTTP URL      | -       | Yes      |
| `LEADERBOARD_WS`   | Leaderboard service WebSocket URL | -       | Yes      |
| `RTTM_HTTP`        | RTTM service HTTP URL             | -       | Yes      |
| `RTTM_WS`          | RTTM service WebSocket URL        | -       | Yes      |
| `PORTFOLIO_HTTP`   | Portfolio service HTTP URL        | -       | Yes      |

## Deployment Checklist

### Pre-deployment Configuration

- [ ] Environment file matches target environment
- [ ] Runtime configuration (`env.js`) is properly configured
- [ ] API endpoints are accessible
- [ ] WebSocket endpoints are reachable
- [ ] SSL certificates are valid (production)
- [ ] CORS settings allow frontend domain

### Post-deployment Validation

- [ ] Application loads without console errors
- [ ] API calls succeed
- [ ] WebSocket connections establish
- [ ] Authentication flow works
- [ ] All features are functional
- [ ] Performance meets requirements
