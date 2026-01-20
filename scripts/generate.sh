#!/bin/bash
# generate.sh - Generate code from Protocol Buffer definitions
#
# Usage: ./scripts/generate.sh [go|python|java|ruby|all]
#
# This script generates language-specific code from .proto files.
# It can use either buf (preferred) or protoc directly.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROTO_DIR="$ROOT_DIR/proto"
GEN_DIR="$ROOT_DIR/gen"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    local lang=$1

    case $lang in
        go)
            if ! command_exists protoc-gen-go; then
                log_error "protoc-gen-go not found. Install with:"
                echo "  go install google.golang.org/protobuf/cmd/protoc-gen-go@latest"
                exit 1
            fi
            if ! command_exists protoc-gen-go-grpc; then
                log_error "protoc-gen-go-grpc not found. Install with:"
                echo "  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"
                exit 1
            fi
            ;;
        python)
            if ! python3 -c "import grpc_tools.protoc" 2>/dev/null; then
                log_error "grpcio-tools not found. Install with:"
                echo "  pip install grpcio-tools"
                exit 1
            fi
            ;;
        java)
            if ! command_exists protoc-gen-grpc-java; then
                log_warn "protoc-gen-grpc-java not found. Using buf plugins instead."
            fi
            ;;
        ruby)
            if ! command_exists grpc_tools_ruby_protoc; then
                log_error "grpc-tools gem not found. Install with:"
                echo "  gem install grpc grpc-tools"
                exit 1
            fi
            ;;
    esac
}

# Generate Go code
generate_go() {
    log_info "Generating Go code..."

    local out_dir="$GEN_DIR/go"
    mkdir -p "$out_dir"

    if command_exists buf; then
        cd "$ROOT_DIR"
        buf generate --include-imports
    else
        check_prerequisites go

        # Find all proto files
        find "$PROTO_DIR" -name "*.proto" | while read -r proto_file; do
            protoc \
                --proto_path="$PROTO_DIR" \
                --go_out="$out_dir" \
                --go_opt=paths=source_relative \
                --go-grpc_out="$out_dir" \
                --go-grpc_opt=paths=source_relative \
                "$proto_file"
        done
    fi

    log_info "Go code generated in $out_dir"
}

# Generate Python code
generate_python() {
    log_info "Generating Python code..."

    local out_dir="$GEN_DIR/python"
    mkdir -p "$out_dir"

    if command_exists buf; then
        cd "$ROOT_DIR"
        buf generate --include-imports
    else
        check_prerequisites python

        # Find all proto files
        find "$PROTO_DIR" -name "*.proto" | while read -r proto_file; do
            python3 -m grpc_tools.protoc \
                --proto_path="$PROTO_DIR" \
                --python_out="$out_dir" \
                --grpc_python_out="$out_dir" \
                "$proto_file"
        done

        # Create __init__.py files for packages
        find "$out_dir" -type d -exec touch {}/__init__.py \;
    fi

    log_info "Python code generated in $out_dir"
}

# Generate Java code
generate_java() {
    log_info "Generating Java code..."

    local out_dir="$GEN_DIR/java"
    mkdir -p "$out_dir"

    if command_exists buf; then
        cd "$ROOT_DIR"
        buf generate --include-imports
    else
        check_prerequisites java

        # Find all proto files
        find "$PROTO_DIR" -name "*.proto" | while read -r proto_file; do
            protoc \
                --proto_path="$PROTO_DIR" \
                --java_out="$out_dir" \
                "$proto_file"
        done
    fi

    log_info "Java code generated in $out_dir"
}

# Generate Ruby code
generate_ruby() {
    log_info "Generating Ruby code..."

    local out_dir="$GEN_DIR/ruby"
    mkdir -p "$out_dir"

    check_prerequisites ruby

    # Find all proto files
    find "$PROTO_DIR" -name "*.proto" | while read -r proto_file; do
        grpc_tools_ruby_protoc \
            --proto_path="$PROTO_DIR" \
            --ruby_out="$out_dir" \
            --grpc_out="$out_dir" \
            "$proto_file"
    done

    log_info "Ruby code generated in $out_dir"
}

# Generate all languages
generate_all() {
    log_info "Generating code for all languages..."

    if command_exists buf; then
        cd "$ROOT_DIR"
        buf generate --include-imports
        log_info "All code generated using buf"
    else
        generate_go
        generate_python
        generate_java
        generate_ruby
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [go|python|java|ruby|all]"
    echo ""
    echo "Generate code from Protocol Buffer definitions."
    echo ""
    echo "Commands:"
    echo "  go      Generate Go code"
    echo "  python  Generate Python code"
    echo "  java    Generate Java code"
    echo "  ruby    Generate Ruby code"
    echo "  all     Generate code for all languages (default)"
    echo ""
    echo "Examples:"
    echo "  $0 go        # Generate Go code only"
    echo "  $0 all       # Generate all languages"
    echo "  $0           # Same as 'all'"
}

# Main
main() {
    local command="${1:-all}"

    case $command in
        go)
            generate_go
            ;;
        python)
            generate_python
            ;;
        java)
            generate_java
            ;;
        ruby)
            generate_ruby
            ;;
        all)
            generate_all
            ;;
        -h|--help|help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
