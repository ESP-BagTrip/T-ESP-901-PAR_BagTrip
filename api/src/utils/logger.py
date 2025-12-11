"""Logger simple pour l'application."""

import logging
import os
from enum import IntEnum
from typing import Any


class LogLevel(IntEnum):
    """Niveaux de log."""

    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3


class Logger:
    """Logger simple avec niveaux de log."""

    def __init__(self, level: LogLevel = LogLevel.INFO):
        """Initialise le logger."""
        self.level = level
        self._logger = logging.getLogger(__name__)
        self._logger.setLevel(logging.DEBUG)

        # Handler console
        handler = logging.StreamHandler()
        handler.setLevel(logging.DEBUG)
        formatter = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        handler.setFormatter(formatter)
        self._logger.addHandler(handler)

    def _should_log(self, level: LogLevel) -> bool:
        """Vérifie si le niveau de log doit être affiché."""
        return level >= self.level

    def _format_message(self, level: str, message: str, data: Any | None = None) -> str:
        """Formate le message de log."""
        if data:
            import json

            return f"{message} {json.dumps(data, indent=2, default=str)}"
        return message

    def debug(self, message: str, data: Any | None = None) -> None:
        """Log debug."""
        if self._should_log(LogLevel.DEBUG):
            self._logger.debug(self._format_message("DEBUG", message, data))

    def info(self, message: str, data: Any | None = None) -> None:
        """Log info."""
        if self._should_log(LogLevel.INFO):
            self._logger.info(self._format_message("INFO", message, data))

    def warn(self, message: str, data: Any | None = None) -> None:
        """Log warning."""
        if self._should_log(LogLevel.WARN):
            self._logger.warning(self._format_message("WARN", message, data))

    def error(self, message: str, data: Any | None = None) -> None:
        """Log error."""
        if self._should_log(LogLevel.ERROR):
            self._logger.error(self._format_message("ERROR", message, data))

    def set_level(self, level: LogLevel) -> None:
        """Change le niveau de log."""
        self.level = level


log_level = LogLevel.DEBUG if os.getenv("NODE_ENV") == "development" else LogLevel.INFO
logger = Logger(log_level)

# Log de configuration au démarrage
logger.info(f"[LOGGER] Initialized with level: {LogLevel(log_level).name} ({log_level})")
logger.info(f"[LOGGER] NODE_ENV: {os.getenv('NODE_ENV', 'development')}")
