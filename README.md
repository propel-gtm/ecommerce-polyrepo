# E-Commerce Polyrepo

This is the parent repository that links all microservices and infrastructure components as git subtrees.

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

## Git Subtree Structure

Each component is maintained as an independent repository and linked here as a git subtree:

- `be-api-gin/` → https://github.com/propel-gtm/be-api-gin
- `fe-nextjs/` → https://github.com/propel-gtm/fe-nextjs
- `infra-terraform-eks/` → https://github.com/propel-gtm/infra-terraform-eks
- `local-k8s/` → https://github.com/propel-gtm/local-k8s
- `proto-schemas/` → https://github.com/propel-gtm/proto-schemas
- `svc-inventory-rails/` → https://github.com/propel-gtm/svc-inventory-rails
- `svc-listing-spring/` → https://github.com/propel-gtm/svc-listing-spring
- `svc-user-django/` → https://github.com/propel-gtm/svc-user-django

## Working with Subtrees

### Pull updates from a subtree
\`\`\`bash
git subtree pull --prefix=<directory> <remote-url> main --squash
\`\`\`

### Push changes to a subtree
\`\`\`bash
git subtree push --prefix=<directory> <remote-url> main
\`\`\`

### Example: Pull updates from be-api-gin
\`\`\`bash
git subtree pull --prefix=be-api-gin https://github.com/propel-gtm/be-api-gin.git main --squash
\`\`\`

### Example: Push changes to fe-nextjs
\`\`\`bash
git subtree push --prefix=fe-nextjs https://github.com/propel-gtm/fe-nextjs.git main
\`\`\`
