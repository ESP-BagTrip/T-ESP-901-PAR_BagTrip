import importlib.util
import os
import sys
from unittest.mock import MagicMock

# Mock stripe if not installed
if importlib.util.find_spec("stripe") is None:
    sys.modules["stripe"] = MagicMock()

# Set dummy environment variables to satisfy Pydantic validation during collection
# These must be set before modules are imported
os.environ.setdefault("AMADEUS_CLIENT_ID", "dummy_client_id")
os.environ.setdefault("AMADEUS_CLIENT_SECRET", "dummy_client_secret")
os.environ.setdefault("LLM_API_KEY", "dummy_llm_key")
