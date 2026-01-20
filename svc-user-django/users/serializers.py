"""
Serializers for the user service.
"""
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""

    class Meta:
        model = User
        fields = [
            'id', 'email', 'username', 'first_name', 'last_name',
            'phone_number', 'is_active', 'is_verified', 'date_joined', 'updated_at'
        ]
        read_only_fields = ['id', 'is_active', 'is_verified', 'date_joined', 'updated_at']


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""

    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = [
            'email', 'password', 'password_confirm',
            'username', 'first_name', 'last_name', 'phone_number'
        ]

    def validate(self, attrs):
        """Validate that passwords match."""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                'password_confirm': 'Passwords do not match.'
            })
        return attrs

    def validate_email(self, value):
        """Validate email is unique."""
        if User.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value.lower()

    def create(self, validated_data):
        """Create and return a new user."""
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login."""

    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True, style={'input_type': 'password'})

    def validate(self, attrs):
        """Validate user credentials."""
        email = attrs.get('email', '').lower()
        password = attrs.get('password', '')

        user = authenticate(username=email, password=password)

        if not user:
            raise serializers.ValidationError('Invalid email or password.')

        if not user.is_active:
            raise serializers.ValidationError('User account is disabled.')

        attrs['user'] = user
        return attrs


class TokenResponseSerializer(serializers.Serializer):
    """Serializer for token response."""

    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserSerializer()


class LogoutSerializer(serializers.Serializer):
    """Serializer for logout (token blacklist)."""

    refresh = serializers.CharField(required=True)

    def validate(self, attrs):
        """Validate and blacklist the refresh token."""
        self.token = attrs['refresh']
        return attrs

    def save(self, **kwargs):
        """Blacklist the refresh token."""
        try:
            token = RefreshToken(self.token)
            token.blacklist()
        except Exception as e:
            raise serializers.ValidationError({'refresh': 'Invalid or expired token.'})


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password."""

    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password]
    )
    new_password_confirm = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        """Validate passwords."""
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                'new_password_confirm': 'New passwords do not match.'
            })
        return attrs

    def validate_old_password(self, value):
        """Validate old password is correct."""
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Old password is incorrect.')
        return value


class UserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile."""

    class Meta:
        model = User
        fields = ['username', 'first_name', 'last_name', 'phone_number']

    def validate_username(self, value):
        """Validate username is unique if provided."""
        if value:
            user = self.context['request'].user
            if User.objects.filter(username=value).exclude(id=user.id).exists():
                raise serializers.ValidationError('This username is already taken.')
        return value
