# API Testing Guide

## Issue Fixed
✅ **Database migrations were missing** - ran `kubectl exec -n ecommerce deploy/svc-user-django -- python manage.py migrate`

## Important: Use Minikube IP
Since minikube runs in a VM, **you must use the minikube IP instead of `localhost`**

```bash
# Get minikube IP
minikube ip
# Returns: 192.168.49.2
```

## Service URLs (Minikube NodePorts)

| Service | URL | Port |
|---------|-----|------|
| **API Gateway** | http://192.168.49.2:30080 | 30080 |
| **User Service** | http://192.168.49.2:30801 | 30801 |
| **Listing Service** | http://192.168.49.2:30802 | 30802 |
| **Inventory Service** | http://192.168.49.2:30301 | 30301 |
| **Frontend** | http://192.168.49.2:30300 | 30300 |

## Authentication Flow

### 1. Register a New User

**Endpoint:** `POST http://192.168.49.2:30801/api/auth/register/`

**Request:**
```json
{
  "username": "demouser",
  "email": "demo@example.com",
  "password": "SecurePass123",
  "password_confirm": "SecurePass123",
  "first_name": "Demo",
  "last_name": "User"
}
```

**Response:**
```json
{
  "message": "User registered successfully.",
  "user": { ... },
  "tokens": {
    "access": "eyJhbGci...",
    "refresh": "eyJhbGci..."
  }
}
```

### 2. Login

**Endpoint:** `POST http://192.168.49.2:30801/api/auth/login/`

**Request:**
```json
{
  "email": "demo@example.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "message": "Login successful.",
  "tokens": {
    "access": "eyJhbGci...",
    "refresh": "eyJhbGci..."
  }
}
```

### 3. Use Access Token for Protected Endpoints

Add the access token to the `Authorization` header:

```
Authorization: Bearer eyJhbGci...
```

**Example:** Get current user profile
```bash
curl -X GET http://192.168.49.2:30801/api/users/me/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4. Refresh Token (When Access Token Expires)

**Endpoint:** `POST http://192.168.49.2:30801/api/auth/refresh/`

**Request:**
```json
{
  "refresh": "YOUR_REFRESH_TOKEN"
}
```

## Using in Postman

### Option 1: Update Postman Collection URLs
Replace `localhost` with `192.168.49.2` in your collection variables or directly in the URLs.

### Option 2: Set Up Port Forwarding (Use localhost)
Run these commands in separate terminals:

```bash
# API Gateway
kubectl port-forward -n ecommerce svc/be-api-gin 30080:8080

# User Service
kubectl port-forward -n ecommerce svc/svc-user-django 30801:8000

# Listing Service
kubectl port-forward -n ecommerce svc/svc-listing-spring 30802:8080

# Inventory Service
kubectl port-forward -n ecommerce svc/svc-inventory-rails 30301:3000
```

Then use `http://localhost:30080`, `http://localhost:30801`, etc.

## Test User Created

A test user has been created for you:
- **Email:** demo@example.com
- **Username:** demouser
- **Password:** SecurePass123

## Common Issues

### Connection Refused (ECONNREFUSED)
- **Cause:** Using `localhost` instead of minikube IP
- **Solution:** Use `192.168.49.2` instead of `localhost`

### Database Errors (relation does not exist)
- **Cause:** Database migrations not run
- **Solution:** Run migrations:
  ```bash
  kubectl exec -n ecommerce deploy/svc-user-django -- python manage.py migrate
  ```

### Invalid Password Errors
- **Cause:** Password validation requires:
  - Minimum length
  - Not too common
  - Must include `password_confirm` field in registration
- **Solution:** Use strong passwords like `SecurePass123`

### JSON Parse Errors
- **Cause:** Special characters in curl commands (!, $, etc.)
- **Solution:** Use simpler passwords or escape special characters

## Health Check Endpoints

Test if services are running:

```bash
# User Service
curl http://192.168.49.2:30801/api/health/

# API Gateway
curl http://192.168.49.2:30080/health

# Listing Service
curl http://192.168.49.2:30802/actuator/health

# Inventory Service
curl http://192.168.49.2:30301/health
```

## Quick Test Commands

```bash
# Register
curl -X POST http://192.168.49.2:30801/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"SecurePass123","password_confirm":"SecurePass123","first_name":"Test","last_name":"User"}'

# Login (save the access token from response)
curl -X POST http://192.168.49.2:30801/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123"}'

# Get current user (replace TOKEN with access token from login)
curl -X GET http://192.168.49.2:30801/api/users/me/ \
  -H "Authorization: Bearer TOKEN"
```

## Notes

- Access tokens expire after 15 minutes (configurable)
- Refresh tokens expire after 7 days (configurable)
- All protected endpoints require `Authorization: Bearer <token>` header
- Use refresh token endpoint to get new access token when expired
