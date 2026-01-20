#!/bin/bash

# =============================================================================
# Ecommerce Polyrepo - Minikube Setup Script
# =============================================================================
# This script sets up a complete local Kubernetes development environment
# for the ecommerce polyrepo using Minikube.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MINIKUBE_CPUS=${MINIKUBE_CPUS:-4}
MINIKUBE_MEMORY=${MINIKUBE_MEMORY:-8192}
MINIKUBE_DISK=${MINIKUBE_DISK:-30g}
MINIKUBE_DRIVER=${MINIKUBE_DRIVER:-docker}
NAMESPACE="ecommerce"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
POLYREPO_DIR="$(dirname "$PROJECT_DIR")"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        return 1
    fi
    log_success "$1 is installed"
}

wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    local start_time=$(date +%s)

    log_info "Waiting for all pods in namespace '$namespace' to be ready..."

    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $timeout ]; then
            log_error "Timeout waiting for pods to be ready"
            kubectl get pods -n "$namespace"
            return 1
        fi

        # Check if all pods are ready
        local not_ready=$(kubectl get pods -n "$namespace" -o json 2>/dev/null | \
            jq -r '.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | .metadata.name' | wc -l)

        if [ "$not_ready" -eq 0 ]; then
            local total=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | wc -l)
            if [ "$total" -gt 0 ]; then
                log_success "All pods are ready!"
                return 0
            fi
        fi

        echo -ne "\r  Elapsed: ${elapsed}s / ${timeout}s - Pods not ready: $not_ready"
        sleep 5
    done
}

# -----------------------------------------------------------------------------
# Pre-flight Checks
# -----------------------------------------------------------------------------

preflight_checks() {
    log_info "Running pre-flight checks..."

    check_command "docker" || exit 1
    check_command "minikube" || exit 1
    check_command "kubectl" || exit 1

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    log_success "Docker is running"

    log_success "All pre-flight checks passed!"
}

# -----------------------------------------------------------------------------
# Start Minikube
# -----------------------------------------------------------------------------

start_minikube() {
    log_info "Starting Minikube with $MINIKUBE_CPUS CPUs, ${MINIKUBE_MEMORY}MB memory, $MINIKUBE_DISK disk..."

    # Check if Minikube is already running
    if minikube status &> /dev/null; then
        log_warn "Minikube is already running. Checking configuration..."

        # Get current resources
        local current_cpus=$(minikube config get cpus 2>/dev/null || echo "unknown")
        local current_memory=$(minikube config get memory 2>/dev/null || echo "unknown")

        log_info "Current Minikube configuration: CPUs=$current_cpus, Memory=$current_memory"
        log_info "Using existing Minikube instance..."
    else
        # Start Minikube with specified resources
        minikube start \
            --driver="$MINIKUBE_DRIVER" \
            --cpus="$MINIKUBE_CPUS" \
            --memory="$MINIKUBE_MEMORY" \
            --disk-size="$MINIKUBE_DISK" \
            --kubernetes-version=stable \
            --addons=default-storageclass,storage-provisioner

        log_success "Minikube started successfully!"
    fi

    # Enable required addons
    log_info "Enabling required addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    minikube addons enable dashboard

    log_success "Minikube addons enabled!"
}

# -----------------------------------------------------------------------------
# Configure Docker Environment
# -----------------------------------------------------------------------------

configure_docker_env() {
    log_info "Configuring Docker environment to use Minikube's Docker daemon..."

    # This allows building images directly in Minikube's Docker
    eval $(minikube docker-env)

    log_success "Docker environment configured!"
}

# -----------------------------------------------------------------------------
# Build Docker Images
# -----------------------------------------------------------------------------

build_images() {
    log_info "Building Docker images..."

    cd "$POLYREPO_DIR"

    # Build each service image
    local services=(
        "fe-nextjs"
        "be-api-gin"
        "svc-user-django"
        "svc-listing-spring"
        "svc-inventory-rails"
    )

    for service in "${services[@]}"; do
        log_info "Building $service..."
        if [ -f "$service/Dockerfile" ]; then
            docker build -t "ecommerce/$service:latest" "$service/"
            log_success "Built ecommerce/$service:latest"
        else
            log_warn "No Dockerfile found for $service, skipping..."
        fi
    done

    log_success "All images built successfully!"
}

# -----------------------------------------------------------------------------
# Deploy to Kubernetes
# -----------------------------------------------------------------------------

deploy_kubernetes() {
    log_info "Deploying to Kubernetes..."

    cd "$PROJECT_DIR"

    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml

    # Apply ConfigMaps and Secrets
    log_info "Applying ConfigMaps and Secrets..."
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secrets.yaml

    # Deploy infrastructure
    log_info "Deploying PostgreSQL..."
    kubectl apply -f k8s/postgres/

    log_info "Deploying Redis..."
    kubectl apply -f k8s/redis/

    # Wait for infrastructure to be ready
    log_info "Waiting for infrastructure to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=redis -n "$NAMESPACE" --timeout=60s || true

    # Deploy services
    log_info "Deploying application services..."
    kubectl apply -f k8s/svc-user-django/
    kubectl apply -f k8s/svc-listing-spring/
    kubectl apply -f k8s/svc-inventory-rails/
    kubectl apply -f k8s/be-api-gin/
    kubectl apply -f k8s/fe-nextjs/

    log_success "All resources deployed!"
}

# -----------------------------------------------------------------------------
# Setup Port Forwarding
# -----------------------------------------------------------------------------

setup_port_forwarding() {
    log_info "Setting up port forwarding..."

    # Kill any existing port-forward processes
    pkill -f "kubectl port-forward" 2>/dev/null || true

    # Start port forwarding in background
    kubectl port-forward svc/fe-nextjs 3000:3000 -n "$NAMESPACE" &
    kubectl port-forward svc/be-api-gin 8080:8080 -n "$NAMESPACE" &
    kubectl port-forward svc/postgres 5432:5432 -n "$NAMESPACE" &
    kubectl port-forward svc/redis 6379:6379 -n "$NAMESPACE" &

    log_success "Port forwarding set up!"
    log_info "Access points:"
    echo "  - Frontend:    http://localhost:3000"
    echo "  - API Gateway: http://localhost:8080"
    echo "  - PostgreSQL:  localhost:5432"
    echo "  - Redis:       localhost:6379"
}

# -----------------------------------------------------------------------------
# Show Status
# -----------------------------------------------------------------------------

show_status() {
    log_info "Current deployment status:"

    echo ""
    echo "=== Pods ==="
    kubectl get pods -n "$NAMESPACE" -o wide

    echo ""
    echo "=== Services ==="
    kubectl get services -n "$NAMESPACE"

    echo ""
    echo "=== Ingress ==="
    kubectl get ingress -n "$NAMESPACE"

    echo ""
    log_info "Minikube IP: $(minikube ip)"

    echo ""
    log_success "Setup complete!"
    echo ""
    echo "To access services via Ingress, add the following to /etc/hosts:"
    echo "  $(minikube ip) ecommerce.local api.ecommerce.local"
    echo ""
    echo "Or start minikube tunnel in another terminal:"
    echo "  minikube tunnel"
    echo ""
    echo "Then access:"
    echo "  - Frontend: http://ecommerce.local"
    echo "  - API:      http://api.ecommerce.local"
    echo ""
    echo "Useful commands:"
    echo "  - View logs:     kubectl logs -f deployment/<name> -n ecommerce"
    echo "  - Open dashboard: minikube dashboard"
    echo "  - Teardown:      ./scripts/teardown.sh"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    echo ""
    echo "=============================================="
    echo "  Ecommerce Polyrepo - Minikube Setup"
    echo "=============================================="
    echo ""

    preflight_checks
    start_minikube
    configure_docker_env
    build_images
    deploy_kubernetes

    # Wait for pods to be ready
    wait_for_pods "$NAMESPACE" 300

    # Optionally set up port forwarding
    read -p "Do you want to set up port forwarding? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_port_forwarding
    fi

    show_status
}

# Run main function
main "$@"
