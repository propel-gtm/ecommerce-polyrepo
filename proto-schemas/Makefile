# Makefile for proto-schemas
# Code generation and management for Protocol Buffer definitions

.PHONY: all generate generate-go generate-python generate-java generate-ruby \
        lint breaking clean install-tools help deps update-deps

# Default target
all: lint generate

# Install required tools
install-tools:
	@echo "Installing buf..."
	@which buf > /dev/null || (curl -sSL https://github.com/bufbuild/buf/releases/latest/download/buf-$$(uname -s)-$$(uname -m) -o /usr/local/bin/buf && chmod +x /usr/local/bin/buf)
	@echo "Installing Go plugins..."
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@echo "Installing Python plugins..."
	pip install grpcio-tools grpcio
	@echo "Tools installed successfully"

# Update buf dependencies
deps:
	buf dep update

update-deps: deps

# Lint proto files
lint:
	@echo "Linting proto files..."
	buf lint

# Check for breaking changes
breaking:
	@echo "Checking for breaking changes..."
	buf breaking --against '.git#branch=main'

# Generate all language bindings
generate: deps
	@echo "Generating code for all languages..."
	buf generate
	@echo "Code generation complete"

# Generate Go code only
generate-go: deps
	@echo "Generating Go code..."
	@mkdir -p gen/go
	buf generate --template buf.gen.go.yaml 2>/dev/null || \
		buf generate --path proto --include-imports
	@echo "Go code generated in gen/go/"

# Generate Python code only
generate-python: deps
	@echo "Generating Python code..."
	@mkdir -p gen/python
	buf generate --template buf.gen.python.yaml 2>/dev/null || \
		./scripts/generate.sh python
	@echo "Python code generated in gen/python/"

# Generate Java code only
generate-java: deps
	@echo "Generating Java code..."
	@mkdir -p gen/java
	buf generate --template buf.gen.java.yaml 2>/dev/null || \
		./scripts/generate.sh java
	@echo "Java code generated in gen/java/"

# Generate Ruby code only
generate-ruby: deps
	@echo "Generating Ruby code..."
	@mkdir -p gen/ruby
	./scripts/generate.sh ruby
	@echo "Ruby code generated in gen/ruby/"

# Format proto files
format:
	@echo "Formatting proto files..."
	buf format -w

# Build (validate) proto files
build:
	@echo "Building proto files..."
	buf build

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -rf gen/
	@echo "Clean complete"

# Create buf.lock file
lock:
	buf dep update

# Push to Buf Schema Registry (requires authentication)
push:
	@echo "Pushing to Buf Schema Registry..."
	buf push

# Show help
help:
	@echo "Available targets:"
	@echo "  all            - Lint and generate all code (default)"
	@echo "  generate       - Generate code for all languages"
	@echo "  generate-go    - Generate Go code only"
	@echo "  generate-python - Generate Python code only"
	@echo "  generate-java  - Generate Java code only"
	@echo "  generate-ruby  - Generate Ruby code only"
	@echo "  lint           - Lint proto files"
	@echo "  format         - Format proto files"
	@echo "  breaking       - Check for breaking changes against main"
	@echo "  build          - Validate proto files"
	@echo "  clean          - Remove generated files"
	@echo "  deps           - Update buf dependencies"
	@echo "  install-tools  - Install required tools"
	@echo "  push           - Push to Buf Schema Registry"
	@echo "  help           - Show this help message"
