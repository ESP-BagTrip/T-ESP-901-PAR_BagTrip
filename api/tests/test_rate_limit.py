"""Tests for the per-IP auth rate-limit middleware."""

from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.middleware.rate_limit import (
    _AUTH_RATE_LIMIT_MAX,
    _AUTH_RATE_LIMITED_PATHS,
    auth_rate_limit_middleware,
)


def _app() -> FastAPI:
    app = FastAPI()
    app.middleware("http")(auth_rate_limit_middleware)

    @app.post("/v1/auth/forgot-password")
    async def forgot_password():
        return {"ok": True}

    @app.post("/v1/auth/reset-password")
    async def reset_password():
        return {"ok": True}

    return app


def test_reset_endpoints_are_in_the_limited_set():
    assert "/v1/auth/forgot-password" in _AUTH_RATE_LIMITED_PATHS
    assert "/v1/auth/reset-password" in _AUTH_RATE_LIMITED_PATHS


def test_forgot_password_returns_429_over_the_limit():
    client = TestClient(_app())
    # Distinct IP so the shared in-memory counter doesn't collide with siblings.
    headers = {"X-Forwarded-For": "203.0.113.11"}
    for _ in range(_AUTH_RATE_LIMIT_MAX):
        assert client.post("/v1/auth/forgot-password", headers=headers).status_code == 200
    over = client.post("/v1/auth/forgot-password", headers=headers)
    assert over.status_code == 429
    assert over.headers.get("Retry-After")


def test_reset_password_returns_429_over_the_limit():
    client = TestClient(_app())
    headers = {"X-Forwarded-For": "203.0.113.12"}
    for _ in range(_AUTH_RATE_LIMIT_MAX):
        assert client.post("/v1/auth/reset-password", headers=headers).status_code == 200
    assert client.post("/v1/auth/reset-password", headers=headers).status_code == 429
