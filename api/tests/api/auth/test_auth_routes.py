"""Unit tests for the auth routes."""

import uuid
from datetime import datetime
from unittest.mock import MagicMock, patch

import bcrypt
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.auth.routes import router as auth_router
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User

# Setup the test app
app = FastAPI()
app.include_router(auth_router)


@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_db_session():
    """Mock the database session."""
    session = MagicMock()
    return session


@pytest.fixture
def override_get_db(mock_db_session):
    """Override the get_db dependency."""
    def _get_db():
        yield mock_db_session
    
    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_stripe_client():
    """Mock the StripeClient."""
    with patch("src.api.auth.routes.StripeClient") as mock_stripe:
        mock_customer = MagicMock()
        mock_customer.id = "cus_test123"
        mock_stripe.create_customer.return_value = mock_customer
        yield mock_stripe


class TestRegister:
    """Test suite for the register endpoint."""

    def test_register_success(self, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test successful user registration."""
        # Setup mock DB behavior
        mock_db_session.query.return_value.filter.return_value.first.return_value = None  # User doesn't exist
        
        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()
            
        mock_db_session.refresh.side_effect = refresh_side_effect
        
        payload = {
            "email": "newuser@example.com",
            "password": "password123",
            "fullName": "New User",
            "phone": "+1234567890"
        }
        
        response = client.post("/v1/auth/register", json=payload)
        
        assert response.status_code == 201
        data = response.json()
        assert "token" in data
        assert data["user"]["email"] == "newuser@example.com"
        
        # Verify DB interactions
        assert mock_db_session.add.called
        assert mock_db_session.commit.called
        
        # Verify Stripe interaction
        mock_stripe_client.create_customer.assert_called_once_with(
            email="newuser@example.com",
            name="New User"
        )

    def test_register_user_exists(self, client, override_get_db, mock_db_session):
        """Test registration when user already exists."""
        # Setup mock DB behavior
        existing_user = User(id=uuid.uuid4(), email="existing@example.com")
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing_user
        
        payload = {
            "email": "existing@example.com",
            "password": "password123"
        }
        
        response = client.post("/v1/auth/register", json=payload)
        
        assert response.status_code == 400
        assert response.json()["detail"] == "User already exists"


    def test_register_integrity_error(self, client, override_get_db, mock_db_session):
        """Test registration race condition handling (IntegrityError)."""
        from sqlalchemy.exc import IntegrityError
        
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        mock_db_session.commit.side_effect = IntegrityError("mock", "mock", "mock")
        
        payload = {
            "email": "race@example.com",
            "password": "password123"
        }
        
        response = client.post("/v1/auth/register", json=payload)
        
        assert response.status_code == 400
        assert response.json()["detail"] == "User already exists"
        assert mock_db_session.rollback.called

    def test_register_stripe_failure(self, client, override_get_db, mock_db_session, mock_stripe_client):
        """Test registration when Stripe customer creation fails."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        # Mock Stripe failure
        mock_stripe_client.create_customer.side_effect = Exception("Stripe down")
        
        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()
            instance.updated_at = datetime.utcnow()
            
        mock_db_session.refresh.side_effect = refresh_side_effect
        
        payload = {
            "email": "nostripe@example.com",
            "password": "password123"
        }
        
        response = client.post("/v1/auth/register", json=payload)
        
        # Should still succeed
        assert response.status_code == 201
        data = response.json()
        assert data["user"]["email"] == "nostripe@example.com"


class TestLogin:
    """Test suite for the login endpoint."""

    def test_login_success(self, client, override_get_db, mock_db_session):
        """Test successful login."""
        # Setup user with hashed password
        password = "password123"
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        user = User(
            id=uuid.uuid4(), 
            email="user@example.com", 
            password_hash=hashed,
            created_at=datetime.utcnow(),
            updated_at=None
        )
        
        mock_db_session.query.return_value.filter.return_value.first.return_value = user
        
        payload = {"email": "user@example.com", "password": password}
        response = client.post("/v1/auth/login", json=payload)
        
        assert response.status_code == 200
        data = response.json()
        assert "token" in data
        assert data["user"]["email"] == "user@example.com"

    def test_login_user_not_found(self, client, override_get_db, mock_db_session):
        """Test login with non-existent email."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        payload = {"email": "unknown@example.com", "password": "password123"}
        response = client.post("/v1/auth/login", json=payload)
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid credentials"

    def test_login_wrong_password(self, client, override_get_db, mock_db_session):
        """Test login with incorrect password."""
        # Setup user with hashed password
        password = "password123"
        hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        user = User(
            id=uuid.uuid4(), 
            email="user@example.com", 
            password_hash=hashed
        )
        
        mock_db_session.query.return_value.filter.return_value.first.return_value = user
        
        payload = {"email": "user@example.com", "password": "wrongpassword"}
        response = client.post("/v1/auth/login", json=payload)
        
        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid credentials"


class TestMe:
    """Test suite for the me endpoint."""
    
    def test_me_success(self, client):
        """Test retrieving current user info."""
        user = User(
            id=uuid.uuid4(),
            email="me@example.com",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        # Override the get_current_user dependency directly
        app.dependency_overrides[get_current_user] = lambda: user
        
        response = client.get("/v1/auth/me")
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "me@example.com"
        assert "id" in data
        
        # Cleanup
        app.dependency_overrides = {}
