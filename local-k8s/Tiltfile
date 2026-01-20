# =============================================================================
# Ecommerce Polyrepo - Tiltfile
# =============================================================================
# This Tiltfile provides live development capabilities using Tilt.
# Tilt watches for file changes and automatically rebuilds/updates services.
# =============================================================================

# Configuration
config.define_string("namespace", args=True)
config.define_bool("no-volumes", args=True)
cfg = config.parse()

namespace = cfg.get("namespace", "ecommerce")

# Allow Kubernetes context
allow_k8s_contexts(["minikube", "docker-desktop", "kind-kind"])

# =============================================================================
# Namespace
# =============================================================================

k8s_yaml("k8s/namespace.yaml")

# =============================================================================
# ConfigMaps and Secrets
# =============================================================================

k8s_yaml("k8s/configmap.yaml")
k8s_yaml("k8s/secrets.yaml")

# =============================================================================
# Infrastructure
# =============================================================================

# PostgreSQL
k8s_yaml([
    "k8s/postgres/statefulset.yaml",
    "k8s/postgres/service.yaml",
])

k8s_resource(
    "postgres",
    labels=["infrastructure"],
    port_forwards=["5432:5432"],
    resource_deps=[],
)

# Redis
k8s_yaml([
    "k8s/redis/deployment.yaml",
    "k8s/redis/service.yaml",
])

k8s_resource(
    "redis",
    labels=["infrastructure"],
    port_forwards=["6379:6379"],
    resource_deps=[],
)

# =============================================================================
# Frontend - Next.js
# =============================================================================

docker_build(
    "ecommerce/fe-nextjs",
    "../fe-nextjs",
    dockerfile="../fe-nextjs/Dockerfile",
    live_update=[
        sync("../fe-nextjs/src", "/app/src"),
        sync("../fe-nextjs/public", "/app/public"),
        run(
            "cd /app && npm install",
            trigger=["../fe-nextjs/package.json", "../fe-nextjs/package-lock.json"],
        ),
    ],
)

k8s_yaml([
    "k8s/fe-nextjs/deployment.yaml",
    "k8s/fe-nextjs/service.yaml",
    "k8s/fe-nextjs/ingress.yaml",
])

k8s_resource(
    "fe-nextjs",
    labels=["frontend"],
    port_forwards=["3000:3000"],
    resource_deps=["be-api-gin"],
)

# =============================================================================
# API Gateway - Gin (Go)
# =============================================================================

docker_build(
    "ecommerce/be-api-gin",
    "../be-api-gin",
    dockerfile="../be-api-gin/Dockerfile",
    live_update=[
        sync("../be-api-gin", "/app"),
        run(
            "cd /app && go build -o server .",
            trigger=["../be-api-gin/**/*.go"],
        ),
    ],
)

k8s_yaml([
    "k8s/be-api-gin/deployment.yaml",
    "k8s/be-api-gin/service.yaml",
])

k8s_resource(
    "be-api-gin",
    labels=["backend"],
    port_forwards=["8080:8080"],
    resource_deps=["postgres", "redis", "svc-user-django", "svc-listing-spring", "svc-inventory-rails"],
)

# =============================================================================
# User Service - Django (Python)
# =============================================================================

docker_build(
    "ecommerce/svc-user-django",
    "../svc-user-django",
    dockerfile="../svc-user-django/Dockerfile",
    live_update=[
        sync("../svc-user-django", "/app"),
        run(
            "cd /app && pip install -r requirements.txt",
            trigger=["../svc-user-django/requirements.txt"],
        ),
        run(
            "cd /app && python manage.py migrate",
            trigger=["../svc-user-django/**/migrations/*.py"],
        ),
    ],
)

k8s_yaml([
    "k8s/svc-user-django/deployment.yaml",
    "k8s/svc-user-django/service.yaml",
])

k8s_resource(
    "svc-user-django",
    labels=["services"],
    port_forwards=["8001:8000", "50051:50051"],
    resource_deps=["postgres", "redis"],
)

# =============================================================================
# Listing Service - Spring Boot (Java)
# =============================================================================

docker_build(
    "ecommerce/svc-listing-spring",
    "../svc-listing-spring",
    dockerfile="../svc-listing-spring/Dockerfile",
    # Spring Boot typically requires full rebuild
)

k8s_yaml([
    "k8s/svc-listing-spring/deployment.yaml",
    "k8s/svc-listing-spring/service.yaml",
])

k8s_resource(
    "svc-listing-spring",
    labels=["services"],
    port_forwards=["8082:8080", "9090:9090"],
    resource_deps=["postgres", "redis"],
)

# =============================================================================
# Inventory Service - Rails (Ruby)
# =============================================================================

docker_build(
    "ecommerce/svc-inventory-rails",
    "../svc-inventory-rails",
    dockerfile="../svc-inventory-rails/Dockerfile",
    live_update=[
        sync("../svc-inventory-rails/app", "/rails/app"),
        sync("../svc-inventory-rails/config", "/rails/config"),
        sync("../svc-inventory-rails/lib", "/rails/lib"),
        run(
            "cd /rails && bundle install",
            trigger=["../svc-inventory-rails/Gemfile", "../svc-inventory-rails/Gemfile.lock"],
        ),
        run(
            "cd /rails && rails db:migrate",
            trigger=["../svc-inventory-rails/db/migrate/*.rb"],
        ),
    ],
)

k8s_yaml([
    "k8s/svc-inventory-rails/deployment.yaml",
    "k8s/svc-inventory-rails/service.yaml",
])

k8s_resource(
    "svc-inventory-rails",
    labels=["services"],
    port_forwards=["3001:3000", "50052:50051"],
    resource_deps=["postgres", "redis"],
)

# =============================================================================
# Resource Groups
# =============================================================================

# Group labels for better organization in Tilt UI
config.set_enabled_namespaces([namespace])

# =============================================================================
# Local Resource: Database Management
# =============================================================================

local_resource(
    "db-migrate-all",
    cmd="kubectl exec -n ecommerce deployment/svc-user-django -- python manage.py migrate && " +
        "kubectl exec -n ecommerce deployment/svc-inventory-rails -- rails db:migrate",
    labels=["database"],
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
)

local_resource(
    "db-seed",
    cmd="kubectl exec -n ecommerce deployment/svc-user-django -- python manage.py loaddata initial_data || true && " +
        "kubectl exec -n ecommerce deployment/svc-inventory-rails -- rails db:seed || true",
    labels=["database"],
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
)

# =============================================================================
# Local Resource: Health Checks
# =============================================================================

local_resource(
    "health-check",
    cmd="""
    echo "Checking health endpoints..."
    curl -sf http://localhost:8080/health && echo "API Gateway: OK" || echo "API Gateway: FAILED"
    curl -sf http://localhost:8001/api/health/ && echo "User Service: OK" || echo "User Service: FAILED"
    curl -sf http://localhost:8082/actuator/health && echo "Listing Service: OK" || echo "Listing Service: FAILED"
    curl -sf http://localhost:3001/health && echo "Inventory Service: OK" || echo "Inventory Service: FAILED"
    """,
    labels=["utilities"],
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
)

# =============================================================================
# Update Settings
# =============================================================================

update_settings(
    max_parallel_updates=3,
    k8s_upsert_timeout_secs=120,
    suppress_unused_image_warnings=["ecommerce/*"],
)

# =============================================================================
# Print Summary
# =============================================================================

print("""
==============================================
Ecommerce Polyrepo - Tilt Development

Access Points:
  Frontend:        http://localhost:3000
  API Gateway:     http://localhost:8080
  User Service:    http://localhost:8001
  Listing Service: http://localhost:8082
  Inventory:       http://localhost:3001
  PostgreSQL:      localhost:5432
  Redis:           localhost:6379

Tilt UI: http://localhost:10350
==============================================
""")
