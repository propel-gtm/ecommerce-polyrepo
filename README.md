# E-Commerce Proto Schemas

Centralized Protocol Buffer definitions for the e-commerce microservices platform.

## Overview

This repository contains all `.proto` files and code generation configurations for the e-commerce platform's gRPC services:

- **User Service** - User management, authentication, profiles
- **Listing Service** - Product listings, categories, search
- **Inventory Service** - Stock management, reservations, tracking
- **Common Types** - Shared messages (pagination, errors, money, etc.)

## Prerequisites

### Required Tools

- [Buf CLI](https://docs.buf.build/installation) (v1.28.0+)
- [Protocol Buffer Compiler](https://grpc.io/docs/protoc-installation/) (protoc v3.21.0+)

### Language-Specific Plugins

#### Go
```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

#### Python
```bash
pip install grpcio-tools grpcio
```

#### Java
```bash
# Using Maven or Gradle with protobuf plugin
# See https://github.com/grpc/grpc-java
```

#### Ruby
```bash
gem install grpc grpc-tools
```

## Project Structure

```
proto-schemas/
├── buf.yaml              # Buf module configuration
├── buf.gen.yaml          # Code generation configuration
├── buf.lock              # Dependency lock file
├── Makefile              # Build automation
├── scripts/
│   └── generate.sh       # Generation script
└── proto/
    ├── common/v1/
    │   └── common.proto  # Shared types
    ├── user/v1/
    │   └── user.proto    # User service
    ├── listing/v1/
    │   └── listing.proto # Listing service
    └── inventory/v1/
        └── inventory.proto # Inventory service
```

## Usage

### Using Buf (Recommended)

#### Lint Proto Files
```bash
buf lint
```

#### Check for Breaking Changes
```bash
buf breaking --against '.git#branch=main'
```

#### Generate Code
```bash
buf generate
```

### Using Make

```bash
# Generate all language bindings
make generate

# Generate specific language
make generate-go
make generate-python
make generate-java
make generate-ruby

# Lint proto files
make lint

# Check for breaking changes
make breaking

# Clean generated files
make clean
```

### Using Script Directly

```bash
./scripts/generate.sh [go|python|java|ruby|all]
```

## Code Generation

### Go

Generated code will be placed in `gen/go/`:

```go
import (
    userv1 "github.com/ecommerce/proto-schemas/gen/go/user/v1"
    listingv1 "github.com/ecommerce/proto-schemas/gen/go/listing/v1"
    inventoryv1 "github.com/ecommerce/proto-schemas/gen/go/inventory/v1"
    commonv1 "github.com/ecommerce/proto-schemas/gen/go/common/v1"
)

// Create a client
conn, err := grpc.Dial("localhost:50051", grpc.WithInsecure())
client := userv1.NewUserServiceClient(conn)

// Make a request
resp, err := client.GetUser(ctx, &userv1.GetUserRequest{
    UserId: "user-123",
})
```

### Python

Generated code will be placed in `gen/python/`:

```python
from user.v1 import user_pb2, user_pb2_grpc
from listing.v1 import listing_pb2, listing_pb2_grpc

# Create a channel and stub
channel = grpc.insecure_channel('localhost:50051')
stub = user_pb2_grpc.UserServiceStub(channel)

# Make a request
response = stub.GetUser(user_pb2.GetUserRequest(user_id='user-123'))
```

### Java

Generated code will be placed in `gen/java/`:

```java
import com.ecommerce.user.v1.UserServiceGrpc;
import com.ecommerce.user.v1.GetUserRequest;
import com.ecommerce.user.v1.GetUserResponse;

// Create a channel and stub
ManagedChannel channel = ManagedChannelBuilder
    .forAddress("localhost", 50051)
    .usePlaintext()
    .build();

UserServiceGrpc.UserServiceBlockingStub stub =
    UserServiceGrpc.newBlockingStub(channel);

// Make a request
GetUserResponse response = stub.getUser(
    GetUserRequest.newBuilder()
        .setUserId("user-123")
        .build()
);
```

### Ruby

Generated code will be placed in `gen/ruby/`:

```ruby
require 'user/v1/user_services_pb'

# Create a stub
stub = User::V1::UserService::Stub.new(
  'localhost:50051',
  :this_channel_is_insecure
)

# Make a request
response = stub.get_user(
  User::V1::GetUserRequest.new(user_id: 'user-123')
)
```

## Versioning

This repository follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes to proto definitions
- **MINOR**: New services, methods, or fields (backward compatible)
- **PATCH**: Documentation, comments, or non-functional changes

### API Versioning

Each service uses URL-based versioning (`/v1/`, `/v2/`, etc.):

- `proto/user/v1/` - User service v1
- `proto/user/v2/` - User service v2 (when needed)

## Contributing

1. Create a feature branch
2. Make changes to proto files
3. Run `make lint` to check for issues
4. Run `make breaking` to check for breaking changes
5. Update documentation if needed
6. Submit a pull request

### Proto Style Guide

- Use `proto3` syntax
- Follow [Buf Style Guide](https://docs.buf.build/lint/rules)
- Use `PascalCase` for message and service names
- Use `snake_case` for field names
- Include comments for all services, methods, and messages
- Use semantic versioning in package names

## License

MIT License - See [LICENSE](LICENSE) for details.
