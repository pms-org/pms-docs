# 🔧 Configuration Guide

## Overview
This guide explains how to configure the PMS Frontend application for different environments and deployment scenarios.

## Environment Configuration

### 📁 Environment Files
The application uses three environment configurations:

```
src/environments/
├── environment.ts          # Development (default)
├── environment.prod.ts     # Production
└── environment.k8s.ts      # Kubernetes
```

### 🛠️ Environment Structure
Each environment file contains service endpoints:

```typescript
export const environment = {
  production: boolean,
  analytics: {
    baseHttp: string,    // REST API base URL
    baseWs: string,      // WebSocket base URL
  },
  leaderboard: {
    baseHttp: string,
    baseWs: string,
  },
  rttm: {
    baseHttp: string,
    baseWs: string,
  },
};
```

## 🚀 Build Configurations

### Development
```bash
ng serve
# Uses: environment.ts
# Features: Hot reload, source maps, no optimization
```

### Production
```bash
ng build --configuration=production
# Uses: environment.prod.ts
# Features: Minification, tree-shaking, HTTPS/WSS
```

### Kubernetes
```bash
ng build --configuration=k8s
# Uses: environment.k8s.ts
# Features: Service discovery, internal cluster URLs
```

## 🌐 Service Endpoints

### Current Setup
- **Analytics**: Remote server (`18.118.149.115:8082`)
- **Leaderboard**: Local development (`localhost:8000`)
- **RTTM**: Local development (`localhost:8085`)

### Production Setup
Update `environment.prod.ts` with your domains:
```typescript
analytics: {
  baseHttp: 'https://analytics.yourdomain.com',
  baseWs: 'wss://analytics.yourdomain.com',
},
```

### Kubernetes Setup
Uses internal service names:
```typescript
analytics: {
  baseHttp: 'http://analytics-service:8082',
  baseWs: 'ws://analytics-service:8082',
},
```

## 🔄 Proxy Configuration

### Development Proxy (`proxy.conf.json`)
Routes API calls to backend services during development:

```json
{
  "/api/analytics": {
    "target": "http://18.118.149.115:8082",
    "secure": false,
    "changeOrigin": true
  },
  "/ws": {
    "target": "ws://18.118.149.115:8082",
    "ws": true,
    "secure": false
  }
}
```

### Key Features:
- **CORS handling**: `changeOrigin: true`
- **WebSocket support**: `ws: true`
- **Debug logging**: `logLevel: "debug"`
- **Timeout handling**: For WebSocket connections

## 🐳 Docker Configuration

### Dockerfile
Multi-stage build for production:
```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration=k8s

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist/pms-frontend /usr/share/nginx/html
```

### Nginx Configuration
- Serves static files
- Proxies API calls to backend
- Handles WebSocket upgrades
- SPA routing support

## ☸️ Kubernetes Deployment

### Resources Included:
- **Deployment**: 2 replicas with resource limits
- **Service**: ClusterIP for internal communication
- **Ingress**: External access with domain routing

### Commands:
```bash
# Build image
docker build -t pms-frontend .

# Deploy to cluster
kubectl apply -f k8s-deployment.yaml
```

## 🔐 Security Considerations

### Development
- HTTP/WS protocols for local testing
- CORS enabled for cross-origin requests

### Production
- HTTPS/WSS protocols mandatory
- SSL certificates required on backend
- Secure headers in Nginx

### Kubernetes
- Internal service communication
- Network policies recommended
- Secret management for sensitive data

## 🎯 Quick Setup

### 1. Local Development
```bash
npm install
ng serve
# Access: http://localhost:4200
```

### 2. Production Build
```bash
# Update environment.prod.ts with your domains
ng build --configuration=production
# Deploy dist/ folder to web server
```

### 3. Kubernetes Deployment
```bash
# Update k8s-deployment.yaml with your image registry
docker build -t your-registry/pms-frontend .
docker push your-registry/pms-frontend
kubectl apply -f k8s-deployment.yaml
```

## 🔍 Troubleshooting

### Common Issues:
1. **WebSocket Connection Errors**: Check backend service availability
2. **CORS Issues**: Verify proxy configuration
3. **Build Failures**: Ensure environment files exist
4. **404 Errors**: Check Nginx SPA routing configuration

### Debug Commands:
```bash
# Check build configuration
ng build --configuration=production --verbose

# Test proxy configuration
ng serve --proxy-config proxy.conf.json

# Validate environment
ng build --configuration=k8s --dry-run
```