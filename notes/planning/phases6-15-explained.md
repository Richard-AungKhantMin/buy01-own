# Phases 6-15 Explained - Frontend Development & Beyond

This comprehensive document covers all remaining phases (6-15) of the e-commerce platform build.

---

## Phase 6: Frontend Development - Angular Setup

### Step 24: Angular Project Initialization

**What is Angular?**
A framework for building single-page applications (SPAs) - web apps that load once and dynamically update content without full page reloads.

**Why Angular?**
- Component-based architecture (reusable UI pieces)
- TypeScript (JavaScript with types - catches errors early)
- Built-in routing, forms, HTTP client
- Large ecosystem and community support

**Create Angular Project:**
```bash
# Install Angular CLI globally
npm install -g @angular/cli

# Create new project
ng new ecommerce-frontend

# Questions it asks:
# - Routing? YES (we need multiple pages)
# - Stylesheet format? CSS or SCSS (choose SCSS for advanced styling)

cd ecommerce-frontend
```

**Install Dependencies:**
```bash
# Angular Material (UI components)
ng add @angular/material

# Or Bootstrap
npm install bootstrap

# JWT decode library (to read JWT tokens)
npm install jwt-decode

# Other useful libraries
npm install ngx-toastr  # Toast notifications
npm install @ngrx/store  # State management (optional)
```

**Project Structure:**
```
ecommerce-frontend/
├── src/
│   ├── app/
│   │   ├── core/              # Singleton services (auth, API)
│   │   ├── shared/            # Shared components, pipes, directives
│   │   ├── features/          # Feature modules
│   │   │   ├── auth/         # Login, register
│   │   │   ├── products/     # Product listing, details
│   │   │   └── seller/       # Seller dashboard
│   │   ├── app.component.ts   # Root component
│   │   └── app-routing.module.ts  # Routes
│   ├── environments/          # Environment configs
│   │   ├── environment.ts    # Development
│   │   └── environment.prod.ts  # Production
│   └── assets/               # Images, fonts, etc.
└── angular.json              # Angular configuration
```

**Environment Configuration:**
```typescript
// environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080'  // API Gateway URL
};

// environment.prod.ts (production)
export const environment = {
  production: true,
  apiUrl: 'https://api.yourdomain.com'
};
```

**Proxy Configuration** (to avoid CORS during development):
```json
// proxy.conf.json
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true
  }
}
```

Update `package.json`:
```json
"scripts": {
  "start": "ng serve --proxy-config proxy.conf.json"
}
```

---

### Step 25: Core Module & Services

**CoreModule** - Singleton services used throughout app:
```typescript
@NgModule({
  providers: [
    AuthService,
    UserService,
    ProductService,
    MediaService,
    SessionService
  ]
})
export class CoreModule {
  // Prevent reimporting CoreModule
  constructor(@Optional() @SkipSelf() parentModule: CoreModule) {
    if (parentModule) {
      throw new Error('CoreModule is already loaded. Import it only once in AppModule.');
    }
  }
}
```

**AuthService Example:**
```typescript
@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = environment.apiUrl;
  
  constructor(private http: HttpClient, private sessionService: SessionService) {}
  
  register(data: RegisterRequest): Observable<any> {
    return this.http.post(`${this.apiUrl}/auth/register`, data);
  }
  
  login(credentials: LoginRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/auth/login`, credentials)
      .pipe(
        tap(response => {
          // Save token and user info
          this.sessionService.setToken(response.token);
          this.sessionService.setUser(response.user);
        })
      );
  }
  
  logout(): void {
    this.sessionService.clear();
  }
  
  isAuthenticated(): boolean {
    return this.sessionService.hasToken();
  }
}
```

---

### Step 26: Authentication Infrastructure

**AuthInterceptor** - Automatically adds JWT to requests:
```typescript
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  
  constructor(private sessionService: SessionService) {}
  
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.sessionService.getToken();
    
    if (token) {
      // Clone request and add Authorization header
      req = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
    }
    
    return next.handle(req);
  }
}
```

**ErrorInterceptor** - Handles HTTP errors:
```typescript
@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  
  constructor(private router: Router, private toastr: ToastrService) {}
  
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          // Unauthorized - redirect to login
          this.toastr.error('Session expired. Please login again.');
          this.router.navigate(['/login']);
        } else if (error.status === 403) {
          // Forbidden
          this.toastr.error('You don\'t have permission for this action.');
        } else if (error.status === 0) {
          // Network error
          this.toastr.error('Network error. Please check your connection.');
        } else {
          // Other errors
          const message = error.error?.message || 'An error occurred';
          this.toastr.error(message);
        }
        
        return throwError(() => error);
      })
    );
  }
}
```

**AuthGuard** - Protects routes:
```typescript
@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  
  constructor(
    private authService: AuthService,
    private router: Router,
    private toastr: ToastrService
  ) {}
  
  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): boolean {
    if (this.authService.isAuthenticated()) {
      return true;  // Allow access
    }
    
    // Redirect to login
    this.toastr.warning('Please login to continue');
    this.router.navigate(['/login'], {
      queryParams: { returnUrl: state.url }  // Remember where they wanted to go
    });
    return false;
  }
}
```

**RoleGuard** - Checks user role:
```typescript
@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate {
  
  constructor(
    private sessionService: SessionService,
    private router: Router,
    private toastr: ToastrService
  ) {}
  
  canActivate(route: ActivatedRouteSnapshot): boolean {
    const requiredRole = route.data['role'];  // Set in route config
    const userRole = this.sessionService.getUserRole();
    
    if (userRole === requiredRole) {
      return true;
    }
    
    this.toastr.error('Access denied');
    this.router.navigate(['/']);
    return false;
  }
}
```

**Usage in Routes:**
```typescript
const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { 
    path: 'profile', 
    component: ProfileComponent,
    canActivate: [AuthGuard]  // Must be logged in
  },
  {
    path: 'seller',
    component: SellerDashboardComponent,
    canActivate: [AuthGuard, RoleGuard],
    data: { role: 'SELLER' }  // Must be seller
  }
];
```

---

### Step 27: State Management & Models

**TypeScript Interfaces:**
```typescript
// models/user.model.ts
export interface User {
  id: string;
  name: string;
  email: string;
  role: 'CLIENT' | 'SELLER';
  avatar?: string;
  createdAt: Date;
}

// models/product.model.ts
export interface Product {
  id: string;
  name: string;
  description?: string;
  price: number;
  quantity: number;
  imageUrls: string[];
  userId: string;
  createdAt: Date;
}

// models/auth.model.ts
export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  role: 'CLIENT' | 'SELLER';
  avatar?: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}
```

**SessionService:**
```typescript
@Injectable({
  providedIn: 'root'
})
export class SessionService {
  private readonly TOKEN_KEY = 'auth_token';
  private readonly USER_KEY = 'user_info';
  
  setToken(token: string): void {
    localStorage.setItem(this.TOKEN_KEY, token);
  }
  
  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }
  
  hasToken(): boolean {
    return !!this.getToken();
  }
  
  setUser(user: User): void {
    localStorage.setItem(this.USER_KEY, JSON.stringify(user));
  }
  
  getUser(): User | null {
    const userJson = localStorage.getItem(this.USER_KEY);
    return userJson ? JSON.parse(userJson) : null;
  }
  
  getUserRole(): string | null {
    const user = this.getUser();
    return user ? user.role : null;
  }
  
  clear(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.USER_KEY);
  }
}
```

---

## Phase 7: Frontend Development - Authentication Pages

### Step 28: Sign-Up Page

**Component:**
```typescript
export class RegisterComponent implements OnInit {
  registerForm: FormGroup;
  loading = false;
  showAvatarUpload = false;
  
  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private toastr: ToastrService
  ) {}
  
  ngOnInit(): void {
    this.registerForm = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(8)]],
      confirmPassword: ['', Validators.required],
      role: ['CLIENT', Validators.required],
      avatar: ['']
    }, { validators: this.passwordMatchValidator });
    
    // Show avatar upload for sellers
    this.registerForm.get('role')?.valueChanges.subscribe(role => {
      this.showAvatarUpload = role === 'SELLER';
    });
  }
  
  passwordMatchValidator(g: FormGroup) {
    return g.get('password')?.value === g.get('confirmPassword')?.value
      ? null
      : { mismatch: true };
  }
  
  onSubmit(): void {
    if (this.registerForm.invalid) {
      return;
    }
    
    this.loading = true;
    const formValue = this.registerForm.value;
    
    this.authService.register(formValue).subscribe({
      next: () => {
        this.toastr.success('Registration successful! Please login.');
        this.router.navigate(['/login']);
      },
      error: () => {
        this.loading = false;
      },
      complete: () => {
        this.loading = false;
      }
    });
  }
}
```

**Template:**
```html
<form [formGroup]="registerForm" (ngSubmit)="onSubmit()">
  <h2>Create Account</h2>
  
  <!-- Name -->
  <mat-form-field>
    <input matInput placeholder="Full Name" formControlName="name">
    <mat-error *ngIf="registerForm.get('name')?.hasError('required')">
      Name is required
    </mat-error>
    <mat-error *ngIf="registerForm.get('name')?.hasError('minlength')">
      Name must be at least 2 characters
    </mat-error>
  </mat-form-field>
  
  <!-- Email -->
  <mat-form-field>
    <input matInput type="email" placeholder="Email" formControlName="email">
    <mat-error *ngIf="registerForm.get('email')?.hasError('required')">
      Email is required
    </mat-error>
    <mat-error *ngIf="registerForm.get('email')?.hasError('email')">
      Invalid email format
    </mat-error>
  </mat-form-field>
  
  <!-- Password -->
  <mat-form-field>
    <input matInput type="password" placeholder="Password" formControlName="password">
    <mat-error *ngIf="registerForm.get('password')?.hasError('required')">
      Password is required
    </mat-error>
    <mat-error *ngIf="registerForm.get('password')?.hasError('minlength')">
      Password must be at least 8 characters
    </mat-error>
  </mat-form-field>
  
  <!-- Confirm Password -->
  <mat-form-field>
    <input matInput type="password" placeholder="Confirm Password" formControlName="confirmPassword">
    <mat-error *ngIf="registerForm.hasError('mismatch')">
      Passwords do not match
    </mat-error>
  </mat-form-field>
  
  <!-- Role Selection -->
  <mat-radio-group formControlName="role">
    <mat-radio-button value="CLIENT">I want to buy products</mat-radio-button>
    <mat-radio-button value="SELLER">I want to sell products</mat-radio-button>
  </mat-radio-group>
  
  <!-- Avatar Upload (for sellers) -->
  <div *ngIf="showAvatarUpload">
    <app-file-upload 
      (fileUploaded)="onAvatarUploaded($event)"
      accept="image/*">
    </app-file-upload>
  </div>
  
  <button mat-raised-button color="primary" type="submit" [disabled]="loading || registerForm.invalid">
    <mat-spinner *ngIf="loading" diameter="20"></mat-spinner>
    <span *ngIf="!loading">Register</span>
  </button>
  
  <p>Already have an account? <a routerLink="/login">Login here</a></p>
</form>
```

---

### Step 29: Sign-In Page

Similar structure to registration, simpler form:

```typescript
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  loading = false;
  
  ngOnInit(): void {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required],
      rememberMe: [false]
    });
  }
  
  onSubmit(): void {
    if (this.loginForm.invalid) return;
    
    this.loading = true;
    this.authService.login(this.loginForm.value).subscribe({
      next: (response) => {
        this.toastr.success('Welcome back!');
        
        // Redirect based on role
        if (response.user.role === 'SELLER') {
          this.router.navigate(['/seller/dashboard']);
        } else {
          this.router.navigate(['/products']);
        }
      },
      error: () => {
        this.loading = false;
      }
    });
  }
}
```

---

## Phase 8: Frontend Development - Seller Features

### Step 31-34: Seller Dashboard, Products, Media

**Key Components:**
1. **Seller Dashboard Layout** - Navigation sidebar, header
2. **Product List** - Table/grid of seller's products
3. **Product Form** - Create/edit products with image management
4. **Media Library** - Grid of uploaded images

**Example: Product List Component**
```typescript
export class SellerProductsComponent implements OnInit {
  products: Product[] = [];
  loading = true;
  page = 0;
  size = 10;
  totalItems = 0;
  
  constructor(
    private productService: ProductService,
    private dialog: MatDialog,
    private toastr: ToastrService
  ) {}
  
  ngOnInit(): void {
    this.loadProducts();
  }
  
  loadProducts(): void {
    this.loading = true;
    this.productService.getMyProducts(this.page, this.size).subscribe({
      next: (response) => {
        this.products = response.content;
        this.totalItems = response.totalElements;
        this.loading = false;
      }
    });
  }
  
  deleteProduct(product: Product): void {
    const dialogRef = this.dialog.open(ConfirmDialogComponent, {
      data: { message: `Delete "${product.name}"?` }
    });
    
    dialogRef.afterClosed().subscribe(confirmed => {
      if (confirmed) {
        this.productService.delete(product.id).subscribe({
          next: () => {
            this.toastr.success('Product deleted');
            this.loadProducts();  // Refresh list
          }
        });
      }
    });
  }
  
  onPageChange(event: PageEvent): void {
    this.page = event.pageIndex;
    this.size = event.pageSize;
    this.loadProducts();
  }
}
```

---

## Phase 9: Frontend Development - Public Product Pages

### Step 35-36: Product Listing & Detail Pages

**Product Listing** - Show all products in cards:
```typescript
export class ProductListComponent implements OnInit {
  products: Product[] = [];
  loading = true;
  
  ngOnInit(): void {
    this.productService.getAll().subscribe({
      next: (response) => {
        this.products = response.content;
        this.loading = false;
      }
    });
  }
}
```

**Template with cards:**
```html
<div class="product-grid">
  <mat-card *ngFor="let product of products" 
            [routerLink]="['/products', product.id]"
            class="product-card">
    <img mat-card-image [src]="product.imageUrls[0] || 'assets/placeholder.jpg'" 
         [alt]="product.name">
    <mat-card-content>
      <h3>{{product.name}}</h3>
      <p class="price">${{product.price | number:'1.2-2'}}</p>
      <p class="description">{{product.description | slice:0:100}}...</p>
    </mat-card-content>
  </mat-card>
</div>
```

---

## Phase 10: UI/UX Polish & Responsive Design

### Step 37-39: Responsive Design, Loading States, Validation

**Key Concepts:**
- **Mobile-first CSS**: Start with mobile styles, add desktop styles with media queries
- **Loading spinners**: Show when fetching data
- **Skeleton screens**: Placeholder content while loading
- **Toast notifications**: Success/error messages
- **Form validation**: Inline errors, disable buttons when invalid

**Responsive Grid:**
```scss
.product-grid {
  display: grid;
  gap: 20px;
  
  // Mobile (1 column)
  grid-template-columns: 1fr;
  
  // Tablet (2 columns)
  @media (min-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }
  
  // Desktop (4 columns)
  @media (min-width: 1024px) {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

---

## Phase 11: Security Hardening

### Step 40-42: HTTPS, Input Sanitization, XSS Prevention

**Key Security Practices:**
1. **HTTPS only** in production
2. **Never use innerHTML** with user content (use textContent or Angular's sanitizer)
3. **CSRF tokens** with HttpClient (automatic in Angular)
4. **Secure token storage** (consider httpOnly cookies in production)
5. **Input validation** on frontend AND backend

---

## Phase 12: Testing Strategy

### Step 43-46: Unit, Integration, E2E Tests

**Unit Test Example:**
```typescript
describe('AuthService', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;
  
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AuthService]
    });
    
    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
  });
  
  it('should login successfully', () => {
    const mockResponse = {
      token: 'fake-jwt-token',
      user: { id: '1', name: 'Test', email: 'test@test.com', role: 'CLIENT' }
    };
    
    service.login({ email: 'test@test.com', password: 'pass' }).subscribe(response => {
      expect(response.token).toBe('fake-jwt-token');
    });
    
    const req = httpMock.expectOne(`${environment.apiUrl}/auth/login`);
    expect(req.request.method).toBe('POST');
    req.flush(mockResponse);
  });
  
  afterEach(() => {
    httpMock.verify();
  });
});
```

---

## Phase 13: DevOps & Deployment

### Step 47-50: Docker, CI/CD, Deployment

**Dockerfile for Angular:**
```dockerfile
# Build stage
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build --prod

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist/ecommerce-frontend /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf:**
```nginx
server {
  listen 80;
  location / {
    root /usr/share/nginx/html;
    index index.html;
    try_files $uri $uri/ /index.html;  # SPA routing
  }
}
```

---

## Phase 14: Observability & Monitoring

### Step 51-54: Health Checks, Logging, Metrics, Tracing

**Key Tools:**
- **Actuator**: Health endpoints
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **ELK Stack**: Log aggregation
- **Zipkin/Jaeger**: Distributed tracing

---

## Phase 15: Documentation & Finalization

### Step 55-60: API Docs, Seed Data, Testing, Handover

**Swagger/OpenAPI:** Auto-generated API documentation
**Seed Data:** Sample users and products for testing
**Final Testing:** All flows work end-to-end
**README:** Complete setup instructions
**Presentation:** Demo for stakeholders

---

## Summary

You now have explanations for all 15 phases covering:
- ✅ **Backend**: User, Product, Media services
- ✅ **Gateway**: Routing, security, CORS
- ✅ **Frontend**: Angular with authentication, products, seller features
- ✅ **Security**: JWT, role-based access, input validation
- ✅ **Testing**: Unit, integration, E2E
- ✅ **DevOps**: Docker, CI/CD, deployment
- ✅ **Monitoring**: Logging, metrics, tracing
- ✅ **Documentation**: API docs, README, handover

Each phase builds on the previous, creating a complete, production-ready e-commerce platform!
