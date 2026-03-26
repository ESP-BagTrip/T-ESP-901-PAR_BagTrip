"""Tests d'intégration pour le flow complet."""

import os
from uuid import uuid4

import jwt
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from src.config.database import SessionLocal
from src.main import app
from src.models.user import User

client = TestClient(app)

# JWT secret pour les tests
JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key")


@pytest.fixture
def db():
    """Fixture pour la session DB."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def test_user(db: Session):
    """Créer un utilisateur de test."""
    from passlib.context import CryptContext

    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    user = User(
        id=uuid4(),
        email="test@example.com",
        password_hash=pwd_context.hash("test_password"),
        full_name="Test User",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def auth_token(test_user: User):
    """Obtenir un token JWT pour l'utilisateur de test."""
    token = jwt.encode(
        {"userId": str(test_user.id)}, JWT_SECRET, algorithm="HS256"
    )
    return token


@pytest.fixture
def test_user2(db: Session):
    """Créer un deuxième utilisateur de test."""
    from passlib.context import CryptContext

    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    user = User(
        id=uuid4(),
        email="test2@example.com",
        password_hash=pwd_context.hash("test_password"),
        full_name="Test User 2",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def auth_token2(test_user2: User):
    """Obtenir un token JWT pour le deuxième utilisateur."""
    token = jwt.encode(
        {"userId": str(test_user2.id)}, JWT_SECRET, algorithm="HS256"
    )
    return token


def test_full_flow(auth_token: str, db: Session, test_user: User):
    """Test du flow complet."""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 1. Créer un trip
    trip_response = client.post(
        "/v1/trips",
        headers=headers,
        json={
            "title": "Voyage à Paris",
            "destinationName": "Paris",
            "startDate": "2099-06-01",
            "endDate": "2099-06-10",
        },
    )
    assert trip_response.status_code == 200
    trip_id = trip_response.json()["trip"]["id"]

    # 2. Ajouter un traveler
    traveler_response = client.post(
        f"/v1/trips/{trip_id}/travelers",
        headers=headers,
        json={
            "first_name": "John",
            "last_name": "Doe",
            "date_of_birth": "1990-01-01",
            "gender": "M",
        },
    )
    assert traveler_response.status_code == 200
    traveler_id = traveler_response.json()["traveler"]["id"]

    # 3. Créer une conversation
    conv_response = client.post(
        f"/v1/trips/{trip_id}/conversations",
        headers=headers,
        json={"title": "Planification"},
    )
    assert conv_response.status_code == 201
    conversation_id = conv_response.json()["conversation"]["id"]

    # 4. Envoyer un message au chat (simuler sans SSE pour le test)
    # Note: Le test réel nécessiterait un client SSE, donc on teste juste l'endpoint
    chat_response = client.post(
        "/v1/agent/chat",
        headers=headers,
        json={
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "message": "Je veux aller à Paris du 1er au 5 janvier",
            "context_version": None,
        },
    )
    # L'endpoint retourne un stream, donc on vérifie juste le status
    assert chat_response.status_code == 200

    # 5. Vérifier que les messages sont persistés
    messages_response = client.get(
        f"/v1/conversations/{conversation_id}/messages",
        headers=headers,
    )
    assert messages_response.status_code == 200
    messages = messages_response.json()["items"]
    assert len(messages) >= 1  # Au moins le message utilisateur


def test_context_version_mismatch(
    auth_token: str, db: Session, test_user: User
):
    """Test de gestion du context version mismatch."""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # Créer trip et conversation
    trip_response = client.post(
        "/v1/trips",
        headers=headers,
        json={
            "title": "Test Trip",
            "destinationName": "Paris",
            "startDate": "2099-06-01",
            "endDate": "2099-06-10",
        },
    )
    trip_id = trip_response.json()["trip"]["id"]

    conv_response = client.post(
        f"/v1/trips/{trip_id}/conversations",
        headers=headers,
        json={"title": "Test"},
    )
    conversation_id = conv_response.json()["conversation"]["id"]

    # Envoyer un premier message pour créer le contexte
    client.post(
        "/v1/agent/chat",
        headers=headers,
        json={
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "message": "Premier message",
            "context_version": None,
        },
    )

    # Envoyer un deuxième message avec un context_version incorrect
    chat_response = client.post(
        "/v1/agent/chat",
        headers=headers,
        json={
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "message": "Deuxième message",
            "context_version": 999,  # Version incorrecte
        },
    )

    assert chat_response.status_code == 409
    assert "stale_context" in chat_response.json()["detail"]["error"]


def test_rate_limiting(auth_token: str, db: Session, test_user: User):
    """Test du rate limiting."""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # Créer trip et conversation
    trip_response = client.post(
        "/v1/trips",
        headers=headers,
        json={
            "title": "Test Trip",
            "destinationName": "Paris",
            "startDate": "2099-06-01",
            "endDate": "2099-06-10",
        },
    )
    trip_id = trip_response.json()["trip"]["id"]

    conv_response = client.post(
        f"/v1/trips/{trip_id}/conversations",
        headers=headers,
        json={"title": "Test"},
    )
    conversation_id = conv_response.json()["conversation"]["id"]

    # Envoyer plus de 10 requêtes rapidement
    responses = []
    for i in range(12):
        response = client.post(
            "/v1/agent/chat",
            headers=headers,
            json={
                "trip_id": trip_id,
                "conversation_id": conversation_id,
                "message": f"Message {i}",
            },
        )
        responses.append(response.status_code)

    # Les premières doivent être 200, les dernières 429
    assert 200 in responses[:10]  # Au moins certaines des 10 premières sont 200
    assert 429 in responses[10:]  # Au moins une des 2 dernières est 429


def test_rbac_unauthorized_access(
    auth_token: str, auth_token2: str, db: Session, test_user: User, test_user2: User
):
    """Test de RBAC - accès non autorisé."""
    headers1 = {"Authorization": f"Bearer {auth_token}"}
    headers2 = {"Authorization": f"Bearer {auth_token2}"}

    # User1 crée un trip et une conversation
    trip_response = client.post(
        "/v1/trips",
        headers=headers1,
        json={
            "title": "User1 Trip",
            "destinationName": "Paris",
            "startDate": "2099-06-01",
            "endDate": "2099-06-10",
        },
    )
    trip_id = trip_response.json()["trip"]["id"]

    conv_response = client.post(
        f"/v1/trips/{trip_id}/conversations",
        headers=headers1,
        json={"title": "User1 Conversation"},
    )
    conversation_id = conv_response.json()["conversation"]["id"]

    # User2 tente d'accéder aux ressources de User1
    # Tenter d'accéder à la conversation
    response = client.get(
        f"/v1/conversations/{conversation_id}",
        headers=headers2,
    )
    assert response.status_code == 403

    # Tenter d'accéder aux messages
    response = client.get(
        f"/v1/conversations/{conversation_id}/messages",
        headers=headers2,
    )
    assert response.status_code == 403

    # Tenter d'envoyer un message au chat
    response = client.post(
        "/v1/agent/chat",
        headers=headers2,
        json={
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "message": "Unauthorized message",
        },
    )
    assert response.status_code == 403
