"""Domain-specific webhook handlers.

Each module exports a single function that takes `(db, event, stripe_event)`
and applies the side effect for one event family. The dispatcher in
`service.py` decides which handler runs based on `event.type`.
"""
