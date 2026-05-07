"""Cloudflare R2 / Supabase Storage client wrapper.

Phase 0 writes to a local cache directory only (`./.cache/blobs/<sha256>`).
The live R2 path activates when settings.live_apis is true AND the R2
bucket exists. The bucket is NOT provisioned in this Phase 0 pass.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path

from .config import settings

log = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class StoredBlob:
    storage_path: str           # logical path (e.g. "guideline-blobs/sha256/abc...")
    backend: str                # "local-cache" | "r2" | "supabase-storage"
    bytes_written: int


def store_blob(payload: bytes, *, sha256: str, mime: str | None = None) -> StoredBlob:
    if settings.live_apis and settings.r2_account_id:
        # TODO[Phase 1+]: invoke boto3 client against the R2 bucket. Skipped
        # in Phase 0 because the bucket isn't provisioned and this would error.
        raise NotImplementedError(
            "R2 upload not implemented in Phase 0; provision the bucket first."
        )

    cache_dir = Path(".cache/blobs") / sha256[:2]
    cache_dir.mkdir(parents=True, exist_ok=True)
    out = cache_dir / sha256
    out.write_bytes(payload)
    log.info("blob cached locally", extra={"sha256": sha256, "bytes": len(payload)})
    return StoredBlob(
        storage_path=f"local-cache://{out}",
        backend="local-cache",
        bytes_written=len(payload),
    )
