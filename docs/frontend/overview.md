---
sidebar_position: 1
title: Frontend Overview
---

# Frontend Overview

The PMS Frontend is a modern Angular-based single-page application (SPA) that provides real-time portfolio management dashboards, analytics, and system monitoring capabilities for financial institutions.

## Architecture Overview

### Technology Stack

| Component      | Technology        | Version       | Purpose                       |
| -------------- | ----------------- | ------------- | ----------------------------- |
| **Framework**  | Angular           | 21.0.0        | Component-based UI framework  |
| **Language**   | TypeScript        | 5.9.2         | Type-safe JavaScript          |
| **Styling**    | Tailwind CSS      | 4.1.12        | Utility-first CSS framework   |
| **Charts**     | Chart.js          | 4.5.1         | Data visualization library    |
| **WebSocket**  | STOMP.js + SockJS | 7.2.1 + 1.6.1 | Real-time communication       |
| **Build Tool** | Angular CLI       | 21.0.3        | Development and build tooling |
| **PDF Export** | jsPDF             | 2.5.2         | Report generation             |

### Application Structure

```
src/
├── app/
│   ├── core/                    # Core services and configuration
│   │   ├── config/             # Runtime configuration
│   │   ├── guards/             # Route protection
│   │   ├── interceptors/       # HTTP interceptors
│   │   ├── services/           # Core business services
│   │   └── state/              # State management
│   ├── features/               # Feature modules
│   │   ├── dashboard/          # Portfolio analytics
│   │   ├── leaderboard/         # Performance rankings
│   │   ├── login/              # Authentication
│   │   ├── portfolio/          # Portfolio management
│   │   ├── rttm/               # Real-time monitoring
│   │   ├── shell/              # Application shell
│   │   └── signup/             # User registration
│   └── shared/                 # Shared components and utilities
├── environments/               # Environment configurations
└── styles.css                  # Global styles
```

## Core Features

### 1. Portfolio Analytics Dashboard

**Real-time Portfolio Monitoring**

- Live position updates via WebSocket
- Sector allocation analysis
- Realized/Unrealized P&L tracking
- Portfolio value history charts
- Risk metrics and exposure analysis

**Key Components:**

- Interactive portfolio holdings table
- Real-time P&L indicators
- Sector diversification charts
- Historical performance graphs

### 2. Leaderboard & Performance Ranking

**Competitive Analysis**

- Portfolio performance rankings
- Peer comparison metrics
- Sharpe and Sortino ratio analysis
- Composite scoring system

**Real-time Updates:**

- Live ranking position changes
- Performance metric updates
- New portfolio entries

### 3. Real-Time Transaction Monitoring (RTTM)

**System Health Monitoring**

- Service availability status
- Performance metrics dashboard
- Alert management system
- Pipeline monitoring
- Dead letter queue management

**Operational Features:**

- System telemetry data
- Error rate monitoring
- Throughput metrics
- Latency tracking

## Authentication & Security

### Current Implementation

- **Token-based Authentication**: JWT tokens stored in localStorage
- **Route Guards**: Automatic redirection for unauthenticated users
- **HTTP Interceptors**: Automatic token attachment to API requests
- **Trusted Environment**: Designed for internal enterprise deployments

### Security Features

- HTTPS/WSS enforcement in production
- Security headers (XSS protection, CSRF prevention)
- Input validation and sanitization
- CORS configuration for secure API communication

## WebSocket Architecture

### Multi-Protocol Implementation

| Service         | Protocol          | Library         | Purpose                              |
| --------------- | ----------------- | --------------- | ------------------------------------ |
| **Analytics**   | STOMP over SockJS | @stomp/rx-stomp | Portfolio updates, P&L data          |
| **Leaderboard** | Native WebSocket  | WebSocket API   | Ranking updates, performance metrics |
| **RTTM**        | Native WebSocket  | WebSocket API   | System monitoring, alerts            |

### Connection Management

- **Auto-reconnection**: 5-second retry intervals
- **Heartbeat Monitoring**: 10-second keepalive signals
- **Connection Status**: Real-time connection state tracking
- **Graceful Degradation**: Fallback to polling when WebSocket fails

## Configuration Management

### Environment-Based Configuration

**Development Environment:**

```typescript
analytics: {
  baseHttp: 'http://localhost:8080',
  baseWs: 'http://localhost:8086',
}
```

**Production Environment:**

```typescript
analytics: {
  baseHttp: 'https://analytics.yourdomain.com',
  baseWs: 'wss://analytics.yourdomain.com',
}
```

**Kubernetes Environment:**

```typescript
analytics: {
  baseHttp: 'http://analytics-service:8082',
  baseWs: 'ws://analytics-service:8082',
}
```

### Runtime Configuration

- **Dynamic Endpoints**: Configurable via `env.js` file
- **Service Discovery**: Automatic backend service location
- **Environment Overrides**: Runtime configuration overrides

## Build and Deployment

### Build Configurations

| Configuration   | Command                               | Environment           | Optimization               |
| --------------- | ------------------------------------- | --------------------- | -------------------------- |
| **Development** | `ng serve`                            | Local development     | Hot reload, source maps    |
| **Production**  | `ng build --configuration=production` | Production deployment | Minification, tree-shaking |
| **Kubernetes**  | `ng build --configuration=k8s`        | Container deployment  | Service discovery URLs     |

### Containerization

- **Multi-stage Docker builds** for optimized images
- **Nginx serving** for static file delivery
- **Environment-specific configurations** for different deployments

## Performance Characteristics

### Bundle Analysis

- **Lazy Loading**: Feature modules loaded on-demand
- **Tree Shaking**: Unused code elimination
- **Code Splitting**: Optimized chunk sizes
- **Asset Optimization**: Image and font optimization

### Runtime Performance

- **Change Detection**: OnPush strategy for optimal performance
- **Memory Management**: Efficient subscription handling
- **WebSocket Optimization**: Connection pooling and message batching

## Development Workflow

### Local Development

```bash
# Install dependencies
npm install

# Start development server
ng serve

# Run tests
ng test

# Build for production
ng build --configuration=production
```

### Code Quality

- **TypeScript**: Strict type checking enabled
- **ESLint**: Code quality and style enforcement
- **Prettier**: Automatic code formatting
- **Unit Tests**: Comprehensive test coverage

## Browser Support

| Browser | Version | Support Level |
| ------- | ------- | ------------- |
| Chrome  | 90+     | Full support  |
| Firefox | 88+     | Full support  |
| Safari  | 14+     | Full support  |
| Edge    | 90+     | Full support  |

## Monitoring and Observability

### Application Metrics

- **Performance Monitoring**: Page load times, API response times
- **Error Tracking**: JavaScript errors, failed API calls
- **User Analytics**: Feature usage, navigation patterns
- **WebSocket Health**: Connection status, message throughput

### Logging Strategy

- **Structured Logging**: Consistent log format across components
- **Error Boundaries**: Graceful error handling and reporting
- **Debug Information**: Development mode detailed logging
- **Production Optimization**: Minimal logging in production builds

## Future Enhancements

### Planned Features

- **Advanced Authentication**: OAuth2/OpenID Connect integration
- **Role-Based Access Control**: Granular permission system
- **Offline Support**: Service worker implementation
- **Progressive Web App**: Mobile app capabilities
- **Advanced Analytics**: Machine learning insights
- **Multi-tenancy**: Organization-based data isolation

### Technical Improvements

- **State Management**: NgRx for complex state handling
- **Component Library**: Design system standardization
- **Testing Infrastructure**: E2E testing with Cypress
- **Performance Monitoring**: Real user monitoring (RUM)
- **Accessibility**: WCAG 2.1 AA compliance
