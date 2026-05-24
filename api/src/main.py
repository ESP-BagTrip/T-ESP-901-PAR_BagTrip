"""Point d'entrée FastAPI."""

import traceback

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator

from src.config.database import engine
from src.config.env import settings
from src.middleware.rate_limit import auth_rate_limit_middleware, rate_limit_middleware
from src.middleware.request_id import request_id_middleware
from src.middleware.security_headers import security_headers_middleware
from src.router_registry import register_routers
from src.startup import lifespan
from src.utils.errors import AppError
from src.utils.logger import LogLevel, logger

app = FastAPI(
    title="BagTrip API",
    description="API Python pour BagTrip avec intégration Amadeus",
    version="1.0.0",
    lifespan=lifespan,
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiting middleware (après CORS)
app.middleware("http")(rate_limit_middleware)
app.middleware("http")(auth_rate_limit_middleware)

# Security headers — added after auth middlewares so they wrap every response.
app.middleware("http")(security_headers_middleware)

# Request-ID middleware must run OUTERMOST — FastAPI runs middlewares in
# reverse registration order, so registering last means this is the first
# middleware to see the request and the last to see the response. That way
# every other middleware and handler logs with the request id already set.
app.middleware("http")(request_id_middleware)

# Prometheus instrumentation — RED metrics (request rate, error rate,
# latency histogram) on /metrics. Public access is blocked at the inner
# Caddyfile so api.bagtrip.fr/metrics returns 404; Prometheus scrapes the
# container directly through the internal docker network.
Instrumentator(
    should_group_status_codes=True,
    should_ignore_untemplated=False,
    should_instrument_requests_inprogress=True,
    # Patterns are matched with re.search, so anchor them to exact routes;
    # otherwise "/" matches every path and all handlers are silently excluded.
    excluded_handlers=[r"^/metrics$", r"^/health$", r"^/$"],
    inprogress_name="http_requests_inprogress",
    inprogress_labels=True,
).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False, tags=["monitoring"])

# OpenTelemetry distributed tracing — enabled when OTEL_EXPORTER_OTLP_ENDPOINT
# is set (e.g. `http://tempo:4317` in production). FastAPI / SQLAlchemy / Redis
# / HTTPX are auto-instrumented; spans flow to Grafana Tempo via OTLP gRPC.
# Tracing is silent in dev/test where the env var is unset.
if settings.OTEL_EXPORTER_OTLP_ENDPOINT:
    from opentelemetry import trace as _otel_trace
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
    from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
    from opentelemetry.instrumentation.redis import RedisInstrumentor
    from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.sdk.trace.sampling import TraceIdRatioBased

    _otel_resource = Resource.create(
        {
            "service.name": settings.OTEL_SERVICE_NAME,
            "service.version": "1.0.0",
            "deployment.environment": settings.NODE_ENV,
        }
    )
    _otel_provider = TracerProvider(
        resource=_otel_resource,
        sampler=TraceIdRatioBased(settings.OTEL_TRACES_SAMPLER_ARG),
    )
    _otel_provider.add_span_processor(
        BatchSpanProcessor(
            OTLPSpanExporter(endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT, insecure=True)
        )
    )
    _otel_trace.set_tracer_provider(_otel_provider)
    # excluded_urls is a comma-separated list of regex patterns matched with
    # re.search against the request URL. Anchor each one or "/" matches every
    # path and OTEL silently drops every span.
    FastAPIInstrumentor.instrument_app(app, excluded_urls=r"^/metrics$,^/health$,^/$")
    SQLAlchemyInstrumentor().instrument(engine=engine, enable_commenter=False)
    RedisInstrumentor().instrument()
    HTTPXClientInstrumentor().instrument()
    logger.info(f"OpenTelemetry tracing enabled (endpoint={settings.OTEL_EXPORTER_OTLP_ENDPOINT})")

# Inclusion des routes - toutes sous /v1 (ordre préservé dans router_registry)
register_routers(app)

# SMP-330 — local cover-image static mount. In prod the request never
# reaches FastAPI because Caddy intercepts ``/covers/*`` first (see
# Caddyfile + compose.prod.yml volume mount). In dev there is no Caddy
# in front, so FastAPI itself serves the rehosted Wikipedia/Commons
# photos at the same URL shape, keeping the client config identical.
# ``check_dir=False`` means we don't fail to start when the directory
# does not exist yet — the LocalCoverStore creates it on first write.
app.mount(
    "/covers",
    StaticFiles(directory=settings.COVERS_STORAGE_DIR, check_dir=False),
    name="covers",
)


# Gestion globale des erreurs
@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    """Gestionnaire d'erreurs pour AppError."""
    # Logger l'erreur avec plus de détails en mode debug
    if logger.level == LogLevel.DEBUG:
        logger.error(
            f"AppError: {exc.code}",
            {
                "code": exc.code,
                "status_code": exc.status_code,
                "message": exc.message,
                "detail": exc.detail,
                "path": request.url.path,
                "method": request.method,
            },
        )

    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": {
                "error": exc.message,
                "code": exc.code,
                **(exc.detail or {}),
            }
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Gestionnaire d'erreurs général.

    In production (non-DEBUG) the response is a generic 500 with no exception
    text — otherwise raw SQL / psycopg2 messages end up in the Flutter dev
    console and shared error logs. In DEBUG mode we still surface the full
    payload (message + type + traceback) to make local debugging easy.
    Server-side logs always receive the rich context.
    """
    log_context = {
        "error": str(exc),
        "type": type(exc).__name__,
        "path": request.url.path,
        "method": request.method,
    }
    is_debug = logger.level == LogLevel.DEBUG
    if is_debug:
        log_context["traceback"] = traceback.format_exc()
        logger.error(
            f"Unhandled exception: {type(exc).__name__}",
            log_context,
            exc_info=True,
        )
    else:
        logger.error("Unhandled exception", log_context)

    if is_debug:
        return JSONResponse(
            status_code=500,
            content={
                "error": "Internal server error",
                "detail": {
                    "error": str(exc),
                    "type": type(exc).__name__,
                    "traceback": traceback.format_exc(),
                },
            },
        )
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error"},
    )


@app.get("/")
async def root():
    """Route racine."""
    return {"message": "BagTrip API", "version": "1.0.0"}


if __name__ == "__main__":
    import uvicorn

    # Bandit B104: binding inside docker is intentional — the container only
    # exposes the port through the docker-compose network, not public internet.
    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",  # nosec B104
        port=settings.PORT,
        reload=settings.NODE_ENV == "development",
        log_level="debug" if settings.NODE_ENV == "development" else "info",
    )
