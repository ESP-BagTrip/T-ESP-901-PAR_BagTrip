"""Cover-image orchestration service (SMP-330).

Owns the no-API-key pipeline that picks a destination cover, re-hosts it
locally so external links can never break, and caches the result by
``(destination, locale)``. Exposes a single entry point that callers in
``trips/routes.py`` and the AI plan orchestrators use in place of the
old direct Unsplash call.
"""
