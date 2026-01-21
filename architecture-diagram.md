# E-Commerce Polyrepo Architecture Diagram

## System Architecture Overview
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                   CLIENT                                    │
│                         (Browser / Mobile App)                              │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
                                     │ HTTP/REST
                                     │
                    ┌────────────────▼────────────────┐
                    │                                 │
                    │     Frontend (Next.js)          │
                    │     Port: 3000                  │
                    │     Tech: React, TypeScript     │
                    │                                 │
                    └────────────────┬────────────────┘
                                     │
                                     │ HTTP/REST
                                     │
        ┌────────────────────────────▼──────────────────────────────┐
        │                                                           │
        │           API Gateway (be-api-gin)                        │
        │           Port: 8080                                      │
        │           Tech: Go (Gin Framework)                        │
        │                                                           │
        │  Features:                                                │
        │  • JWT Authentication & Validation                        │
        │  • Request Routing                                        │
        │  • Rate Limiting                                          │
        │  • CORS Handling                                          │
        │                                                           │
        └──────┬─────────────────┬──────────────────┬───────────────┘
               │                 │                  │
               │ gRPC            │ gRPC             │ gRPC
               │ :50051          │ :9090            │ :50052
               │                 │                  │
    ┌──────────▼──────────┐ ┌────▼───────────────┐ ┌▼────────────────────┐
    │                     │ │                    │ │                     │
    │  User Service       │ │  Listing Service   │ │ Inventory Service   │
    │  (svc-user-django)  │ │(svc-listing-spring)│ │(svc-inventory-rails)│
    │                     │ │                    │ │                     │
    │  REST: 8001         │ │  REST: 8082        │ │  REST: 3001         │
    │  gRPC: 50051        │ │  gRPC: 9090        │ │  gRPC: 50052        │
    │                     │ │                    │ │                     │
    │  Tech: Django       │ │  Tech: Spring Boot │ │  Tech: Rails        │
    │  Python 3.11        │ │  Java 17           │ │  Ruby 3.2           │
    │                     │ │                    │ │                     │
    │  Features:          │ │  Features:         │ │  Features:          │
    │  • User Auth        │ │  • Product Catalog │ │  • Stock Tracking   │
    │  • JWT Tokens       │ │  • Categories      │ │  • Reservations     │
    │  • User Profiles    │ │  • Search          │ │  • Movements        │
    │  • Permissions      │ │  • Variants        │ │  • Warehouses       │
    │                     │ │                    │ │  • Backorders       │
    └──────────┬──────────┘ └───────┬────────────┘ └─────┬───────────────┘
               │                    │                    │
               │                    │                    │
               └────────────────────┼────────────────────┘
                                    │
                    ┌───────────────┴────────────────┐
                    │                                │
        ┌───────────▼──────────┐      ┌──────────────▼──────────┐
        │                      │      │                         │
        │   PostgreSQL         │      │        Redis            │
        │   Port: 5433         │      │        Port: 6379       │
        │   (Host:5433→5432)   │      │                         │
        │   Databases:         │      │   Usage:                │
        │   • users            │      │   • Session Storage     │
        │   • listings         │      │   • Caching             │
        │   • inventory        │      │   • Background Jobs     │
        │   • ecommerce        │      │     (Sidekiq)           │
        │                      │      │                         │
        └──────────────────────┘      └─────────────────────────┘
```
## Communication Patterns
### 1. External Client Flow (via API Gateway)
```
Client → Frontend (3000) → API Gateway (8080) → gRPC → Microservice
                                                      ↓
                                                 PostgreSQL
```
### 2. Direct Service Access (Development)
```
Client → User Service (8001)      → PostgreSQL (users db)
Client → Listing Service (8082)   → PostgreSQL (listings db)
Client → Inventory Service (3001) → PostgreSQL (inventory db)
```
### 3. Service-to-Service Communication
```
User Service ←──gRPC──→ Listing Service
                  ↓
           Inventory Service
```
## Data Flow Example: Create Order
```
1. Client Request
   │
   ├──→ Frontend (Next.js)
   │    │
   │    └──→ API Gateway (POST /api/v1/orders + JWT)
   │         │
   │         ├──→ User Service (gRPC: ValidateToken)
   │         │    └──→ PostgreSQL (users db)
   │         │         Returns: User Valid ✓
   │         │
   │         ├──→ Listing Service (gRPC: GetProduct)
   │         │    └──→ PostgreSQL (listings db)
   │         │         Returns: Product Details
   │         │
   │         └──→ Inventory Service (gRPC: ReserveStock)
   │              └──→ PostgreSQL (inventory db)
   │                   Returns: Reservation ID
   │ ←───────Response: Order Created ✓
```
## Authentication Flow
```
1. User Registration/Login
   Client → User Service → PostgreSQL (users db)
   ← Returns: JWT Access Token + Refresh Token
2. Authenticated Request
   Client → API Gateway (with Bearer Token)
   │
   └──→ User Service (gRPC: ValidateToken)
        └──→ PostgreSQL / Redis Cache
             Returns: Valid/Invalid
             │
             └──→ If Valid: Route to target service
                  If Invalid: 401 Unauthorized
```
## Network Configuration (Docker)
```
Network: ecommerce-network (172.28.0.0/16)
Container Hostnames:
├── fe-nextjs:3000
├── be-api-gin:8080
├── svc-user-django:8000 (gRPC: 50051)
├── svc-listing-spring:8080 (gRPC: 9090)
├── svc-inventory-rails:3000 (gRPC: 50051)
├── postgres:5432
└── redis:6379
Port Mappings (Host:Container):
├── Frontend:         3000:3000
├── API Gateway:      8080:8080
├── User Service:     8001:8000, 50051:50051
├── Listing Service:  8082:8080, 9090:9090
├── Inventory Service: 3001:3000, 50052:50051
├── PostgreSQL:       5433:5432
└── Redis:            6379:6379
```
## Technology Stack Summary
```
┌─────────────────────┬──────────────────┬───────────────────┐
│ Service             │ Technology       │ Port (REST/gRPC)  │
├─────────────────────┼──────────────────┼───────────────────┤
│ Frontend            │ Next.js/React    │ 3000              │
│ API Gateway         │ Go (Gin)         │ 8080              │
│ User Service        │ Django/Python    │ 8001 / 50051      │
│ Listing Service     │ Spring Boot/Java │ 8082 / 9090       │
│ Inventory Service   │ Rails/Ruby       │ 3001 / 50052      │
├─────────────────────┼──────────────────┼───────────────────┤
│ Database            │ PostgreSQL 15    │ 5433              │
│ Cache/Queue         │ Redis 7          │ 6379              │
└─────────────────────┴──────────────────┴───────────────────┘
```
## Protocol Buffer (gRPC) Schema Management
```
                    ┌──────────────────────┐
                    │   proto-schemas      │
                    │   (Central Repo)     │
                    │                      │
                    │  • user/v1           │
                    │  • listing/v1        │
                    │  • inventory/v1      │
                    │  • common/v1         │
                    └───────────┬──────────┘
                                │
                    ┌───────────┴────────────┐
                    │    Buf CLI (build)     │
                    └───────────┬────────────┘
                                │
            ┌───────────────────┼────────────────────┐
            │                   │                    │
    ┌───────▼──────┐     ┌──────▼──────┐     ┌───────▼──────┐
    │ Go Stubs     │     │ Java Stubs  │     │ Ruby Stubs   │
    │ (API Gateway)│     │ (Listing)   │     │ (Inventory)  │
    └──────────────┘     └─────────────┘     └──────────────┘
```
## Key Architectural Patterns
1. **API Gateway Pattern**: Single entry point for all client requests
2. **Database per Service**: Each microservice owns its data schema
3. **Synchronous gRPC Communication**: Low-latency service-to-service calls
4. **JWT Authentication**: Stateless token-based auth with validation
5. **Shared Infrastructure**: Common PostgreSQL instance with separate databases
6. **Polyglot Architecture**: Best tool for each job (Go, Python, Java, Ruby)
## Deployment Options
```
Local Development:
├── Docker Compose (simplest)
├── Skaffold (with hot reload)
└── Tilt (UI-based)
Production:
├── Kubernetes (local-k8s/k8s/)
├── AWS EKS (infra-terraform-eks/)
└── Minikube (local testing)
```