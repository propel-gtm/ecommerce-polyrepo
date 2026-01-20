#!/bin/bash

# =============================================================================
# Ecommerce Polyrepo - Teardown Script
# =============================================================================
# This script tears down the local Kubernetes development environment.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="ecommerce"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

# -----------------------------------------------------------------------------
# Kill Port Forwarding
# -----------------------------------------------------------------------------

kill_port_forwarding() {
    log_info "Stopping port forwarding processes..."
    pkill -f "kubectl port-forward" 2>/dev/null || true
    log_success "Port forwarding stopped"
}

# -----------------------------------------------------------------------------
# Delete Kubernetes Resources
# -----------------------------------------------------------------------------

delete_kubernetes_resources() {
    log_info "Deleting Kubernetes resources..."

    cd "$PROJECT_DIR"

    # Delete application deployments
    log_info "Deleting application services..."
    kubectl delete -f k8s/fe-nextjs/ --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f k8s/be-api-gin/ --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f k8s/svc-user-django/ --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f k8s/svc-listing-spring/ --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f k8s/svc-inventory-rails/ --ignore-not-found=true 2>/dev/null || true

    # Delete infrastructure
    log_info "Deleting infrastructure..."
    kubectl delete -f k8s/redis/ --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f k8s/postgres/ --ignore-not-found=true 2>/dev/null || true

    # Delete ConfigMaps and Secrets
    log_info "Deleting ConfigMaps and Secrets..."
    kubectl delete -f k8s/secrets.yaml --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f k8s/configmap.yaml --ignore-not-found=true 2>/dev/null || true

    log_success "Kubernetes resources deleted"
}

# -----------------------------------------------------------------------------
# Delete Namespace
# -----------------------------------------------------------------------------

delete_namespace() {
    log_info "Deleting namespace '$NAMESPACE'..."

    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl delete namespace "$NAMESPACE" --wait=true --timeout=120s
        log_success "Namespace deleted"
    else
        log_warn "Namespace '$NAMESPACE' does not exist"
    fi
}

# -----------------------------------------------------------------------------
# Clean Docker Images
# -----------------------------------------------------------------------------

clean_docker_images() {
    log_info "Cleaning Docker images..."

    # Check if we should use Minikube's Docker
    if minikube status &> /dev/null; then
        eval $(minikube docker-env)
    fi

    # Remove ecommerce images
    local images=(
        "ecommerce/fe-nextjs"
        "ecommerce/be-api-gin"
        "ecommerce/svc-user-django"
        "ecommerce/svc-listing-spring"
        "ecommerce/svc-inventory-rails"
    )

    for image in "${images[@]}"; do
        if docker images | grep -q "$image"; then
            docker rmi "$image:latest" 2>/dev/null || true
            log_info "Removed $image"
        fi
    done

    # Prune dangling images
    docker image prune -f 2>/dev/null || true

    log_success "Docker images cleaned"
}

# -----------------------------------------------------------------------------
# Stop Minikube (Optional)
# -----------------------------------------------------------------------------

stop_minikube() {
    read -p "Do you want to stop Minikube? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Stopping Minikube..."
        minikube stop
        log_success "Minikube stopped"
    else
        log_info "Minikube left running"
    fi
}

# -----------------------------------------------------------------------------
# Delete Minikube (Optional)
# -----------------------------------------------------------------------------

delete_minikube() {
    read -p "Do you want to DELETE Minikube completely? This will remove all data. (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Deleting Minikube cluster..."
        minikube delete
        log_success "Minikube deleted"
    else
        log_info "Minikube cluster preserved"
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    echo ""
    echo "=============================================="
    echo "  Ecommerce Polyrepo - Teardown"
    echo "=============================================="
    echo ""

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi

    # Check if minikube is available and running
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        log_info "Minikube is running"
    else
        log_warn "Minikube is not running or not installed"
    fi

    kill_port_forwarding
    delete_kubernetes_resources
    delete_namespace

    read -p "Do you want to clean Docker images? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean_docker_images
    fi

    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        stop_minikube
        delete_minikube
    fi

    echo ""
    log_success "Teardown complete!"
    echo ""
}

# Run main function
main "$@"
