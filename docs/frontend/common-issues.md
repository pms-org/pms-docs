---
sidebar_position: 5
title: Common Issues
---

# Frontend Common Issues

This guide covers common issues encountered in the PMS Frontend application, their causes, and solutions.

## Build and Development Issues

### Build Failures

**Issue: `ng build` fails with TypeScript errors**

**Symptoms:**

```
Error: src/app/features/dashboard/dashboard.page.ts:15:23 - error TS2307: Cannot find module '@angular/core'.
```

**Causes:**

- Missing node_modules
- Corrupted node_modules
- Package version conflicts

**Solutions:**

1. **Clean and reinstall dependencies:**

```bash
rm -rf node_modules package-lock.json
npm install
```

2. **Clear Angular cache:**

```bash
rm -rf .angular/cache
ng build
```

3. **Check TypeScript configuration:**

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "moduleResolution": "node",
    "baseUrl": "./",
    "paths": {
      "@app/*": ["src/app/*"],
      "@env/*": ["src/environments/*"]
    }
  }
}
```

**Issue: Build succeeds but application doesn't load**

**Symptoms:**

- Build completes successfully
- Browser shows blank page
- Console shows JavaScript errors

**Causes:**

- Missing polyfills
- Incorrect base href
- Asset loading issues

**Solutions:**

1. **Check index.html:**

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>PMS Frontend</title>
    <base href="/" />
    <!-- Ensure correct base href -->
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
  </head>
  <body>
    <app-root></app-root>
  </body>
</html>
```

2. **Verify polyfills:**

```typescript
// polyfills.ts
import "zone.js"; // Included with Angular CLI
```

3. **Check asset paths:**

```typescript
// angular.json
{
  "assets": [
    "src/favicon.ico",
    "src/assets"
  ]
}
```

### Development Server Issues

**Issue: `ng serve` fails to start**

**Symptoms:**

```
Port 4200 is already in use
```

**Solutions:**

1. **Kill process on port:**

```bash
# Find process
lsof -ti:4200

# Kill process
kill -9 $(lsof -ti:4200)
```

2. **Use different port:**

```bash
ng serve --port 4201
```

3. **Check for zombie processes:**

```bash
ps aux | grep ng
killall node
```

**Issue: Hot reload not working**

**Symptoms:**

- Changes not reflected in browser
- Manual refresh required

**Causes:**

- File watching issues
- Network restrictions
- Browser cache

**Solutions:**

1. **Check file watcher limits:**

```bash
# Increase system file watcher limits
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

2. **Disable browser cache:**

```typescript
// main.ts
if (environment.production === false) {
  // Disable browser cache in development
  document.head.innerHTML +=
    '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">';
}
```

3. **Restart development server:**

```bash
# Stop server (Ctrl+C)
ng serve --poll=2000  # Use polling for file changes
```

## Authentication Issues

### Login Problems

**Issue: Login fails with 401 Unauthorized**

**Symptoms:**

- Login form accepts credentials
- API returns 401 error
- User cannot access protected routes

**Causes:**

- Incorrect credentials
- Auth service unavailable
- Network connectivity issues
- CORS configuration problems

**Solutions:**

1. **Verify credentials:**

```typescript
// Check login request payload
console.log("Login payload:", credentials);
```

2. **Test auth service connectivity:**

```bash
curl -X POST http://localhost:8085/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'
```

3. **Check CORS configuration:**

```javascript
// In browser console
fetch("http://localhost:8085/api/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ username: "test", password: "test123" }),
})
  .then((response) => console.log("CORS test:", response))
  .catch((error) => console.error("CORS error:", error));
```

4. **Verify proxy configuration:**

```json
// proxy.conf.json
{
  "/api/auth/*": {
    "target": "http://localhost:8085",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  }
}
```

**Issue: Token not persisted after login**

**Symptoms:**

- Login succeeds
- Page refresh logs user out
- Token not found in localStorage

**Causes:**

- localStorage disabled/blocked
- Token not properly stored
- Storage quota exceeded

**Solutions:**

1. **Check localStorage availability:**

```typescript
// In browser console
try {
  localStorage.setItem("test", "value");
  console.log("localStorage available");
  localStorage.removeItem("test");
} catch (e) {
  console.error("localStorage not available:", e);
}
```

2. **Verify token storage:**

```typescript
// In AuthService.login()
.subscribe({
  next: (response) => {
    console.log('Storing token:', response.accessToken);
    localStorage.setItem('accessToken', response.accessToken);
    console.log('Token stored:', localStorage.getItem('accessToken'));
  }
});
```

3. **Check storage quota:**

```typescript
// Check localStorage usage
let total = 0;
for (let key in localStorage) {
  if (localStorage.hasOwnProperty(key)) {
    total += localStorage[key].length;
  }
}
console.log("localStorage usage:", total, "characters");
```

### Route Protection Issues

**Issue: Auth guard not working**

**Symptoms:**

- Unauthenticated users can access protected routes
- Authenticated users redirected unexpectedly

**Causes:**

- Auth guard not applied to routes
- Token validation logic incorrect
- Route configuration issues

**Solutions:**

1. **Verify route configuration:**

```typescript
// app.routes.ts
export const routes: Routes = [
  {
    path: "",
    component: ShellComponent,
    canActivate: [authGuard], // Ensure guard is applied
    children: [
      // Protected routes
    ],
  },
];
```

2. **Check auth guard logic:**

```typescript
// auth.guard.ts
export const authGuard: CanActivateFn = () => {
  const token = localStorage.getItem("accessToken");
  console.log("Auth guard check - token exists:", !!token);

  if (token) {
    return true;
  }

  console.log("Redirecting to login");
  inject(Router).navigate(["/login"]);
  return false;
};
```

3. **Test token validation:**

```typescript
// Check token validity
const token = localStorage.getItem("accessToken");
if (token) {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    const isExpired = payload.exp * 1000 < Date.now();
    console.log("Token expired:", isExpired);
  } catch (e) {
    console.error("Invalid token format");
  }
}
```

## WebSocket Connection Issues

### Connection Failures

**Issue: WebSocket connection fails**

**Symptoms:**

- WebSocket status shows disconnected
- Real-time updates not working
- Console shows connection errors

**Causes:**

- Incorrect WebSocket URLs
- Server not running
- Network/firewall issues
- Protocol mismatches

**Solutions:**

1. **Verify WebSocket URLs:**

```typescript
// Check environment configuration
console.log("Analytics WS URL:", environment.analytics.baseWs);
console.log("Leaderboard WS URL:", environment.leaderboard.baseWs);
console.log("RTTM WS URL:", environment.rttm.baseWs);
```

2. **Test WebSocket connectivity:**

```bash
# Test WebSocket connection
wscat -c ws://localhost:8086

# Test STOMP connection
curl -I http://localhost:8086
```

3. **Check protocol consistency:**

```typescript
// Ensure protocol matches environment
const isSecure = window.location.protocol === "https:";
const expectedProtocol = isSecure ? "wss:" : "ws:";
console.log("Expected protocol:", expectedProtocol);
```

4. **Verify server configuration:**

```typescript
// Check if WebSocket server is running
fetch("/ws/health")
  .then((response) => console.log("WS server health:", response.status))
  .catch((error) => console.error("WS server unreachable:", error));
```

**Issue: WebSocket reconnects frequently**

**Symptoms:**

- Connection established then immediately lost
- High reconnection frequency
- Performance degradation

**Causes:**

- Network instability
- Server-side connection limits
- Heartbeat configuration issues
- Memory leaks in connection handling

**Solutions:**

1. **Check network stability:**

```typescript
// Monitor network status
window.addEventListener("online", () => console.log("Network online"));
window.addEventListener("offline", () => console.log("Network offline"));
```

2. **Adjust heartbeat settings:**

```typescript
// In WebSocket service
this.client = new Client({
  heartbeatIncoming: 30000, // Increase from 10000
  heartbeatOutgoing: 30000, // Increase from 10000
  reconnectDelay: 10000, // Increase from 5000
});
```

3. **Implement connection pooling:**

```typescript
// Use connection pool to distribute load
private connectionPool: WebSocket[] = [];
private currentConnection = 0;

private getConnection(): WebSocket {
  return this.connectionPool[this.currentConnection++ % this.connectionPool.length];
}
```

### Message Handling Issues

**Issue: WebSocket messages not processed**

**Symptoms:**

- Connection established
- Messages received but not displayed
- Data not updating in UI

**Causes:**

- Message parsing errors
- Data normalization issues
- Component subscription problems

**Solutions:**

1. **Debug message parsing:**

```typescript
// Add message logging
this.ws.onmessage = (event) => {
  console.log("Raw message received:", event.data);
  try {
    const parsed = JSON.parse(event.data);
    console.log("Parsed message:", parsed);
    this.processMessage(parsed);
  } catch (error) {
    console.error("Message parsing failed:", error);
  }
};
```

2. **Check data normalization:**

```typescript
// Test normalization functions
const testData = {
  /* sample message */
};
const normalized = this.normalizeData(testData);
console.log("Normalized data:", normalized);
```

3. **Verify component subscriptions:**

```typescript
// Check if components are subscribed
ngOnInit() {
  console.log('Component initialized');
  this.subscription = this.wsService.data$.subscribe(data => {
    console.log('Data received in component:', data);
    // Process data
  });
}
```

## API Communication Issues

### HTTP Request Failures

**Issue: API calls fail with network errors**

**Symptoms:**

- API requests return network errors
- CORS errors in console
- Timeout errors

**Causes:**

- Backend services not running
- Proxy configuration issues
- CORS misconfiguration
- Network connectivity problems

**Solutions:**

1. **Test backend connectivity:**

```bash
# Test API endpoints
curl -I http://localhost:8080/api/analytics/health
curl -I http://localhost:8085/api/auth/health
```

2. **Check proxy configuration:**

```json
// proxy.conf.json
{
  "/api/*": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug",
    "headers": {
      "Connection": "keep-alive"
    }
  }
}
```

3. **Verify CORS headers:**

```typescript
// Backend CORS configuration
const corsOptions = {
  origin: ["http://localhost:4200", "http://localhost:8080"],
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true,
};
```

4. **Test with different network conditions:**

```typescript
// Add timeout and retry logic
this.http
  .get("/api/data", {
    timeout: 10000, // 10 second timeout
  })
  .pipe(
    retry(3), // Retry 3 times
    catchError((error) => {
      console.error("API call failed after retries:", error);
      return throwError(() => error);
    }),
  );
```

### Data Loading Issues

**Issue: Data not loading in components**

**Symptoms:**

- Components render but show no data
- Loading indicators stuck
- Console shows successful API calls

**Causes:**

- Async data handling issues
- Component lifecycle problems
- Observable subscription issues

**Solutions:**

1. **Check async data handling:**

```typescript
// Use async pipe in templates
<div *ngIf="data$ | async as data">
  {{ data | json }}
</div>

// Or handle in component
ngOnInit() {
  this.data$.subscribe({
    next: (data) => {
      console.log('Data loaded:', data);
      this.processData(data);
    },
    error: (error) => {
      console.error('Data loading failed:', error);
    }
  });
}
```

2. **Verify service calls:**

```typescript
// Add logging to services
@Injectable({ providedIn: "root" })
export class ApiService {
  getData(): Observable<Data> {
    console.log("Making API call to getData");
    return this.http.get<Data>("/api/data").pipe(
      tap((response) => console.log("API response:", response)),
      catchError((error) => {
        console.error("API error:", error);
        return throwError(() => error);
      }),
    );
  }
}
```

3. **Check change detection:**

```typescript
// Force change detection if needed
constructor(private cdr: ChangeDetectorRef) {}

ngOnInit() {
  this.data$.subscribe(data => {
    this.data = data;
    this.cdr.detectChanges();  // Force change detection
  });
}
```

## Performance Issues

### Slow Loading Times

**Issue: Application loads slowly**

**Symptoms:**

- Initial load takes > 3 seconds
- Bundle size too large
- Runtime performance issues

**Causes:**

- Large bundle sizes
- Inefficient lazy loading
- Memory leaks
- Heavy computations

**Solutions:**

1. **Analyze bundle size:**

```bash
ng build --stats-json
# Use webpack-bundle-analyzer to visualize
npx webpack-bundle-analyzer dist/stats.json
```

2. **Optimize lazy loading:**

```typescript
// Ensure proper route lazy loading
const routes: Routes = [
  {
    path: "dashboard",
    loadComponent: () =>
      import("./features/dashboard/dashboard.page").then(
        (m) => m.DashboardPage,
      ),
  },
];
```

3. **Implement virtual scrolling:**

```typescript
// For large lists
<cdk-virtual-scroll-viewport itemSize="50">
  <div *cdkVirtualFor="let item of items">
    {{ item.name }}
  </div>
</cdk-virtual-scroll-viewport>
```

4. **Optimize change detection:**

```typescript
// Use OnPush change detection
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyComponent {
  // Only update when inputs change
}
```

### Memory Leaks

**Issue: Memory usage increases over time**

**Symptoms:**

- Browser memory usage grows
- Performance degrades over time
- Application becomes unresponsive

**Causes:**

- Unsubscribed observables
- DOM element leaks
- Timer leaks
- Circular references

**Solutions:**

1. **Proper subscription management:**

```typescript
// Use subscription management
private subscriptions = new Subscription();

ngOnInit() {
  this.subscriptions.add(
    this.data$.subscribe(data => {
      // Handle data
    })
  );
}

ngOnDestroy() {
  this.subscriptions.unsubscribe();
}
```

2. **Use async pipe:**

```html
<!-- Automatically unsubscribes -->
<div *ngIf="data$ | async as data">{{ data.value }}</div>
```

3. **Clean up timers:**

```typescript
private timer?: number;

ngOnInit() {
  this.timer = window.setInterval(() => {
    // Do something
  }, 1000);
}

ngOnDestroy() {
  if (this.timer) {
    clearInterval(this.timer);
  }
}
```

## Browser Compatibility Issues

### Browser-Specific Problems

**Issue: Application doesn't work in older browsers**

**Symptoms:**

- JavaScript errors in specific browsers
- Features not working as expected
- Styling issues

**Causes:**

- Missing polyfills
- Unsupported ES6+ features
- CSS compatibility issues

**Solutions:**

1. **Add browser polyfills:**

```javascript
// polyfills.ts
import "core-js/es/array";
import "core-js/es/object";
import "core-js/es/promise";
```

2. **Configure TypeScript target:**

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "es2017",
    "lib": ["es2017", "dom"]
  }
}
```

3. **Use CSS vendor prefixes:**

```css
/* autoprefixer will add vendor prefixes */
.flex {
  display: flex;
}
```

### Mobile Responsiveness Issues

**Issue: Layout breaks on mobile devices**

**Symptoms:**

- Content not properly sized
- Touch interactions not working
- Navigation issues

**Causes:**

- Missing responsive design
- Touch event handling issues
- Viewport configuration problems

**Solutions:**

1. **Configure viewport:**

```html
<!-- index.html -->
<meta name="viewport" content="width=device-width, initial-scale=1" />
```

2. **Use responsive CSS:**

```css
/* Mobile-first approach */
.container {
  width: 100%;
  padding: 1rem;
}

@media (min-width: 768px) {
  .container {
    width: 750px;
    margin: 0 auto;
  }
}
```

3. **Handle touch events:**

```typescript
// Handle touch events properly
@HostListener('touchstart', ['$event'])
onTouchStart(event: TouchEvent) {
  // Handle touch start
}

@HostListener('touchend', ['$event'])
onTouchEnd(event: TouchEvent) {
  // Handle touch end
}
```

## Deployment Issues

### Production Build Problems

**Issue: Production build fails**

**Symptoms:**

- Development build works
- Production build fails
- Different behavior in production

**Causes:**

- AOT compilation issues
- Tree-shaking problems
- Environment configuration issues

**Solutions:**

1. **Fix AOT compilation errors:**

```typescript
// Avoid template errors
@Component({
  template: ` <div *ngIf="data">{{ data.name }}</div> `,
})
export class MyComponent {
  data?: { name: string };
}
```

2. **Handle environment differences:**

```typescript
// Use environment checks
if (!environment.production) {
  // Development-only code
}
```

3. **Fix tree-shaking issues:**

```typescript
// Ensure imports are used
import { map } from "rxjs/operators";

// Use the import
observable.pipe(map((x) => x));
```

### Runtime Issues in Production

**Issue: Application works in development but fails in production**

**Symptoms:**

- Console errors in production
- Features not working
- Different behavior than development

**Causes:**

- Missing assets
- Incorrect base paths
- Environment configuration issues
- CDN issues

**Solutions:**

1. **Check asset loading:**

```html
<!-- Ensure correct paths -->
<script src="/runtime.js"></script>
<script src="/polyfills.js"></script>
<script src="/main.js"></script>
```

2. **Verify environment configuration:**

```typescript
// Check production environment
console.log("Production mode:", environment.production);
console.log("API URLs:", environment.analytics.baseHttp);
```

3. **Test with production build locally:**

```bash
ng build --configuration=production
npx http-server dist/pms-frontend -p 8080
```

## Debugging Tools and Techniques

### Browser Developer Tools

**Network Tab:**

```javascript
// Monitor API calls
// Check WebSocket connections
// Verify asset loading
```

**Console Commands:**

```javascript
// Check application state
angular.getComponent(document.querySelector("app-root"));

// Inspect component instances
ng.getComponent(element);

// Debug change detection
ng.profiler.timeChangeDetection();
```

### Angular DevTools

**Component Inspection:**

```javascript
// Install Angular DevTools extension
// Inspect component tree
// Monitor change detection
// Profile performance
```

### Performance Monitoring

**Lighthouse Audit:**

```bash
# Run Lighthouse audit
npx lighthouse http://localhost:4200 --output=json --output-path=./report.json
```

**Memory Leak Detection:**

```javascript
// Use Chrome DevTools Memory tab
// Take heap snapshots
// Look for detached DOM nodes
// Monitor memory usage over time
```

## Prevention Best Practices

### Code Quality

**Linting and Formatting:**

```json
// .eslintrc.json
{
  "extends": ["@angular-eslint/recommended"],
  "rules": {
    "@angular-eslint/no-output-on-prefix": "error",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

**Unit Testing:**

```typescript
// Comprehensive test coverage
describe("MyComponent", () => {
  it("should handle error states", () => {
    // Test error scenarios
  });
});
```

### Error Boundaries

**Global Error Handling:**

```typescript
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  handleError(error: any): void {
    // Log errors
    console.error("Global error:", error);

    // Send to error tracking service
    this.errorTrackingService.captureError(error);

    // Show user-friendly message
    this.toastService.showError("An unexpected error occurred");
  }
}
```

### Monitoring and Alerting

**Application Monitoring:**

```typescript
// Track key metrics
@Injectable({ providedIn: "root" })
export class MonitoringService {
  trackError(error: Error): void {
    // Send to monitoring service
  }

  trackPerformance(metric: string, value: number): void {
    // Track performance metrics
  }
}
```

## Emergency Procedures

### Application Unresponsive

**Immediate Actions:**

1. Check browser console for errors
2. Verify network connectivity
3. Clear browser cache and cookies
4. Try incognito/private browsing mode
5. Restart development server
6. Check backend service status

**Recovery Steps:**

```bash
# 1. Stop all processes
pkill -f "ng serve"
pkill -f "node"

# 2. Clear caches
rm -rf .angular/cache
rm -rf node_modules/.cache

# 3. Reinstall dependencies
npm install

# 4. Restart services
ng serve
```

### Data Loss Prevention

**Backup Strategies:**

- Regular git commits
- Environment configuration backups
- Database backups (for backend services)
- Asset backups

**Recovery Procedures:**

```bash
# Restore from git
git checkout <last-working-commit>
npm install
ng serve

# Restore configuration
cp environment.ts.backup environment.ts
```

## Support and Escalation

### Internal Resources

**Team Contacts:**

- Frontend Lead: [contact info]
- Backend Team: [contact info]
- DevOps Team: [contact info]

**Documentation:**

- [API Documentation](../reference/endpoints.md)
- [Troubleshooting Guide](./common-issues.md)
- [Configuration Guide](./configuration.md)

### External Resources

**Angular Resources:**

- [Angular Documentation](https://angular.dev)
- [Angular CLI](https://angular.dev/tools/cli)
- [Angular DevTools](https://angular.dev/tools/devtools)

**WebSocket Resources:**

- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [STOMP Protocol](https://stomp.github.io)

**Browser Support:**

- [Chrome DevTools](https://developer.chrome.com/docs/devtools/)
- [Firefox DevTools](https://developer.mozilla.org/en-US/docs/Tools)

## Issue Reporting Template

**When reporting issues, include:**

```markdown
## Issue Summary

[Brief description of the problem]

## Environment

- Browser: [Chrome/Firefox/Safari]
- OS: [Windows/macOS/Linux]
- Angular Version: [17.x.x]
- Node Version: [18.x.x]

## Steps to Reproduce

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Console Errors
```

[Error messages from browser console]

```

## Screenshots
[Attach screenshots if applicable]

## Additional Context
[Any other relevant information]
```
