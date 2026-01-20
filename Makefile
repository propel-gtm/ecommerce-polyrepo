# =============================================================================
# Ecommerce Polyrepo - Local Kubernetes Development Makefile
# =============================================================================

.PHONY: help start stop restart status logs build deploy clean \
        setup-minikube teardown port-forward \
        build-fe-nextjs build-be-api-gin build-svc-user-django \
        build-svc-listing-spring build-svc-inventory-rails \
        rebuild rebuild-fe-nextjs rebuild-be-api-gin rebuild-svc-user-django \
        rebuild-svc-listing-spring rebuild-svc-inventory-rails \
        shell-fe-nextjs shell-be-api-gin shell-svc-user-django \
        shell-svc-listing-spring shell-svc-inventory-rails \
        db-shell db-migrate db-reset \
        skaffold-dev skaffold-run tilt-up compose-up compose-down

# Default target
.DEFAULT_GOAL := help

# Variables
NAMESPACE := ecommerce
POLYREPO_DIR := $(shell dirname $(CURDIR))
KUBECTL := kubectl -n $(NAMESPACE)

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# =============================================================================
# Help
# =============================================================================

help: ## Show this help message
	@echo ""
	@echo "Ecommerce Polyrepo - Local Kubernetes Development"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Minikube Management
# =============================================================================

setup-minikube: ## One-click setup with Minikube
	@chmod +x scripts/setup-minikube.sh
	@./scripts/setup-minikube.sh

teardown: ## Teardown the entire environment
	@chmod +x scripts/teardown.sh
	@./scripts/teardown.sh

start: ## Start Minikube if stopped
	@echo "$(GREEN)Starting Minikube...$(NC)"
	@minikube start
	@echo "$(GREEN)Minikube started!$(NC)"

stop: ## Stop Minikube
	@echo "$(YELLOW)Stopping Minikube...$(NC)"
	@minikube stop
	@echo "$(YELLOW)Minikube stopped!$(NC)"

restart: stop start ## Restart Minikube

status: ## Show cluster and pod status
	@echo "$(BLUE)=== Minikube Status ===$(NC)"
	@minikube status || true
	@echo ""
	@echo "$(BLUE)=== Pods ===$(NC)"
	@$(KUBECTL) get pods -o wide || true
	@echo ""
	@echo "$(BLUE)=== Services ===$(NC)"
	@$(KUBECTL) get services || true
	@echo ""
	@echo "$(BLUE)=== Ingress ===$(NC)"
	@$(KUBECTL) get ingress || true

# =============================================================================
# Build Images
# =============================================================================

build: build-fe-nextjs build-be-api-gin build-svc-user-django build-svc-listing-spring build-svc-inventory-rails ## Build all Docker images

build-fe-nextjs: ## Build frontend image
	@echo "$(BLUE)Building fe-nextjs...$(NC)"
	@eval $$(minikube docker-env) && docker build -t ecommerce/fe-nextjs:latest $(POLYREPO_DIR)/fe-nextjs

build-be-api-gin: ## Build API gateway image
	@echo "$(BLUE)Building be-api-gin...$(NC)"
	@eval $$(minikube docker-env) && docker build -t ecommerce/be-api-gin:latest $(POLYREPO_DIR)/be-api-gin

build-svc-user-django: ## Build user service image
	@echo "$(BLUE)Building svc-user-django...$(NC)"
	@eval $$(minikube docker-env) && docker build -t ecommerce/svc-user-django:latest $(POLYREPO_DIR)/svc-user-django

build-svc-listing-spring: ## Build listing service image
	@echo "$(BLUE)Building svc-listing-spring...$(NC)"
	@eval $$(minikube docker-env) && docker build -t ecommerce/svc-listing-spring:latest $(POLYREPO_DIR)/svc-listing-spring

build-svc-inventory-rails: ## Build inventory service image
	@echo "$(BLUE)Building svc-inventory-rails...$(NC)"
	@eval $$(minikube docker-env) && docker build -t ecommerce/svc-inventory-rails:latest $(POLYREPO_DIR)/svc-inventory-rails

# =============================================================================
# Deploy
# =============================================================================

deploy: ## Deploy all resources to Kubernetes
	@echo "$(BLUE)Deploying all resources...$(NC)"
	@$(KUBECTL) apply -f k8s/namespace.yaml
	@$(KUBECTL) apply -f k8s/configmap.yaml
	@$(KUBECTL) apply -f k8s/secrets.yaml
	@$(KUBECTL) apply -f k8s/postgres/
	@$(KUBECTL) apply -f k8s/redis/
	@sleep 10
	@$(KUBECTL) apply -f k8s/svc-user-django/
	@$(KUBECTL) apply -f k8s/svc-listing-spring/
	@$(KUBECTL) apply -f k8s/svc-inventory-rails/
	@$(KUBECTL) apply -f k8s/be-api-gin/
	@$(KUBECTL) apply -f k8s/fe-nextjs/
	@echo "$(GREEN)Deployment complete!$(NC)"

# =============================================================================
# Rebuild (Build + Rolling Restart)
# =============================================================================

rebuild: build ## Rebuild all images and restart deployments
	@echo "$(BLUE)Restarting all deployments...$(NC)"
	@$(KUBECTL) rollout restart deployment

rebuild-fe-nextjs: build-fe-nextjs ## Rebuild and restart frontend
	@$(KUBECTL) rollout restart deployment/fe-nextjs

rebuild-be-api-gin: build-be-api-gin ## Rebuild and restart API gateway
	@$(KUBECTL) rollout restart deployment/be-api-gin

rebuild-svc-user-django: build-svc-user-django ## Rebuild and restart user service
	@$(KUBECTL) rollout restart deployment/svc-user-django

rebuild-svc-listing-spring: build-svc-listing-spring ## Rebuild and restart listing service
	@$(KUBECTL) rollout restart deployment/svc-listing-spring

rebuild-svc-inventory-rails: build-svc-inventory-rails ## Rebuild and restart inventory service
	@$(KUBECTL) rollout restart deployment/svc-inventory-rails

# =============================================================================
# Logs
# =============================================================================

logs: ## Show logs for all pods
	@$(KUBECTL) logs -f -l app.kubernetes.io/part-of=ecommerce --max-log-requests=10

logs-fe-nextjs: ## Show frontend logs
	@$(KUBECTL) logs -f deployment/fe-nextjs

logs-be-api-gin: ## Show API gateway logs
	@$(KUBECTL) logs -f deployment/be-api-gin

logs-svc-user-django: ## Show user service logs
	@$(KUBECTL) logs -f deployment/svc-user-django

logs-svc-listing-spring: ## Show listing service logs
	@$(KUBECTL) logs -f deployment/svc-listing-spring

logs-svc-inventory-rails: ## Show inventory service logs
	@$(KUBECTL) logs -f deployment/svc-inventory-rails

logs-postgres: ## Show PostgreSQL logs
	@$(KUBECTL) logs -f -l app=postgres

logs-redis: ## Show Redis logs
	@$(KUBECTL) logs -f deployment/redis

# =============================================================================
# Shell Access
# =============================================================================

shell-fe-nextjs: ## Open shell in frontend pod
	@$(KUBECTL) exec -it deployment/fe-nextjs -- sh

shell-be-api-gin: ## Open shell in API gateway pod
	@$(KUBECTL) exec -it deployment/be-api-gin -- sh

shell-svc-user-django: ## Open shell in user service pod
	@$(KUBECTL) exec -it deployment/svc-user-django -- bash

shell-svc-listing-spring: ## Open shell in listing service pod
	@$(KUBECTL) exec -it deployment/svc-listing-spring -- sh

shell-svc-inventory-rails: ## Open shell in inventory service pod
	@$(KUBECTL) exec -it deployment/svc-inventory-rails -- bash

# =============================================================================
# Database
# =============================================================================

db-shell: ## Open PostgreSQL shell
	@$(KUBECTL) exec -it postgres-0 -- psql -U postgres -d ecommerce

db-migrate: ## Run database migrations for all services
	@echo "$(BLUE)Running Django migrations...$(NC)"
	@$(KUBECTL) exec deployment/svc-user-django -- python manage.py migrate
	@echo "$(BLUE)Running Rails migrations...$(NC)"
	@$(KUBECTL) exec deployment/svc-inventory-rails -- rails db:migrate

db-reset: ## Reset all databases (DESTRUCTIVE)
	@echo "$(YELLOW)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? (y/n) " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(KUBECTL) delete pvc --all; \
		$(KUBECTL) delete statefulset postgres; \
		$(KUBECTL) apply -f k8s/postgres/; \
	fi

# =============================================================================
# Port Forwarding
# =============================================================================

port-forward: ## Start port forwarding for all services
	@echo "$(BLUE)Starting port forwarding...$(NC)"
	@pkill -f "kubectl port-forward" 2>/dev/null || true
	@$(KUBECTL) port-forward svc/fe-nextjs 3000:3000 &
	@$(KUBECTL) port-forward svc/be-api-gin 8080:8080 &
	@$(KUBECTL) port-forward svc/postgres 5432:5432 &
	@$(KUBECTL) port-forward svc/redis 6379:6379 &
	@echo "$(GREEN)Port forwarding started!$(NC)"
	@echo "  Frontend:    http://localhost:3000"
	@echo "  API Gateway: http://localhost:8080"
	@echo "  PostgreSQL:  localhost:5432"
	@echo "  Redis:       localhost:6379"

port-forward-stop: ## Stop all port forwarding
	@pkill -f "kubectl port-forward" 2>/dev/null || true
	@echo "$(YELLOW)Port forwarding stopped$(NC)"

# =============================================================================
# Skaffold
# =============================================================================

skaffold-dev: ## Start Skaffold in dev mode (hot reload)
	@skaffold dev --port-forward

skaffold-run: ## Build and deploy with Skaffold
	@skaffold run

skaffold-delete: ## Delete Skaffold deployments
	@skaffold delete

# =============================================================================
# Tilt
# =============================================================================

tilt-up: ## Start Tilt for live development
	@tilt up

tilt-down: ## Stop Tilt
	@tilt down

# =============================================================================
# Docker Compose (Alternative)
# =============================================================================

compose-up: ## Start services with Docker Compose
	@docker-compose up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo "  Frontend:    http://localhost:3000"
	@echo "  API Gateway: http://localhost:8080"

compose-down: ## Stop Docker Compose services
	@docker-compose down

compose-logs: ## Show Docker Compose logs
	@docker-compose logs -f

compose-ps: ## Show Docker Compose status
	@docker-compose ps

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Clean up resources (keep Minikube running)
	@echo "$(YELLOW)Cleaning up resources...$(NC)"
	@$(KUBECTL) delete deployment --all || true
	@$(KUBECTL) delete service --all || true
	@$(KUBECTL) delete configmap --all || true
	@$(KUBECTL) delete secret --all || true
	@$(KUBECTL) delete pvc --all || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-images: ## Remove all ecommerce Docker images
	@eval $$(minikube docker-env) && \
		docker rmi ecommerce/fe-nextjs:latest 2>/dev/null || true && \
		docker rmi ecommerce/be-api-gin:latest 2>/dev/null || true && \
		docker rmi ecommerce/svc-user-django:latest 2>/dev/null || true && \
		docker rmi ecommerce/svc-listing-spring:latest 2>/dev/null || true && \
		docker rmi ecommerce/svc-inventory-rails:latest 2>/dev/null || true
	@echo "$(GREEN)Images removed!$(NC)"

# =============================================================================
# Utilities
# =============================================================================

dashboard: ## Open Minikube dashboard
	@minikube dashboard

tunnel: ## Start Minikube tunnel for LoadBalancer services
	@minikube tunnel

ip: ## Show Minikube IP
	@minikube ip

events: ## Show Kubernetes events
	@$(KUBECTL) get events --sort-by='.lastTimestamp'

describe-pods: ## Describe all pods
	@$(KUBECTL) describe pods

top: ## Show resource usage
	@$(KUBECTL) top pods 2>/dev/null || echo "Metrics server not available"
