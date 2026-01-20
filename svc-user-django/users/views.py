"""
API views for the user service.
"""
import logging
from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404

from .models import User
from .serializers import (
    UserSerializer,
    UserRegistrationSerializer,
    UserLoginSerializer,
    LogoutSerializer,
    ChangePasswordSerializer,
    UserUpdateSerializer,
)

logger = logging.getLogger(__name__)


class RegisterView(generics.CreateAPIView):
    """User registration endpoint."""

    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        """Create a new user and return tokens."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate tokens
        refresh = RefreshToken.for_user(user)

        logger.info(f'User registered: {user.email}')

        return Response({
            'message': 'User registered successfully.',
            'user': UserSerializer(user).data,
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    """User login endpoint."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        """Authenticate user and return tokens."""
        serializer = UserLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)

        logger.info(f'User logged in: {user.email}')

        return Response({
            'message': 'Login successful.',
            'user': UserSerializer(user).data,
            'tokens': {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
            }
        }, status=status.HTTP_200_OK)


class LogoutView(APIView):
    """User logout endpoint (blacklist refresh token)."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Blacklist the refresh token."""
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        logger.info(f'User logged out: {request.user.email}')

        return Response({
            'message': 'Logout successful.'
        }, status=status.HTTP_200_OK)


class CurrentUserView(generics.RetrieveUpdateDestroyAPIView):
    """Current user profile endpoint."""

    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        """Return the current user."""
        return self.request.user

    def get_serializer_class(self):
        """Return appropriate serializer based on request method."""
        if self.request.method in ['PUT', 'PATCH']:
            return UserUpdateSerializer
        return UserSerializer

    def destroy(self, request, *args, **kwargs):
        """Soft delete the current user (deactivate)."""
        user = self.get_object()
        user.is_active = False
        user.save()

        logger.info(f'User deactivated: {user.email}')

        return Response({
            'message': 'Account deactivated successfully.'
        }, status=status.HTTP_200_OK)


class ChangePasswordView(APIView):
    """Change password endpoint."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Change the user's password."""
        serializer = ChangePasswordSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save()

        logger.info(f'Password changed for user: {user.email}')

        return Response({
            'message': 'Password changed successfully.'
        }, status=status.HTTP_200_OK)


class UserListView(generics.ListAPIView):
    """List all users (admin only)."""

    queryset = User.objects.filter(is_active=True)
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]


class UserDetailView(generics.RetrieveAPIView):
    """Retrieve a specific user (admin only)."""

    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]
    lookup_field = 'id'


class HealthCheckView(APIView):
    """Health check endpoint."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        """Return service health status."""
        return Response({
            'status': 'healthy',
            'service': 'user-service',
        }, status=status.HTTP_200_OK)
