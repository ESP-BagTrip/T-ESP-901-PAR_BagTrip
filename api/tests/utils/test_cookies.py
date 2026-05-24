"""Unit tests for cookie helpers — prefix isolation across envs."""

from fastapi import Response

from src.utils import cookies


def test_cookie_names_default_prefix(monkeypatch):
    monkeypatch.setattr(cookies.settings, "COOKIE_NAME_PREFIX", "")

    assert cookies.access_cookie_name() == "access_token"
    assert cookies.refresh_cookie_name() == "refresh_token"
    assert cookies.status_cookie_name() == "auth-status"


def test_cookie_names_with_prefix(monkeypatch):
    monkeypatch.setattr(cookies.settings, "COOKIE_NAME_PREFIX", "dev_")

    assert cookies.access_cookie_name() == "dev_access_token"
    assert cookies.refresh_cookie_name() == "dev_refresh_token"
    assert cookies.status_cookie_name() == "dev_auth-status"


def test_set_auth_cookies_uses_prefixed_names(monkeypatch):
    monkeypatch.setattr(cookies.settings, "COOKIE_NAME_PREFIX", "dev_")
    monkeypatch.setattr(cookies.settings, "COOKIE_DOMAIN", None)
    monkeypatch.setattr(cookies.settings, "COOKIE_SECURE", False)

    response = Response()
    cookies.set_auth_cookies(response, "access-val", "refresh-val", expires_in=3600)

    set_cookies_header = response.headers.getlist("set-cookie")
    joined = " | ".join(set_cookies_header)

    assert "dev_access_token=access-val" in joined
    assert "dev_refresh_token=refresh-val" in joined
    assert "dev_auth-status=authenticated" in joined
    # Unprefixed names must NOT appear — isolation is the whole point.
    assert "access_token=access-val" not in joined.replace("dev_access_token", "")
    assert "refresh_token=refresh-val" not in joined.replace("dev_refresh_token", "")


def test_clear_auth_cookies_uses_prefixed_names(monkeypatch):
    monkeypatch.setattr(cookies.settings, "COOKIE_NAME_PREFIX", "dev_")
    monkeypatch.setattr(cookies.settings, "COOKIE_DOMAIN", None)

    response = Response()
    cookies.clear_auth_cookies(response)

    joined = " | ".join(response.headers.getlist("set-cookie"))

    assert "dev_access_token" in joined
    assert "dev_refresh_token" in joined
    assert "dev_auth-status" in joined
