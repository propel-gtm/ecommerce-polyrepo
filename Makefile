.PHONY: help start stop restart status deploy build clean logs shell db-migrate db-seed port-forward

# Variables
NAMESPACE := ecommerce
SKAFFOLD_DIR := local-k8s

# Color output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Stack Management

start: ## Start all services with Skaffold
	@echo "$(GREEN)Starting all services...$(NC)"
	cd $(SKAFFOLD_DIR) && skaffold dev --port-forward

start-detached: ## Start all services in background
	@echo "$(GREEN)Starting all services in background...$(NC)"
	cd $(SKAFFOLD_DIR) && skaffold run --port-forward &

stop: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	cd $(SKAFFOLD_DIR) && skaffold delete

restart: stop start ## Restart all services

status: ## Show status of all services
	@echo "$(GREEN)Service Status:$(NC)"
	@kubectl get pods -n $(NAMESPACE)
	@echo "\n$(GREEN)Services:$(NC)"
	@kubectl get svc -n $(NAMESPACE)

deploy: ## Deploy all services to minikube
	@echo "$(GREEN)Deploying all services...$(NC)"
	cd $(SKAFFOLD_DIR) && skaffold run

##@ Individual Service Management

restart-frontend: ## Restart frontend (Next.js)
	@echo "$(YELLOW)Restarting fe-nextjs...$(NC)"
	kubectl rollout restart deployment/fe-nextjs -n $(NAMESPACE)
	kubectl rollout status deployment/fe-nextjs -n $(NAMESPACE)

restart-api: ## Restart API gateway (Gin)
	@echo "$(YELLOW)Restarting be-api-gin...$(NC)"
	kubectl rollout restart deployment/be-api-gin -n $(NAMESPACE)
	kubectl rollout status deployment/be-api-gin -n $(NAMESPACE)

restart-user: ## Restart user service (Django)
	@echo "$(YELLOW)Restarting svc-user-django...$(NC)"
	kubectl rollout restart deployment/svc-user-django -n $(NAMESPACE)
	kubectl rollout status deployment/svc-user-django -n $(NAMESPACE)

restart-listing: ## Restart listing service (Spring Boot)
	@echo "$(YELLOW)Restarting svc-listing-spring...$(NC)"
	kubectl rollout restart deployment/svc-listing-spring -n $(NAMESPACE)
	kubectl rollout status deployment/svc-listing-spring -n $(NAMESPACE)

restart-inventory: ## Restart inventory service (Rails)
	@echo "$(YELLOW)Restarting svc-inventory-rails...$(NC)"
	kubectl rollout restart deployment/svc-inventory-rails -n $(NAMESPACE)
	kubectl rollout status deployment/svc-inventory-rails -n $(NAMESPACE)

restart-postgres: ## Restart PostgreSQL
	@echo "$(YELLOW)Restarting postgres...$(NC)"
	kubectl rollout restart statefulset/postgres -n $(NAMESPACE)
	kubectl rollout status statefulset/postgres -n $(NAMESPACE)

restart-redis: ## Restart Redis
	@echo "$(YELLOW)Restarting redis...$(NC)"
	kubectl rollout restart deployment/redis -n $(NAMESPACE)
	kubectl rollout status deployment/redis -n $(NAMESPACE)

##@ Build Commands

build-all: ## Build all service images
	@echo "$(GREEN)Building all images...$(NC)"
	cd $(SKAFFOLD_DIR) && skaffold build --cache-artifacts=false

build-frontend: ## Build frontend image only
	@echo "$(GREEN)Building fe-nextjs...$(NC)"
	cd fe-nextjs && docker build -t ecommerce/fe-nextjs:latest .

build-api: ## Build API gateway image only
	@echo "$(GREEN)Building be-api-gin...$(NC)"
	cd be-api-gin && docker build -t ecommerce/be-api-gin:latest .

build-user: ## Build user service image only
	@echo "$(GREEN)Building svc-user-django...$(NC)"
	cd svc-user-django && docker build -t ecommerce/svc-user-django:latest .

build-listing: ## Build listing service image only
	@echo "$(GREEN)Building svc-listing-spring...$(NC)"
	cd svc-listing-spring && docker build -t ecommerce/svc-listing-spring:latest .

build-inventory: ## Build inventory service image only
	@echo "$(GREEN)Building svc-inventory-rails...$(NC)"
	cd svc-inventory-rails && docker build -t ecommerce/svc-inventory-rails:latest .

##@ Database Operations

db-migrate: ## Run database migrations for all services
	@echo "$(GREEN)Running migrations...$(NC)"
	@echo "$(YELLOW)Django migrations...$(NC)"
	kubectl exec -n $(NAMESPACE) deployment/svc-user-django -- python manage.py migrate
	@echo "$(YELLOW)Rails migrations...$(NC)"
	kubectl exec -n $(NAMESPACE) deployment/svc-inventory-rails -- rails db:migrate

db-migrate-user: ## Run Django migrations only
	@echo "$(GREEN)Running Django migrations...$(NC)"
	kubectl exec -n $(NAMESPACE) deployment/svc-user-django -- python manage.py migrate

db-migrate-inventory: ## Run Rails migrations only
	@echo "$(GREEN)Running Rails migrations...$(NC)"
	kubectl exec -n $(NAMESPACE) deployment/svc-inventory-rails -- rails db:migrate

db-seed: ## Seed databases with initial data
	@echo "$(GREEN)Seeding databases...$(NC)"
	kubectl exec -n $(NAMESPACE) deployment/svc-user-django -- python manage.py loaddata initial_data || true
	kubectl exec -n $(NAMESPACE) deployment/svc-inventory-rails -- rails db:seed || true

db-reset: ## Reset all databases (DANGEROUS!)
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		kubectl exec -n $(NAMESPACE) deployment/svc-user-django -- python manage.py flush --no-input; \
		kubectl exec -n $(NAMESPACE) deployment/svc-inventory-rails -- rails db:reset; \
	fi

##@ Logs & Debugging

logs-frontend: ## Show frontend logs
	kubectl logs -n $(NAMESPACE) -l app=fe-nextjs --tail=100 -f

logs-api: ## Show API gateway logs
	kubectl logs -n $(NAMESPACE) -l app=be-api-gin --tail=100 -f

logs-user: ## Show user service logs
	kubectl logs -n $(NAMESPACE) -l app=svc-user-django --tail=100 -f

logs-listing: ## Show listing service logs
	kubectl logs -n $(NAMESPACE) -l app=svc-listing-spring --tail=100 -f

logs-inventory: ## Show inventory service logs
	kubectl logs -n $(NAMESPACE) -l app=svc-inventory-rails --tail=100 -f

logs-postgres: ## Show PostgreSQL logs
	kubectl logs -n $(NAMESPACE) -l app=postgres --tail=100 -f

logs-redis: ## Show Redis logs
	kubectl logs -n $(NAMESPACE) -l app=redis --tail=100 -f

logs-all: ## Show logs from all services
	kubectl logs -n $(NAMESPACE) --all-containers=true --tail=50 -f

##@ Shell Access

shell-frontend: ## Open shell in frontend container
	kubectl exec -it -n $(NAMESPACE) deployment/fe-nextjs -- /bin/sh

shell-api: ## Open shell in API gateway container
	kubectl exec -it -n $(NAMESPACE) deployment/be-api-gin -- /bin/sh

shell-user: ## Open shell in user service container
	kubectl exec -it -n $(NAMESPACE) deployment/svc-user-django -- /bin/bash

shell-listing: ## Open shell in listing service container
	kubectl exec -it -n $(NAMESPACE) deployment/svc-listing-spring -- /bin/bash

shell-inventory: ## Open shell in inventory service container
	kubectl exec -it -n $(NAMESPACE) deployment/svc-inventory-rails -- /bin/bash

shell-postgres: ## Open PostgreSQL shell
	kubectl exec -it -n $(NAMESPACE) statefulset/postgres -- psql -U postgres

shell-redis: ## Open Redis CLI
	kubectl exec -it -n $(NAMESPACE) deployment/redis -- redis-cli

##@ Port Forwarding

port-forward: ## Set up port forwarding for all services
	@echo "$(GREEN)Setting up port forwarding...$(NC)"
	@echo "Frontend: http://localhost:3000"
	@echo "API Gateway: http://localhost:8080"
	@echo "User Service: http://localhost:8001"
	@echo "Listing Service: http://localhost:8082"
	@echo "Inventory Service: http://localhost:3001"
	@kubectl port-forward -n $(NAMESPACE) svc/fe-nextjs 3000:3000 & \
	kubectl port-forward -n $(NAMESPACE) svc/be-api-gin 8080:8080 & \
	kubectl port-forward -n $(NAMESPACE) svc/svc-user-django 8001:8000 & \
	kubectl port-forward -n $(NAMESPACE) svc/svc-listing-spring 8082:8080 & \
	kubectl port-forward -n $(NAMESPACE) svc/svc-inventory-rails 3001:3000 & \
	kubectl port-forward -n $(NAMESPACE) svc/postgres 5432:5432 & \
	kubectl port-forward -n $(NAMESPACE) svc/redis 6379:6379

kill-port-forward: ## Kill all port forwarding processes
	@echo "$(YELLOW)Killing port forwarding processes...$(NC)"
	@pkill -f "kubectl port-forward" || true

##@ Cleanup & Maintenance

clean: ## Clean up everything
	@echo "$(RED)Cleaning up...$(NC)"
	cd $(SKAFFOLD_DIR) && skaffold delete
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true

clean-images: ## Remove all local images
	@echo "$(YELLOW)Removing local images...$(NC)"
	docker rmi ecommerce/fe-nextjs:latest || true
	docker rmi ecommerce/be-api-gin:latest || true
	docker rmi ecommerce/svc-user-django:latest || true
	docker rmi ecommerce/svc-listing-spring:latest || true
	docker rmi ecommerce/svc-inventory-rails:latest || true

describe-frontend: ## Describe frontend deployment
	kubectl describe deployment/fe-nextjs -n $(NAMESPACE)

describe-api: ## Describe API gateway deployment
	kubectl describe deployment/be-api-gin -n $(NAMESPACE)

describe-user: ## Describe user service deployment
	kubectl describe deployment/svc-user-django -n $(NAMESPACE)

describe-listing: ## Describe listing service deployment
	kubectl describe deployment/svc-listing-spring -n $(NAMESPACE)

describe-inventory: ## Describe inventory service deployment
	kubectl describe deployment/svc-inventory-rails -n $(NAMESPACE)

##@ Minikube Management

minikube-start: ## Start minikube
	@echo "$(GREEN)Starting minikube...$(NC)"
	minikube start

minikube-stop: ## Stop minikube
	@echo "$(YELLOW)Stopping minikube...$(NC)"
	minikube stop

minikube-delete: ## Delete minikube cluster
	@echo "$(RED)Deleting minikube cluster...$(NC)"
	minikube delete

minikube-dashboard: ## Open Kubernetes dashboard
	minikube dashboard

minikube-tunnel: ## Create minikube tunnel for LoadBalancer services
	@echo "$(GREEN)Creating minikube tunnel (requires sudo)...$(NC)"
	minikube tunnel

##@ Quick Commands

dev: ## Start development environment (alias for start)
	@$(MAKE) start

quick-restart: ## Quick restart of all application services (excludes DB/Redis)
	@echo "$(YELLOW)Quick restarting application services...$(NC)"
	@kubectl rollout restart deployment/fe-nextjs -n $(NAMESPACE)
	@kubectl rollout restart deployment/be-api-gin -n $(NAMESPACE)
	@kubectl rollout restart deployment/svc-user-django -n $(NAMESPACE)
	@kubectl rollout restart deployment/svc-listing-spring -n $(NAMESPACE)
	@kubectl rollout restart deployment/svc-inventory-rails -n $(NAMESPACE)
	@echo "$(GREEN)Waiting for rollouts to complete...$(NC)"
	@kubectl rollout status deployment/fe-nextjs -n $(NAMESPACE)
	@kubectl rollout status deployment/be-api-gin -n $(NAMESPACE)
	@kubectl rollout status deployment/svc-user-django -n $(NAMESPACE)
	@kubectl rollout status deployment/svc-listing-spring -n $(NAMESPACE)
	@kubectl rollout status deployment/svc-inventory-rails -n $(NAMESPACE)

ps: ## Show all running pods (alias for status)
	@$(MAKE) status

tail: logs-all ## Tail all logs (alias for logs-all)

list-services: ## List all service URLs and endpoints
	@MINIKUBE_IP=$$(minikube ip); \
	echo "====================================================================="; \
	echo "E-COMMERCE POLYREPO - SERVICE ENDPOINTS"; \
	echo "====================================================================="; \
	echo "Minikube IP: $$MINIKUBE_IP"; \
	echo ""; \
	echo "FRONTEND:"; \
	echo "  Next.js App:            http://$$MINIKUBE_IP:30300"; \
	echo ""; \
	echo "API GATEWAY (Go/Gin):"; \
	echo "  REST API:               http://$$MINIKUBE_IP:30080"; \
	echo "  Health Check:           http://$$MINIKUBE_IP:30080/health"; \
	echo ""; \
	echo "USER SERVICE (Django):"; \
	echo "  REST API:               http://$$MINIKUBE_IP:30801"; \
	echo "  gRPC:                   $$MINIKUBE_IP:30051"; \
	echo "  Health Check:           http://$$MINIKUBE_IP:30801/api/health/"; \
	echo ""; \
	echo "LISTING SERVICE (Spring Boot):"; \
	echo "  REST API:               http://$$MINIKUBE_IP:30802"; \
	echo "  gRPC:                   $$MINIKUBE_IP:30909"; \
	echo "  Health Check:           http://$$MINIKUBE_IP:30802/actuator/health"; \
	echo ""; \
	echo "INVENTORY SERVICE (Rails):"; \
	echo "  REST API:               http://$$MINIKUBE_IP:30301"; \
	echo "  gRPC:                   $$MINIKUBE_IP:30052"; \
	echo "  Health Check:           http://$$MINIKUBE_IP:30301/health"; \
	echo ""; \
	echo "POSTGRESQL DATABASE:"; \
	echo "  Connection:             $$MINIKUBE_IP:30543"; \
	echo "  Connection String:      postgresql://postgres:postgres@$$MINIKUBE_IP:30543/users"; \
	echo ""; \
	echo "====================================================================="; \
	echo "QUICK TEST:"; \
	echo "====================================================================="; \
	echo "curl http://$$MINIKUBE_IP:30080/health              # API Gateway"; \
	echo "curl http://$$MINIKUBE_IP:30801/api/health/         # User Service"; \
	echo "curl http://$$MINIKUBE_IP:30802/actuator/health     # Listing Service"; \
	echo "curl http://$$MINIKUBE_IP:30301/health              # Inventory Service"
