"""Request-ID middleware + contextvar-backed log correlation.

Every request gets a stable identifier that flows through every log line the
handler produces. We prefer the upstream `X-Request-ID` header when present
(lets proxies / load balancers / clients propagate a single id across hops),
otherwise we mint a fresh UUID4.

The id lives in a `contextvars.ContextVar` so any log call — anywhere in the
call tree, including inside services and repositories — can read it without
passing it through every function signature. The logging.Filter below pulls
the value and stamps it into `LogRecord.request_id`, which the formatter then
emits as `[rid=...]`.

`X-Request-ID` is reflected back in the response so clients can grep the
server logs for a given interaction.
"""

from __future__ import annotations

import logging
import uuid
from collections.abc import Awaitable, Callable
from contextvars import ContextVar

from fastapi import Request, Response

_REQUEST_ID_HEADER = "X-Request-ID"
_request_id_ctx: ContextVar[str | None] = ContextVar("request_id", default=None)


def get_request_id() -> str | None:
    """Return the current request id (or None if no request is active)."""
    return _request_id_ctx.get()


async def request_id_middleware(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]],
) -> Response:
    """Attach a request id to every response + every log line produced inline."""
    incoming = request.headers.get(_REQUEST_ID_HEADER)
    request_id = incoming or uuid.uuid4().hex
    token = _request_id_ctx.set(request_id)
    try:
        response = await call_next(request)
    finally:
        _request_id_ctx.reset(token)
    response.headers[_REQUEST_ID_HEADER] = request_id
    return response


class RequestIdLogFilter(logging.Filter):
    """Inject the current request id and OTEL trace id into every LogRecord.

    Formatter templates can reference `%(request_id)s` and `%(trace_id)s`.
    Records produced outside a request (schedulers, lifespan, boot) get a
    placeholder so format strings never raise KeyError. The trace id is
    pulled from the active OTEL span context — when tracing is disabled or
    no span is active, it falls back to the same `-` placeholder, so
    Loki / Grafana queries can rely on the field being present.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = _request_id_ctx.get() or "-"
        record.trace_id = _current_trace_id()
        return True


def _current_trace_id() -> str:
    """Return the current OTEL trace id as 32-char hex, or '-' if absent."""
    try:
        from opentelemetry import trace as _otel_trace

        span_ctx = _otel_trace.get_current_span().get_span_context()
        if span_ctx.is_valid:
            return f"{span_ctx.trace_id:032x}"
    except Exception:
        # OTEL API not importable (deps missing) or any unexpected failure —
        # logging must never break the request path.
        pass
    return "-"
