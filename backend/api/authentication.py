"""Firebase Authentication middleware and helper for Django REST Framework."""
import logging
from typing import Optional, Tuple
from django.contrib.auth.models import AnonymousUser, User
from rest_framework import authentication, exceptions

logger = logging.getLogger(__name__)

try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False


class FirebaseAuthentication(authentication.BaseAuthentication):
    """Authenticates requests using Firebase ID tokens passed in the Authorization header."""

    def authenticate(self, request) -> Optional[Tuple[User, None]]:
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return None

        parts = auth_header.split(' ')
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return None

        token = parts[1]

        if FIREBASE_AVAILABLE and len(firebase_admin._apps) > 0:
            try:
                decoded_token = firebase_auth.verify_id_token(token)
                uid = decoded_token.get('uid', 'anonymous_firebase_user')
                user, _ = User.objects.get_or_create(username=uid)
                return (user, None)
            except Exception as exc:
                logger.error(f"Firebase token verification failed: {exc}")
                raise exceptions.AuthenticationFailed('Invalid Firebase authentication token.')

        # Local development / test fallback
        user, _ = User.objects.get_or_create(username=f"dev_user_{token[:8]}")
        return (user, None)
