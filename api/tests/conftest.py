import os

# Set dummy environment variables to satisfy Pydantic validation during collection
# These must be set before modules are imported
os.environ.setdefault("AMADEUS_CLIENT_ID", "dummy_client_id")
os.environ.setdefault("AMADEUS_CLIENT_SECRET", "dummy_client_secret")
os.environ.setdefault("GOOGLE_API_KEY", "dummy_google_key")
