"""
URL routing for the users app.
"""
from django.urls import path
from . import views

app_name = 'users'

urlpatterns = [
    # Health check
    path('health/', views.HealthCheckView.as_view(), name='health'),

    # Authentication
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/login/', views.LoginView.as_view(), name='login'),
    path('auth/logout/', views.LogoutView.as_view(), name='logout'),

    # Current user
    path('users/me/', views.CurrentUserView.as_view(), name='current_user'),
    path('users/me/password/', views.ChangePasswordView.as_view(), name='change_password'),

    # Admin endpoints
    path('users/', views.UserListView.as_view(), name='user_list'),
    path('users/<uuid:id>/', views.UserDetailView.as_view(), name='user_detail'),
]
