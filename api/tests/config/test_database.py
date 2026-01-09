"""Unit tests for the database configuration."""

from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy.exc import SQLAlchemyError

from src.config.database import clean_database_url, check_database_connection, get_db


class TestCleanDatabaseUrl:
    """Tests for clean_database_url function."""

    def test_clean_database_url_removes_schema(self):
        """Test that 'schema' parameter is removed."""
        url = "postgresql://user:pass@localhost:5432/db?schema=public&other=val"
        cleaned = clean_database_url(url)
        assert "schema=public" not in cleaned
        assert "other=val" in cleaned

    def test_clean_database_url_no_schema(self):
        """Test URL without 'schema' parameter is unchanged (semantically)."""
        url = "postgresql://user:pass@localhost:5432/db?other=val"
        cleaned = clean_database_url(url)
        assert "other=val" in cleaned
        assert "schema" not in cleaned


class TestCheckDatabaseConnection:
    """Tests for check_database_connection function."""

    @patch("src.config.database.engine")
    def test_check_connection_success(self, mock_engine):
        """Test successful connection check."""
        mock_conn = MagicMock()
        mock_engine.connect.return_value.__enter__.return_value = mock_conn
        
        check_database_connection()
        mock_conn.execute.assert_called_once()

    @patch("src.config.database.engine")
    def test_check_connection_failure(self, mock_engine):
        """Test connection failure raises ConnectionError."""
        mock_engine.connect.side_effect = SQLAlchemyError("DB Error")
        
        with pytest.raises(ConnectionError) as exc_info:
            check_database_connection()
        assert "Failed to connect to database" in str(exc_info.value)


class TestGetDb:
    """Tests for get_db dependency."""

    @patch("src.config.database.SessionLocal")
    def test_get_db(self, mock_session_local):
        """Test get_db yields session and closes it."""
        mock_session = MagicMock()
        mock_session_local.return_value = mock_session
        
        gen = get_db()
        session = next(gen)
        
        assert session == mock_session
        
        with pytest.raises(StopIteration):
            next(gen)
        
        mock_session.close.assert_called_once()
