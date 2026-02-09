# 📚 PMS Frontend Documentation

Welcome to the comprehensive documentation for the Portfolio Management System (PMS) Frontend application. This documentation provides detailed information about configuration, architecture, features, and best practices.

## 📖 Documentation Index

### 🔧 [Configuration Guide](./01-configuration.md)
Learn how to configure the application for different environments and deployment scenarios.

**Topics Covered:**
- Environment configuration (dev/prod/k8s)
- Build configurations and optimizations
- Service endpoint management
- Docker and Kubernetes deployment
- Proxy configuration for development
- Security considerations

### 🌐 [Endpoint Handling](./02-endpoints.md)
Understand how the application manages API endpoints and service communication.

**Topics Covered:**
- Service architecture overview
- REST API endpoint documentation
- HTTP service implementation patterns
- Environment-based routing
- Error handling and retry logic
- Request/response monitoring

### 🔌 [WebSocket Handling](./03-websockets.md)
Comprehensive guide to real-time WebSocket connections and data streaming.

**Topics Covered:**
- WebSocket architecture (STOMP, native WebSocket)
- Real-time data streams for Analytics, Leaderboard, and RTTM
- Connection management and auto-reconnection
- Error handling and resilience
- Performance optimization
- Development and debugging

### 🏢 [Business Overview](./04-business-overview.md)
Business perspective, value proposition, and strategic context of the application.

**Topics Covered:**
- Executive summary and business value
- Target user personas and use cases
- Key performance indicators (KPIs)
- Market context and competitive advantages
- ROI analysis and success metrics
- Future roadmap and strategic vision

### 🔐 [Security & Logging](./05-security-logging.md)
Security measures, logging strategies, and compliance considerations.

**Topics Covered:**
- Multi-layer security architecture
- Authentication and authorization
- Data security and encryption
- Audit trails and compliance
- Performance monitoring
- Container and Kubernetes security

### 🚀 [Features & Capabilities](./06-features-capabilities.md)
Complete overview of all application features, components, and technical capabilities.

**Topics Covered:**
- Core feature modules (Dashboard, Leaderboard, RTTM)
- Shared component library
- State management with Signals and RxJS
- UI/UX features and accessibility
- Data visualization and charts
- Performance optimization strategies

## 🏗️ Quick Start Guide

### Prerequisites
- Node.js 18+ and npm
- Angular CLI 21+
- Docker (for containerization)
- Kubernetes (for orchestration)

### Development Setup
```bash
# Clone the repository
git clone <repository-url>
cd pms-frontend

# Install dependencies
npm install

# Start development server
ng serve

# Access application
open http://localhost:4200
```

### Production Deployment
```bash
# Build for production
ng build --configuration=production

# Build Docker image
docker build -t pms-frontend .

# Deploy to Kubernetes
kubectl apply -f k8s-deployment.yaml
```

## 🎯 Key Features Overview

### 📊 Portfolio Analytics Dashboard
- Real-time portfolio monitoring with WebSocket updates
- Interactive sector allocation charts with drill-down capability
- Historical performance tracking and trend analysis
- Comprehensive PnL (Profit & Loss) calculations

### 🏆 Performance Leaderboard
- Live portfolio rankings and peer comparison
- Multi-metric sorting (Sharpe ratio, returns, volatility)
- Real-time updates via WebSocket connections
- Export capabilities for reporting

### 📈 Real-Time Monitoring (RTTM)
- System health dashboard with key metrics
- Processing pipeline monitoring and alerts
- Dead letter queue (DLQ) management
- Critical system notifications and incident tracking

## 🏗️ Architecture Highlights

### Modern Angular Architecture
- **Angular 21**: Latest framework features and performance
- **Standalone Components**: Modular and tree-shakable architecture
- **Signals**: Reactive state management with fine-grained updates
- **RxJS**: Powerful reactive programming for data streams

### Real-Time Capabilities
- **WebSocket Integration**: STOMP and native WebSocket support
- **Live Data Updates**: Real-time portfolio and system monitoring
- **Auto-Reconnection**: Resilient connection management
- **Performance Optimization**: Efficient data streaming and updates

### Production-Ready Features
- **Environment Management**: Separate configs for dev/prod/k8s
- **Security**: HTTPS/WSS, input validation, audit logging
- **Monitoring**: Comprehensive logging and performance tracking
- **Scalability**: Kubernetes-native deployment with resource management

## 🔧 Technology Stack

### Frontend Technologies
- **Angular 21.0.0**: Modern web framework
- **TypeScript**: Type-safe development
- **TailwindCSS 4.1.12**: Utility-first CSS framework
- **Chart.js 4.5.1**: Interactive data visualization
- **RxJS 7.8.0**: Reactive programming library

### Real-Time Communication
- **STOMP.js 7.2.1**: STOMP protocol for messaging
- **SockJS 1.6.1**: WebSocket fallback support
- **Native WebSocket**: Direct WebSocket connections

### Development & Testing
- **Vitest 4.0.8**: Fast unit testing framework
- **Angular CLI**: Development and build tools
- **ESLint**: Code quality and consistency
- **Prettier**: Code formatting

### Deployment & Infrastructure
- **Docker**: Containerization for consistent deployment
- **Kubernetes**: Container orchestration and scaling
- **Nginx**: Production web server and reverse proxy
- **Multi-stage Builds**: Optimized container images

## 📊 Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Analytics     │    │   Leaderboard   │    │      RTTM       │
│   Service       │    │    Service      │    │    Service      │
│                 │    │                 │    │                 │
│ • Portfolio     │    │ • Rankings      │    │ • Monitoring    │
│   Analysis      │    │ • Performance   │    │ • Alerts        │
│ • Sector Data   │    │ • Comparisons   │    │ • Metrics       │
│ • PnL Tracking  │    │ • Benchmarks    │    │ • Pipeline      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  PMS Frontend   │
                    │   (Angular)     │
                    │                 │
                    │ • Dashboard     │
                    │ • Leaderboard   │
                    │ • RTTM Monitor  │
                    │ • Real-time UI  │
                    └─────────────────┘
```

## 🎯 Getting Started

### For Developers
1. Read the [Configuration Guide](./01-configuration.md) for setup instructions
2. Review [Endpoint Handling](./02-endpoints.md) for API integration
3. Understand [WebSocket Handling](./03-websockets.md) for real-time features
4. Explore [Features & Capabilities](./06-features-capabilities.md) for implementation details

### For Business Stakeholders
1. Start with [Business Overview](./04-business-overview.md) for strategic context
2. Review [Features & Capabilities](./06-features-capabilities.md) for functionality overview
3. Check [Security & Logging](./05-security-logging.md) for compliance and risk management

### For System Administrators
1. Focus on [Configuration Guide](./01-configuration.md) for deployment
2. Review [Security & Logging](./05-security-logging.md) for operational requirements
3. Understand [WebSocket Handling](./03-websockets.md) for network configuration

## 🔍 Troubleshooting

### Common Issues
- **WebSocket Connection Errors**: Check backend service availability and proxy configuration
- **Build Failures**: Verify environment files exist and are properly configured
- **CORS Issues**: Ensure proxy configuration includes `changeOrigin: true`
- **Performance Issues**: Review WebSocket connection limits and data throttling

### Debug Resources
- Browser DevTools Network tab for API and WebSocket monitoring
- Angular DevTools for component inspection
- Application logs for detailed error information
- Health check endpoints for service status verification

## 📞 Support & Contributing

### Documentation Updates
This documentation is maintained alongside the codebase. When making changes to the application:
1. Update relevant documentation sections
2. Ensure examples match current implementation
3. Test all configuration examples
4. Update version numbers and dependencies

### Feedback
For questions, issues, or suggestions regarding this documentation:
- Create issues in the project repository
- Submit pull requests for improvements
- Contact the development team for clarification

---

**Last Updated**: January 2026  
**Version**: 1.0.0  
**Angular Version**: 21.0.0