"""Unit tests for the auth middleware."""

import os
import uuid
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from jose import jwt
from unittest.mock import MagicMock

from src.api.auth.middleware import get_current_user, verify_jwt_token
from src.config.env import settings
from src.models.user import User

# Use the same secret as in middleware
JWT_SECRET = settings.JWT_SECRET


def create_test_token(user_id: str, expire_delta: timedelta = None) -> str:
    """Helper to create a JWT token for testing."""
    if expire_delta:
        expire = datetime.utcnow() + expire_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    
    payload = {"userId": user_id, "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


class TestVerifyJwtToken:
    """Test suite for verify_jwt_token function."""

    def test_verify_valid_token(self):
        """Test verification of a valid token."""
        user_id = str(uuid.uuid4())
        token = create_test_token(user_id)
        assert verify_jwt_token(token) == user_id

    def test_verify_invalid_token(self):
        """Test verification of an invalid token."""
        assert verify_jwt_token("invalid.token.here") is None

    def test_verify_expired_token(self):
        """Test verification of an expired token."""
        user_id = str(uuid.uuid4())
        # Create token expired 1 minute ago
        token = create_test_token(user_id, expire_delta=timedelta(minutes=-1))
        assert verify_jwt_token(token) is None
    
    def test_verify_wrong_secret(self):
        """Test verification of a token signed with wrong secret."""
        user_id = str(uuid.uuid4())
        payload = {"userId": user_id, "exp": datetime.utcnow() + timedelta(minutes=15)}
        # Sign with different secret
        token = jwt.encode(payload, "wrong-secret", algorithm="HS256")
        assert verify_jwt_token(token) is None


class TestGetCurrentUser:
    """Test suite for get_current_user dependency."""

    @pytest.mark.asyncio
    async def test_get_current_user_success(self):
        """Test successful retrieval of current user."""
        user_id = str(uuid.uuid4())
        token = create_test_token(user_id)

        # Mock credentials
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

        # Mock Request (no cookie, so Bearer header is used)
        mock_request = MagicMock()
        mock_request.cookies.get.return_value = None

        # Mock DB
        mock_db = MagicMock()
        mock_user = User(id=uuid.UUID(user_id), email="test@example.com")
        mock_db.query.return_value.filter.return_value.first.return_value = mock_user

        user = await get_current_user(mock_request, credentials, mock_db)

        assert user is mock_user
        assert str(user.id) == user_id

    @pytest.mark.asyncio
    async def test_get_current_user_invalid_token(self):
        """Test get_current_user with invalid token."""
        token = "invalid.token"
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        mock_request = MagicMock()
        mock_request.cookies.get.return_value = None
        mock_db = MagicMock()

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(mock_request, credentials, mock_db)

        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
        assert exc_info.value.detail == "Invalid or expired token"

    @pytest.mark.asyncio
    async def test_get_current_user_not_found(self):
        """Test get_current_user when user does not exist in DB."""
        user_id = str(uuid.uuid4())
        token = create_test_token(user_id)

        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

        # Mock Request (no cookie)
        mock_request = MagicMock()
        mock_request.cookies.get.return_value = None

        # Mock DB to return None
        mock_db = MagicMock()
        mock_db.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(mock_request, credentials, mock_db)

        assert exc_info.value.status_code == status.HTTP_404_NOT_FOUND
        assert exc_info.value.detail == "User not found"
