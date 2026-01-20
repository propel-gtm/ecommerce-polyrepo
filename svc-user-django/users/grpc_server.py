"""
gRPC server implementation for the user service.

This module provides a gRPC interface for inter-service communication,
allowing other microservices to query user data and validate tokens.
"""
import os
import sys
import logging
from concurrent import futures
import grpc

# Add parent directory to path for Django settings
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'user_service.settings')

import django
django.setup()

from django.conf import settings
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError

from users.models import User

logger = logging.getLogger(__name__)

# gRPC service definition (inline proto)
# In production, you would use a .proto file and generate stubs
GRPC_SERVICE_DEFINITION = """
syntax = "proto3";

package user;

service UserService {
    rpc GetUser (UserRequest) returns (UserResponse);
    rpc GetUserByEmail (EmailRequest) returns (UserResponse);
    rpc ValidateToken (TokenRequest) returns (TokenResponse);
    rpc ListUsers (ListUsersRequest) returns (ListUsersResponse);
}

message UserRequest {
    string user_id = 1;
}

message EmailRequest {
    string email = 1;
}

message TokenRequest {
    string token = 1;
}

message ListUsersRequest {
    int32 page = 1;
    int32 page_size = 2;
}

message UserResponse {
    bool success = 1;
    string message = 2;
    UserData user = 3;
}

message TokenResponse {
    bool valid = 1;
    string message = 2;
    string user_id = 3;
    string email = 4;
}

message ListUsersResponse {
    bool success = 1;
    repeated UserData users = 2;
    int32 total = 3;
}

message UserData {
    string id = 1;
    string email = 2;
    string username = 3;
    string first_name = 4;
    string last_name = 5;
    string phone_number = 6;
    bool is_active = 7;
    bool is_verified = 8;
    string date_joined = 9;
}
"""


class UserServiceServicer:
    """gRPC servicer for user operations."""

    def GetUser(self, request, context):
        """Get user by ID."""
        try:
            user = User.objects.get(id=request.user_id)
            return {
                'success': True,
                'message': 'User found.',
                'user': user.to_dict()
            }
        except User.DoesNotExist:
            context.set_code(grpc.StatusCode.NOT_FOUND)
            return {
                'success': False,
                'message': 'User not found.',
                'user': None
            }
        except Exception as e:
            logger.error(f'Error getting user: {e}')
            context.set_code(grpc.StatusCode.INTERNAL)
            return {
                'success': False,
                'message': str(e),
                'user': None
            }

    def GetUserByEmail(self, request, context):
        """Get user by email."""
        try:
            user = User.objects.get(email=request.email.lower())
            return {
                'success': True,
                'message': 'User found.',
                'user': user.to_dict()
            }
        except User.DoesNotExist:
            context.set_code(grpc.StatusCode.NOT_FOUND)
            return {
                'success': False,
                'message': 'User not found.',
                'user': None
            }
        except Exception as e:
            logger.error(f'Error getting user by email: {e}')
            context.set_code(grpc.StatusCode.INTERNAL)
            return {
                'success': False,
                'message': str(e),
                'user': None
            }

    def ValidateToken(self, request, context):
        """Validate a JWT access token."""
        try:
            token = AccessToken(request.token)
            user_id = token.get('user_id')

            try:
                user = User.objects.get(id=user_id)
                if not user.is_active:
                    return {
                        'valid': False,
                        'message': 'User account is disabled.',
                        'user_id': '',
                        'email': ''
                    }

                return {
                    'valid': True,
                    'message': 'Token is valid.',
                    'user_id': str(user.id),
                    'email': user.email
                }
            except User.DoesNotExist:
                return {
                    'valid': False,
                    'message': 'User not found.',
                    'user_id': '',
                    'email': ''
                }

        except TokenError as e:
            return {
                'valid': False,
                'message': f'Invalid token: {str(e)}',
                'user_id': '',
                'email': ''
            }
        except Exception as e:
            logger.error(f'Error validating token: {e}')
            context.set_code(grpc.StatusCode.INTERNAL)
            return {
                'valid': False,
                'message': str(e),
                'user_id': '',
                'email': ''
            }

    def ListUsers(self, request, context):
        """List users with pagination."""
        try:
            page = request.page or 1
            page_size = min(request.page_size or 20, 100)  # Max 100 per page
            offset = (page - 1) * page_size

            users = User.objects.filter(is_active=True)[offset:offset + page_size]
            total = User.objects.filter(is_active=True).count()

            return {
                'success': True,
                'users': [user.to_dict() for user in users],
                'total': total
            }
        except Exception as e:
            logger.error(f'Error listing users: {e}')
            context.set_code(grpc.StatusCode.INTERNAL)
            return {
                'success': False,
                'users': [],
                'total': 0
            }


# Simple gRPC server without proto compilation
# For production, use proper proto files and grpcio-tools
class SimpleGrpcServer:
    """Simple gRPC-like server for demonstration.

    In production, you would:
    1. Create a .proto file
    2. Generate Python stubs using grpcio-tools
    3. Implement the generated servicer interface
    """

    def __init__(self, port=50051):
        self.port = port
        self.servicer = UserServiceServicer()
        self.server = None

    def start(self):
        """Start the gRPC server."""
        self.server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

        # In production with proper proto files:
        # user_pb2_grpc.add_UserServiceServicer_to_server(self.servicer, self.server)

        self.server.add_insecure_port(f'[::]:{self.port}')
        self.server.start()

        logger.info(f'gRPC server started on port {self.port}')
        print(f'gRPC server listening on port {self.port}')

    def stop(self):
        """Stop the gRPC server."""
        if self.server:
            self.server.stop(0)
            logger.info('gRPC server stopped')

    def wait_for_termination(self):
        """Wait for the server to terminate."""
        if self.server:
            self.server.wait_for_termination()


def serve():
    """Run the gRPC server."""
    port = settings.GRPC_PORT

    server = SimpleGrpcServer(port=port)
    server.start()

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop()
        print('Server stopped.')


if __name__ == '__main__':
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    serve()
