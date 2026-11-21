"""Settings from environment variables (or server/.env locally)."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # SQLite locally and for the demo; any SQLAlchemy URL (e.g. Postgres) works if the host needs it.
    database_url: str = "sqlite:///./cardclash.db"
    # Secret for admin-only endpoints. Empty = admin endpoints disabled.
    admin_key: str = ""
    # Comma-separated origins allowed by CORS. Godot's "Run in browser" serves on :8060.
    allowed_origins: str = "http://localhost:8060,http://127.0.0.1:8060,http://localhost:8000"
    # Runs from builds older than this are rejected so stale balance doesn't pollute the board.
    game_version: str = "0.1.0"
    # The shared data folder: one copy of every card, read at startup.
    data_dir: Path = REPO_ROOT / "game" / "data"
    # Per-IP limit for POST /run.
    run_rate_limit: str = "10/minute"

    @property
    def origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
