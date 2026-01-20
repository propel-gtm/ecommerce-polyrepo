# Local Kubernetes Development Setup

This directory contains all the necessary configurations for running the ecommerce polyrepo services locally using Minikube.

## Prerequisites

Before getting started, ensure you have the following tools installed:

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| **Docker** | 20.10+ | [Install Docker](https://docs.docker.com/get-docker/) |
| **Minikube** | 1.30+ | [Install Minikube](https://minikube.sigs.k8s.io/docs/start/) |
| **kubectl** | 1.28+ | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| **Skaffold** | 2.0+ | [Install Skaffold](https://skaffold.dev/docs/install/) |
| **Tilt** (optional) | 0.33+ | [Install Tilt](https://docs.tilt.dev/install.html) |

### Verify Installation

```bash
docker --version
minikube version
kubectl version --client
skaffold version
```

## Quick Start

### Option 1: One-Click Setup (Recommended)

```bash
# Run the setup script
./scripts/setup-minikube.sh
```

This script will:
1. Start Minikube with appropriate resources
2. Enable required addons (ingress, metrics-server)
3. Build all Docker images
4. Deploy all services to Kubernetes
5. Set up port forwarding

### Option 2: Using Make Commands

```bash
# Start everything
make start

# View logs
make logs

# Rebuild and redeploy
make rebuild

# Stop everything
make stop
```

### Option 3: Using Skaffold (Hot Reload)

```bash
# Start with hot reload enabled
skaffold dev

# Or just build and deploy once
skaffold run
```

### Option 4: Using Tilt (Live Development)

```bash
# Start Tilt
tilt up

# Open Tilt UI in browser
open http://localhost:10350
```

### Option 5: Docker Compose (No Kubernetes)

```bash
# Start all services with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Architecture Overview

```
                                    +------------------+
                                    |    Ingress       |
                                    |  (localhost:80)  |
                                    +--------+---------+
                                             |
                    +------------------------+------------------------+
                    |                                                 |
           +--------v---------+                              +--------v---------+
           |   fe-nextjs      |                              |   be-api-gin     |
           |   (Frontend)     |                              |  (API Gateway)   |
           |   Port: 3000     |                              |   Port: 8080     |
           +------------------+                              +--------+---------+
                                                                      |
                              +---------------------------------------+---------------------------------------+
                              |                                       |                                       |
                     +--------v---------+                    +--------v---------+                    +--------v---------+
                     | svc-user-django  |                    | svc-listing-spring|                   | svc-inventory-rails|
                     |  (User Service)  |                    | (Listing Service) |                   |(Inventory Service) |
                     |  REST: 8000      |                    |  REST: 8080       |                   |  REST: 3000        |
                     |  gRPC: 50051     |                    |  gRPC: 9090       |                   |  gRPC: 50051       |
                     +--------+---------+                    +--------+---------+                    +--------+---------+
                              |                                       |                                       |
                              +---------------------------------------+---------------------------------------+
                                                                      |
                                                      +---------------+---------------+
                                                      |                               |
                                              +-------v-------+               +-------v-------+
                                              |   PostgreSQL  |               |     Redis     |
                                              |   Port: 5432  |               |   Port: 6379  |
                                              +---------------+               +---------------+
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| Frontend (Next.js) | 3000 | Customer-facing web application |
| API Gateway (Gin) | 8080 | REST API gateway, routes to microservices |
| User Service (Django) | 8000/50051 | User management, authentication |
| Listing Service (Spring) | 8080/9090 | Product listings management |
| Inventory Service (Rails) | 3000/50051 | Inventory and stock management |
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Caching and session storage |

## Accessing Services

After deployment, services are accessible at:

### Using Minikube Tunnel (Recommended)

```bash
# Start tunnel in a separate terminal
minikube tunnel

# Access services
# Frontend: http://ecommerce.local
# API: http://api.ecommerce.local
```

Add to `/etc/hosts`:
```
127.0.0.1 ecommerce.local api.ecommerce.local
```

### Using Port Forwarding

```bash
# Frontend
kubectl port-forward svc/fe-nextjs 3000:3000 -n ecommerce

# API Gateway
kubectl port-forward svc/be-api-gin 8080:8080 -n ecommerce

# PostgreSQL
kubectl port-forward svc/postgres 5432:5432 -n ecommerce

# Redis
kubectl port-forward svc/redis 6379:6379 -n ecommerce
```

### Using NodePort

```bash
# Get Minikube IP
minikube ip

# Access services via NodePort
# Frontend: http://<minikube-ip>:30000
# API Gateway: http://<minikube-ip>:30080
```

## Directory Structure

```
local-k8s/
├── README.md                    # This file
├── skaffold.yaml               # Skaffold configuration
├── docker-compose.yaml         # Docker Compose alternative
├── Makefile                    # Common commands
├── Tiltfile                    # Tilt configuration
├── k8s/
│   ├── namespace.yaml          # Namespace definition
│   ├── configmap.yaml          # Shared configuration
│   ├── secrets.yaml            # Secret templates
│   ├── postgres/               # PostgreSQL StatefulSet
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   ├── redis/                  # Redis Deployment
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── fe-nextjs/              # Frontend
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── be-api-gin/             # API Gateway
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── svc-user-django/        # User Service
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── svc-listing-spring/     # Listing Service
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── svc-inventory-rails/    # Inventory Service
│       ├── deployment.yaml
│       └── service.yaml
└── scripts/
    ├── setup-minikube.sh       # Setup script
    └── teardown.sh             # Cleanup script
```

## Configuration

### Environment Variables

Configuration is managed through:
1. **ConfigMap** (`k8s/configmap.yaml`): Non-sensitive shared configuration
2. **Secrets** (`k8s/secrets.yaml`): Sensitive data (passwords, keys)

To customize:

```bash
# Edit configmap
kubectl edit configmap ecommerce-config -n ecommerce

# Edit secrets (base64 encoded)
kubectl edit secret ecommerce-secrets -n ecommerce
```

### Resource Limits

Default resource limits for local development:

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Frontend | 100m | 500m | 128Mi | 512Mi |
| API Gateway | 100m | 500m | 128Mi | 256Mi |
| User Service | 200m | 1000m | 256Mi | 512Mi |
| Listing Service | 200m | 1000m | 512Mi | 1Gi |
| Inventory Service | 200m | 1000m | 256Mi | 512Mi |
| PostgreSQL | 250m | 1000m | 256Mi | 1Gi |
| Redis | 100m | 500m | 128Mi | 256Mi |

## Development Workflow

### Hot Reload with Skaffold

Skaffold watches for file changes and automatically rebuilds/redeploys:

```bash
# Start development mode
skaffold dev

# Changes to source code trigger automatic rebuild
```

### Hot Reload with Tilt

Tilt provides a web UI and faster rebuilds:

```bash
# Start Tilt
tilt up

# Open dashboard
open http://localhost:10350
```

### Manual Rebuild

```bash
# Rebuild specific service
make rebuild-fe-nextjs
make rebuild-be-api-gin

# Rebuild all
make rebuild
```

## Database Management

### Connect to PostgreSQL

```bash
# Port forward
kubectl port-forward svc/postgres 5432:5432 -n ecommerce

# Connect with psql
psql -h localhost -U postgres -d ecommerce
```

### Run Migrations

```bash
# Django migrations
kubectl exec -it deployment/svc-user-django -n ecommerce -- python manage.py migrate

# Rails migrations
kubectl exec -it deployment/svc-inventory-rails -n ecommerce -- rails db:migrate
```

### Database Reset

```bash
# Delete PVC and recreate
kubectl delete pvc postgres-pvc -n ecommerce
kubectl apply -f k8s/postgres/pvc.yaml
```

## Debugging

### View Logs

```bash
# All pods
kubectl logs -f -l app.kubernetes.io/part-of=ecommerce -n ecommerce

# Specific service
kubectl logs -f deployment/be-api-gin -n ecommerce

# Previous container (after crash)
kubectl logs deployment/svc-user-django -n ecommerce --previous
```

### Execute Commands in Pod

```bash
# Get shell access
kubectl exec -it deployment/be-api-gin -n ecommerce -- sh

# Run one-off command
kubectl exec deployment/svc-user-django -n ecommerce -- python manage.py shell
```

### Check Pod Status

```bash
# List pods
kubectl get pods -n ecommerce

# Describe pod for events
kubectl describe pod <pod-name> -n ecommerce

# Check resource usage
kubectl top pods -n ecommerce
```

## Troubleshooting

### Common Issues

#### Minikube Won't Start

```bash
# Clean up and restart
minikube delete
minikube start --cpus 4 --memory 8192 --disk-size 30g
```

#### Images Not Found

```bash
# Point Docker to Minikube's daemon
eval $(minikube docker-env)

# Rebuild images
make build-images
```

#### Pods Stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name> -n ecommerce

# Check node resources
kubectl describe node minikube
```

#### Services Not Communicating

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -n ecommerce -- nslookup postgres

# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n ecommerce -- wget -qO- http://be-api-gin:8080/health
```

#### Database Connection Refused

```bash
# Check PostgreSQL is running
kubectl get pods -n ecommerce -l app=postgres

# Check PostgreSQL logs
kubectl logs -l app=postgres -n ecommerce

# Verify secret is mounted
kubectl describe pod -l app=svc-user-django -n ecommerce
```

### Health Check Endpoints

| Service | Endpoint |
|---------|----------|
| API Gateway | `GET /health` |
| User Service | `GET /api/health/` |
| Listing Service | `GET /actuator/health` |
| Inventory Service | `GET /health` |

### Reset Everything

```bash
# Complete teardown
./scripts/teardown.sh

# Fresh start
./scripts/setup-minikube.sh
```

## Performance Tips

1. **Increase Minikube Resources**
   ```bash
   minikube config set cpus 4
   minikube config set memory 8192
   ```

2. **Use Local Registry**
   ```bash
   minikube addons enable registry
   ```

3. **Enable Caching**
   ```bash
   # Use buildkit for faster builds
   export DOCKER_BUILDKIT=1
   ```

4. **Parallel Builds**
   ```bash
   skaffold dev --cache-artifacts=true
   ```

## Additional Resources

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Skaffold Documentation](https://skaffold.dev/docs/)
- [Tilt Documentation](https://docs.tilt.dev/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
