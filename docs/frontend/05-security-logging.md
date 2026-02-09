# 🔐 Security & Logging Guide

## Overview
This guide covers the security measures, logging strategies, and monitoring capabilities implemented in the PMS Frontend application to ensure data protection, audit compliance, and operational visibility.

## 🛡️ Security Architecture

### Multi-Layer Security Approach
```
Network Security (HTTPS/WSS, Firewalls)
    ↓
Application Security (Authentication, Authorization)
    ↓
Data Security (Encryption, Validation)
    ↓
Infrastructure Security (Container, Kubernetes)
```

## 🔒 Authentication & Authorization

### Current Implementation
The application currently operates in a **trusted environment** mode, suitable for internal enterprise deployments behind corporate firewalls.

### Future Authentication Strategy
```typescript
// Planned JWT implementation
interface AuthService {
  login(credentials: LoginCredentials): Observable<AuthToken>;
  logout(): void;
  refreshToken(): Observable<AuthToken>;
  isAuthenticated(): boolean;
}

interface AuthToken {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  tokenType: 'Bearer';
}
```

### Authorization Levels
| Role | Dashboard | Leaderboard | RTTM | Admin |
|------|-----------|-------------|------|-------|
| **Viewer** | ✅ Read | ✅ Read | ❌ | ❌ |
| **Analyst** | ✅ Full | ✅ Full | ✅ Read | ❌ |
| **Manager** | ✅ Full | ✅ Full | ✅ Full | ❌ |
| **Admin** | ✅ Full | ✅ Full | ✅ Full | ✅ Full |

## 🌐 Network Security

### HTTPS/WSS Enforcement
```typescript
// Production environment configuration
export const environment = {
  production: true,
  analytics: {
    baseHttp: 'https://analytics.yourdomain.com',  // HTTPS only
    baseWs: 'wss://analytics.yourdomain.com',      // WSS only
  },
  // ... other services with secure protocols
};
```

### Security Headers
Nginx configuration includes security headers:
```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;
```

### CORS Configuration
Development proxy handles CORS securely:
```json
{
  "/api/*": {
    "target": "https://backend.yourdomain.com",
    "secure": true,
    "changeOrigin": true,
    "headers": {
      "Origin": "https://frontend.yourdomain.com"
    }
  }
}
```

## 🔐 Data Security

### Input Validation
```typescript
// HTTP interceptor for request validation
@Injectable()
export class SecurityInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Sanitize request data
    const sanitizedReq = this.sanitizeRequest(req);
    
    // Add security headers
    const secureReq = sanitizedReq.clone({
      setHeaders: {
        'X-Requested-With': 'XMLHttpRequest',
        'Cache-Control': 'no-cache',
      }
    });
    
    return next.handle(secureReq);
  }
}
```

### Data Sanitization
```typescript
// XSS prevention
export class SecurityUtils {
  static sanitizeHtml(input: string): string {
    return input
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;');
  }
  
  static validatePortfolioId(id: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(id);
  }
}
```

### Sensitive Data Handling
```typescript
// No sensitive data in localStorage/sessionStorage
// Use memory-only storage for tokens
class SecureStorage {
  private static tokenStore = new Map<string, string>();
  
  static setToken(key: string, token: string): void {
    this.tokenStore.set(key, token);
  }
  
  static getToken(key: string): string | undefined {
    return this.tokenStore.get(key);
  }
  
  static clearTokens(): void {
    this.tokenStore.clear();
  }
}
```

## 📊 Logging Architecture

### Centralized Logging Service
```typescript
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  CRITICAL = 4
}

@Injectable({ providedIn: 'root' })
export class LoggerService {
  private readonly logLevel = environment.production ? LogLevel.INFO : LogLevel.DEBUG;
  
  debug(message: string, data?: any): void {
    if (this.logLevel <= LogLevel.DEBUG) {
      console.debug(`[DEBUG] ${new Date().toISOString()} - ${message}`, data);
      this.sendToLogServer('DEBUG', message, data);
    }
  }
  
  info(message: string, data?: any): void {
    if (this.logLevel <= LogLevel.INFO) {
      console.info(`[INFO] ${new Date().toISOString()} - ${message}`, data);
      this.sendToLogServer('INFO', message, data);
    }
  }
  
  error(message: string, error?: any): void {
    console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error);
    this.sendToLogServer('ERROR', message, error);
  }
}
```

### Structured Logging
```typescript
interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  userId?: string;
  sessionId: string;
  component: string;
  action?: string;
  data?: any;
  error?: {
    name: string;
    message: string;
    stack: string;
  };
}

// Usage example
this.logger.info('Portfolio analysis requested', {
  portfolioId: 'uuid-123',
  userId: 'user-456',
  component: 'AnalyticsService',
  action: 'getPortfolioSectorAnalysis'
});
```

## 🔍 Security Monitoring

### Security Event Logging
```typescript
@Injectable({ providedIn: 'root' })
export class SecurityLogger {
  private readonly logger = inject(LoggerService);
  
  logAuthenticationAttempt(success: boolean, userId?: string): void {
    this.logger.info('Authentication attempt', {
      success,
      userId,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      ipAddress: this.getClientIP()
    });
  }
  
  logUnauthorizedAccess(resource: string, userId?: string): void {
    this.logger.warn('Unauthorized access attempt', {
      resource,
      userId,
      timestamp: new Date().toISOString(),
      severity: 'HIGH'
    });
  }
  
  logDataAccess(resource: string, action: string, userId?: string): void {
    this.logger.info('Data access', {
      resource,
      action,
      userId,
      timestamp: new Date().toISOString()
    });
  }
}
```

### Audit Trail
```typescript
interface AuditEvent {
  eventId: string;
  timestamp: string;
  userId: string;
  action: string;
  resource: string;
  oldValue?: any;
  newValue?: any;
  success: boolean;
  ipAddress: string;
  userAgent: string;
}

// Audit logging for critical operations
@Injectable({ providedIn: 'root' })
export class AuditService {
  logPortfolioAccess(portfolioId: string, action: string): void {
    const auditEvent: AuditEvent = {
      eventId: this.generateEventId(),
      timestamp: new Date().toISOString(),
      userId: this.getCurrentUserId(),
      action,
      resource: `portfolio:${portfolioId}`,
      success: true,
      ipAddress: this.getClientIP(),
      userAgent: navigator.userAgent
    };
    
    this.sendAuditEvent(auditEvent);
  }
}
```

## 🚨 Error Handling & Monitoring

### Global Error Handler
```typescript
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  private readonly logger = inject(LoggerService);
  
  handleError(error: any): void {
    // Log error details
    this.logger.error('Unhandled error occurred', {
      name: error.name,
      message: error.message,
      stack: error.stack,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      userAgent: navigator.userAgent
    });
    
    // Send to monitoring service
    this.sendToMonitoringService(error);
    
    // Show user-friendly message
    this.showUserNotification('An unexpected error occurred. Please try again.');
  }
}
```

### HTTP Error Interceptor
```typescript
@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  private readonly logger = inject(LoggerService);
  
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        // Log HTTP errors
        this.logger.error('HTTP Error', {
          status: error.status,
          statusText: error.statusText,
          url: error.url,
          message: error.message,
          timestamp: new Date().toISOString()
        });
        
        // Handle specific error types
        switch (error.status) {
          case 401:
            this.handleUnauthorized();
            break;
          case 403:
            this.handleForbidden();
            break;
          case 500:
            this.handleServerError();
            break;
        }
        
        return throwError(() => error);
      })
    );
  }
}
```

## 📈 Performance Monitoring

### Performance Metrics
```typescript
@Injectable({ providedIn: 'root' })
export class PerformanceMonitor {
  private readonly logger = inject(LoggerService);
  
  measureApiCall<T>(apiCall: Observable<T>, endpoint: string): Observable<T> {
    const startTime = performance.now();
    
    return apiCall.pipe(
      tap(() => {
        const duration = performance.now() - startTime;
        this.logger.info('API call completed', {
          endpoint,
          duration: `${duration.toFixed(2)}ms`,
          timestamp: new Date().toISOString()
        });
        
        // Alert on slow responses
        if (duration > 5000) {
          this.logger.warn('Slow API response detected', {
            endpoint,
            duration: `${duration.toFixed(2)}ms`
          });
        }
      })
    );
  }
  
  measureComponentLoad(componentName: string): void {
    const loadTime = performance.now();
    this.logger.debug('Component loaded', {
      component: componentName,
      loadTime: `${loadTime.toFixed(2)}ms`
    });
  }
}
```

### WebSocket Connection Monitoring
```typescript
@Injectable({ providedIn: 'root' })
export class WebSocketMonitor {
  private readonly logger = inject(LoggerService);
  
  monitorConnection(serviceName: string, ws: WebSocket): void {
    const connectionStart = Date.now();
    
    ws.addEventListener('open', () => {
      const connectionTime = Date.now() - connectionStart;
      this.logger.info('WebSocket connected', {
        service: serviceName,
        connectionTime: `${connectionTime}ms`,
        timestamp: new Date().toISOString()
      });
    });
    
    ws.addEventListener('error', (error) => {
      this.logger.error('WebSocket error', {
        service: serviceName,
        error: error.type,
        timestamp: new Date().toISOString()
      });
    });
    
    ws.addEventListener('close', (event) => {
      this.logger.warn('WebSocket disconnected', {
        service: serviceName,
        code: event.code,
        reason: event.reason,
        timestamp: new Date().toISOString()
      });
    });
  }
}
```

## 🐳 Container Security

### Dockerfile Security Best Practices
```dockerfile
# Use specific version tags
FROM node:18.19.0-alpine AS build

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S angular -u 1001

# Set working directory
WORKDIR /app

# Copy package files first (layer caching)
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY --chown=angular:nodejs . .

# Build application
RUN npm run build -- --configuration=production

# Production stage
FROM nginx:1.25.3-alpine
COPY --from=build /app/dist/pms-frontend /usr/share/nginx/html

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user for nginx
RUN addgroup -g 1001 -S nginx-group
RUN adduser -S nginx-user -u 1001 -G nginx-group

# Set ownership
RUN chown -R nginx-user:nginx-group /usr/share/nginx/html
RUN chown -R nginx-user:nginx-group /var/cache/nginx

# Switch to non-root user
USER nginx-user

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

### Kubernetes Security
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pms-frontend
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: pms-frontend
        image: pms-frontend:latest
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
```

## 🔧 Security Configuration

### Content Security Policy
```typescript
// CSP configuration for production
const cspDirectives = {
  'default-src': ["'self'"],
  'script-src': ["'self'", "'unsafe-inline'"],
  'style-src': ["'self'", "'unsafe-inline'"],
  'img-src': ["'self'", "data:", "https:"],
  'connect-src': ["'self'", "wss:", "https:"],
  'font-src': ["'self'"],
  'object-src': ["'none'"],
  'media-src': ["'self'"],
  'frame-src': ["'none'"]
};
```

### Environment-Specific Security
```typescript
// Development - relaxed security for debugging
const developmentSecurity = {
  enableDebugLogging: true,
  allowHttpConnections: true,
  corsEnabled: true,
  csrfProtection: false
};

// Production - strict security
const productionSecurity = {
  enableDebugLogging: false,
  allowHttpConnections: false,
  corsEnabled: false,
  csrfProtection: true,
  hsts: true,
  secureHeaders: true
};
```

## 📊 Compliance & Reporting

### Regulatory Compliance
- **GDPR**: Data protection and privacy controls
- **SOX**: Financial data integrity and audit trails
- **PCI DSS**: Payment card data security (if applicable)
- **ISO 27001**: Information security management

### Audit Reports
```typescript
interface SecurityReport {
  reportId: string;
  generatedAt: string;
  period: { start: string; end: string };
  metrics: {
    authenticationAttempts: number;
    failedLogins: number;
    unauthorizedAccess: number;
    dataAccess: number;
    errors: number;
  };
  incidents: SecurityIncident[];
  recommendations: string[];
}
```

## 🚀 Security Best Practices

### Development
- Regular dependency updates
- Security linting and scanning
- Code review for security issues
- Secure coding guidelines

### Deployment
- HTTPS/WSS enforcement
- Security headers configuration
- Container security scanning
- Kubernetes security policies

### Operations
- Regular security assessments
- Incident response procedures
- Security monitoring and alerting
- Backup and recovery procedures

### Monitoring
- Real-time security event monitoring
- Automated threat detection
- Performance and availability monitoring
- Compliance reporting and auditing