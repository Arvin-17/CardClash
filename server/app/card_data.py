"""The shared cards.json, read once at startup."""

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CardData:
    raw: bytes
    etag: str
    version: int
    ids: frozenset[str]

    @classmethod
    def load(cls, data_dir: Path) -> "CardData | None":
        path = data_dir / "cards.json"
        try:
            raw = path.read_bytes()
            parsed = json.loads(raw)
        except (OSError, ValueError):
            return None
        return cls(
            raw=raw,
            etag='"' + hashlib.sha256(raw).hexdigest()[:16] + '"',
            version=int(parsed.get("version", 0)),
            ids=frozenset(c["id"] for c in parsed.get("cards", [])),
        )
