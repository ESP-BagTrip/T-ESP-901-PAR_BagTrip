import sqlalchemy
from sqlalchemy import create_engine, text
import os

url = "postgresql://postgres:postgres@localhost:5432/postgres"
print(f"Connecting to {url}...")
try:
    engine = create_engine(url)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print(f"Success! Result: {result.scalar()}")
except Exception as e:
    print(f"Connection failed: {e}")
