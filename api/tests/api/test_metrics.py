"""Tests for the Prometheus /metrics endpoint added in Phase 1b."""

from fastapi import FastAPI
from fastapi.testclient import TestClient
from prometheus_fastapi_instrumentator import Instrumentator


def test_metrics_endpoint_serves_prometheus_text() -> None:
    """The instrumentator exposes /metrics with the Prometheus exposition format."""
    app = FastAPI()

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)

    client = TestClient(app)
    # Generate at least one observable request so the counter is emitted.
    client.get("/health")

    response = client.get("/metrics")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    body = response.text
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body


def test_metrics_route_registered_in_main_app() -> None:
    """`src.main.app` registers the /metrics route via the instrumentator."""
    from src.main import app

    paths = {getattr(route, "path", "") for route in app.routes}
    assert "/metrics" in paths


def test_metrics_endpoint_excluded_from_openapi_schema() -> None:
    """The /metrics endpoint must not leak into the public OpenAPI schema."""
    from src.main import app

    schema_paths = set(app.openapi().get("paths", {}).keys())
    assert "/metrics" not in schema_paths
