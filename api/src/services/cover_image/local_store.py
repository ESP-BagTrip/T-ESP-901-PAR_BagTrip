"""Content-addressed local image store (SMP-330).

External cover URLs (Wikipedia/Commons) are brittle: files get renamed,
licenses change, the URL stops working months later and the app shows a
broken image. Re-hosting every accepted cover under
``COVERS_STORAGE_DIR/<sha256>.<ext>`` solves three problems at once:

- the URL is permanent and served from the same domain as the app, no
  CORS surprises, no third-party uptime risk;
- duplicates collapse automatically (two trips to "Paris" pick the same
  Wikipedia photo → one file on disk);
- the rehosted files fit cleanly into the existing Restic backup
  (cf. ``infra/observability_stack`` Phase 6) so a disk loss restores
  cleanly without re-querying Wikipedia.

Files are written atomically (``tmp`` + ``os.replace``) so a concurrent
read never sees a half-written PNG.
"""

from __future__ import annotations

import contextlib
import hashlib
import mimetypes
import os
import tempfile
from pathlib import Path

from src.config.env import settings
from src.integrations.cover_image._http import DEFAULT_TIMEOUT_S, WIKIMEDIA_HEADERS
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

# Map common image content types to a stable extension. We trust the server's
# Content-Type more than the URL suffix because Commons serves ``.jpg`` URLs
# whose actual payload is a WebP/JPEG depending on the thumbnailer used.
_CONTENT_TYPE_EXT = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}

_MAX_BYTES = 8 * 1024 * 1024  # 8 MB — well above Wikipedia ``originalimage`` sizes


class LocalCoverStore:
    """Content-addressed disk store for re-hosted cover images."""

    def __init__(
        self,
        storage_dir: str | None = None,
        public_base_url: str | None = None,
    ) -> None:
        self._dir = Path(storage_dir or settings.COVERS_STORAGE_DIR)
        self._public_base = (public_base_url or settings.COVERS_PUBLIC_URL_BASE).rstrip("/")
        # Directory creation is deferred to the first write so importing
        # this module never requires write access to ``/var/lib/...``.
        # Tests (and most read-only contexts) never trigger it.
        self._dir_ready = False

    def _ensure_dir(self) -> None:
        if not self._dir_ready:
            self._dir.mkdir(parents=True, exist_ok=True)
            self._dir_ready = True

    def public_url(self, file_name: str) -> str:
        return f"{self._public_base}/{file_name}"

    def _has(self, file_name: str) -> bool:
        return (self._dir / file_name).exists()

    @staticmethod
    def _ext_for(content_type: str | None, url: str) -> str:
        if content_type:
            mapped = _CONTENT_TYPE_EXT.get(content_type.split(";")[0].strip().lower())
            if mapped:
                return mapped
        guessed, _ = mimetypes.guess_type(url)
        return _CONTENT_TYPE_EXT.get(guessed or "", ".jpg")

    def _atomic_write(self, dest: Path, data: bytes) -> None:
        # Same-dir tempfile so ``os.replace`` is atomic across the rename.
        fd, tmp_path = tempfile.mkstemp(prefix=".cover_", dir=str(self._dir))
        try:
            with os.fdopen(fd, "wb") as fh:
                fh.write(data)
            os.replace(tmp_path, dest)
        except Exception:
            # Clean up the tempfile if rename failed for any reason.
            with contextlib.suppress(OSError):
                os.unlink(tmp_path)
            raise

    async def fetch_and_store(self, url: str) -> str | None:
        """Download ``url``, save under ``sha256.<ext>``, return public URL.

        Returns ``None`` on any download/storage failure — the orchestrator
        treats this provider as a miss and tries the next candidate.
        """
        if not url:
            return None
        try:
            client = get_http_client()
            resp = await client.get(
                url,
                headers=WIKIMEDIA_HEADERS,
                timeout=DEFAULT_TIMEOUT_S,
                follow_redirects=True,
            )
        except Exception as exc:
            logger.warn(f"Cover rehost: GET failed for {url}: {exc}")
            return None

        if resp.status_code >= 400:
            logger.warn(f"Cover rehost: {resp.status_code} for {url}")
            return None

        data = resp.content
        if not data:
            return None
        if len(data) > _MAX_BYTES:
            logger.warn(f"Cover rehost: {url} too large ({len(data)} bytes), skipping")
            return None

        digest = hashlib.sha256(data).hexdigest()
        ext = self._ext_for(resp.headers.get("content-type"), url)
        file_name = f"{digest}{ext}"
        dest = self._dir / file_name

        if not self._has(file_name):
            try:
                self._ensure_dir()
                self._atomic_write(dest, data)
            except OSError as exc:
                logger.warn(f"Cover rehost: write failed for {dest}: {exc}")
                return None

        return self.public_url(file_name)


local_cover_store = LocalCoverStore()
