#!/bin/bash

# =============================================================================
# Initialize Multiple PostgreSQL Databases
# =============================================================================
# This script is used by Docker Compose to create multiple databases
# on PostgreSQL startup.
# =============================================================================

set -e
set -u

function create_user_and_database() {
    local database=$1
    echo "Creating database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE DATABASE $database;
        GRANT ALL PRIVILEGES ON DATABASE $database TO $POSTGRES_USER;
EOSQL
}

function create_extensions() {
    local database=$1
    echo "Creating extensions for '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$database" <<-EOSQL
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOSQL
}

# Parse the POSTGRES_MULTIPLE_DATABASES environment variable
if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    echo "Creating multiple databases: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_user_and_database $db
        create_extensions $db
    done
    echo "Multiple databases created successfully!"
else
    echo "No POSTGRES_MULTIPLE_DATABASES specified, skipping..."
fi
