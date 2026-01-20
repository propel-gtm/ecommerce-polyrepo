# E-Commerce Polyrepo

This is the parent repository that links all microservices and infrastructure components as git submodules.

## Architecture

This e-commerce platform consists of the following components:

### Services
- **be-api-gin**: Backend API Gateway built with Go and Gin framework
- **svc-user-django**: User service built with Django
- **svc-inventory-rails**: Inventory service built with Ruby on Rails
- **svc-listing-spring**: Listing service built with Spring Boot

### Frontend
- **fe-nextjs**: Frontend application built with Next.js

### Infrastructure
- **infra-terraform-eks**: Infrastructure as Code using Terraform for EKS
- **local-k8s**: Local Kubernetes configuration and setup

### Shared
- **proto-schemas**: Protocol buffer schemas and definitions

## Git Submodule Structure

Each component is maintained as an independent repository and linked here as a git submodule:

- `be-api-gin/` → https://github.com/propel-gtm/be-api-gin
- `fe-nextjs/` → https://github.com/propel-gtm/fe-nextjs
- `infra-terraform-eks/` → https://github.com/propel-gtm/infra-terraform-eks
- `local-k8s/` → https://github.com/propel-gtm/local-k8s
- `proto-schemas/` → https://github.com/propel-gtm/proto-schemas
- `svc-inventory-rails/` → https://github.com/propel-gtm/svc-inventory-rails
- `svc-listing-spring/` → https://github.com/propel-gtm/svc-listing-spring
- `svc-user-django/` → https://github.com/propel-gtm/svc-user-django

## Getting Started

### Clone the repository with all submodules
```bash
git clone --recursive https://github.com/propel-gtm/ecommerce-polyrepo.git
```

Or if you already cloned it without submodules:
```bash
git submodule update --init --recursive
```

## Working with Submodules

### Update all submodules to latest commits
```bash
git submodule update --remote
```

### Update a specific submodule
```bash
git submodule update --remote be-api-gin
```

### Pull latest changes from all submodules
```bash
git pull --recurse-submodules
```

### Making changes in a submodule

1. Navigate to the submodule directory:
```bash
cd be-api-gin
```

2. Make your changes and commit them:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

3. Update the parent repo to point to the new commit:
```bash
cd ..
git add be-api-gin
git commit -m "Update be-api-gin submodule"
git push
```

### Clone a specific submodule only
If you only want to work on a specific component, you can clone its individual repository:
```bash
git clone https://github.com/propel-gtm/be-api-gin.git
```

## Benefits of Submodules

- **Independent Development**: Each service can be developed, tested, and deployed independently
- **Version Control**: Parent repo tracks specific commits of each submodule
- **Flexible Workflows**: Work on individual repos or the full system
- **Clean Separation**: Clear boundaries between components
