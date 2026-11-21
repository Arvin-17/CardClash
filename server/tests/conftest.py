import datetime as dt

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.db import utc_today
from app.main import create_app

TODAY = dt.date(2026, 11, 21)


@pytest.fixture
def settings() -> Settings:
    return Settings(database_url="sqlite://", admin_key="test-admin", game_version="0.1.0")


@pytest.fixture
def day() -> dict:
    """Mutable 'today' so tests can roll the date over."""
    return {"today": TODAY}


@pytest.fixture
def app(settings: Settings, day: dict):
    app = create_app(settings)
    app.dependency_overrides[utc_today] = lambda: day["today"]
    return app


@pytest.fixture
def client(app) -> TestClient:
    with TestClient(app) as c:
        yield c


def make_run(**over) -> dict:
    """The guide's example payload, tweakable per test."""
    data = {
        "player_name": "alice",
        "seed": 834201933,
        "is_daily": False,
        "won": True,
        "act": "act3_court",
        "battles_won": 5,
        "time_ms": 512000,
        "stats": {"rounds": 31, "busts": 7, "blackjacks": 3, "cards_played": {"drink_me": 4}},
        "game_version": "0.1.0",
    }
    data.update(over)
    return data
