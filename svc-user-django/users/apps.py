"""
App configuration for the users app.
"""
from django.apps import AppConfig


class UsersConfig(AppConfig):
    """Users app configuration."""

    default_auto_field = 'django.db.models.BigAutoField'
    name = 'users'
    verbose_name = 'Users'
