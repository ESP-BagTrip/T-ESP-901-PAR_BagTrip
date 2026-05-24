"""Logger simple pour l'application."""

import logging
import os
from enum import IntEnum
from typing import Any

from src.middleware.request_id import RequestIdLogFilter


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

        # Handler console. Each record gets a `request_id` attribute via the
        # filter below, and the formatter stamps it into every line so the
        # output can be `grep`-ed by a single request from proxy → service.
        handler = logging.StreamHandler()
        handler.setLevel(logging.DEBUG)
        handler.addFilter(RequestIdLogFilter())
        formatter = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] [rid=%(request_id)s] "
            "[trace_id=%(trace_id)s] %(message)s",
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

    def warning(self, message: str, data: Any | None = None, exc_info: bool = False) -> None:
        """Log warning (alias for warn, compatible with standard logging API)."""
        if self._should_log(LogLevel.WARN):
            if exc_info and self.level == LogLevel.DEBUG:
                # En mode debug, afficher la traceback complète
                if data:
                    import json

                    formatted_data = json.dumps(data, indent=2, default=str)
                    full_message = f"{message}\n{formatted_data}"
                else:
                    full_message = message
                self._logger.warning(full_message, exc_info=True)
            else:
                self._logger.warning(self._format_message("WARN", message, data))

    def error(self, message: str, data: Any | None = None, exc_info: bool = False) -> None:
        """Log error."""
        if self._should_log(LogLevel.ERROR):
            if exc_info and self.level == LogLevel.DEBUG:
                # En mode debug, afficher la traceback complète
                # Ne pas formater le message quand exc_info=True pour préserver le contexte
                if data:
                    import json

                    formatted_data = json.dumps(data, indent=2, default=str)
                    full_message = f"{message}\n{formatted_data}"
                else:
                    full_message = message
                self._logger.error(full_message, exc_info=True)
            else:
                self._logger.error(self._format_message("ERROR", message, data))

    def set_level(self, level: LogLevel) -> None:
        """Change le niveau de log."""
        self.level = level


log_level = LogLevel.DEBUG if os.getenv("NODE_ENV") == "development" else LogLevel.INFO
logger = Logger(log_level)

# Log de configuration au démarrage
logger.info(f"[LOGGER] Initialized with level: {LogLevel(log_level).name} ({log_level})")
logger.info(f"[LOGGER] NODE_ENV: {os.getenv('NODE_ENV', 'development')}")
