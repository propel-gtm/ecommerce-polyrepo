# User Service (Django)

A minimal Django-based user microservice providing user registration, authentication, JWT tokens, and profile management with both REST and gRPC interfaces.

## Features

- User registration and authentication
- JWT token-based authentication (access + refresh tokens)
- User profile management (CRUD operations)
- REST API via Django REST Framework
- gRPC interface for inter-service communication

## Tech Stack

- Python 3.11+
- Django 4.2
- Django REST Framework
- djangorestframework-simplejwt
- gRPC (grpcio)

## Quick Start

### Local Development

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment variables
cp .env.example .env

# Run migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Run development server
python manage.py runserver 0.0.0.0:8000

# Run gRPC server (separate terminal)
python -m users.grpc_server
```

### Docker

```bash
docker build -t svc-user-django .
docker run -p 8000:8000 -p 50051:50051 svc-user-django
```

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register/` | Register a new user |
| POST | `/api/auth/login/` | Login and get JWT tokens |
| POST | `/api/auth/refresh/` | Refresh access token |
| POST | `/api/auth/logout/` | Logout (blacklist refresh token) |

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/me/` | Get current user profile |
| PUT | `/api/users/me/` | Update current user profile |
| PATCH | `/api/users/me/` | Partial update current user profile |
| DELETE | `/api/users/me/` | Delete current user account |
| GET | `/api/users/` | List all users (admin only) |
| GET | `/api/users/{id}/` | Get user by ID (admin only) |

## gRPC Interface

The service exposes a gRPC interface on port 50051 for inter-service communication.

### Available Methods

- `GetUser(UserRequest)` - Get user by ID
- `ValidateToken(TokenRequest)` - Validate JWT token
- `GetUserByEmail(EmailRequest)` - Get user by email

## Environment Variables

See `.env.example` for all available configuration options.

## Testing

```bash
# Run tests
python manage.py test

# Run with coverage
coverage run manage.py test
coverage report
```

## License

MIT
