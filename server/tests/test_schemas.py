import pytest
from pydantic import ValidationError

from app.names import clean_name
from app.schemas import RunIn


def run(**over):
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


@pytest.mark.parametrize(
    ("raw", "clean"),
    [("  alice  ", "alice"), ("Al!ce<script>", "Alcescript"), ("a" * 30, "a" * 16), ("Mad  Hatter_9", "Mad Hatter_9")],
)
def test_clean_name(raw, clean):
    assert clean_name(raw) == clean


@pytest.mark.parametrize("raw", ["", "   ", "!!!", "xX_nazi_Xx"])
def test_clean_name_rejects(raw):
    with pytest.raises(ValueError):
        clean_name(raw)


def test_guide_example_run_is_valid():
    assert RunIn(**run()).player_name == "alice"


@pytest.mark.parametrize(
    "over",
    [
        {"battles_won": 6},
        {"battles_won": -1},
        {"time_ms": 29_999},
        {"time_ms": 2 * 60 * 60 * 1000},
        {"won": True, "battles_won": 4},
        {"won": False, "battles_won": 5},
        {"stats": {"rounds": 3, "busts": 4, "blackjacks": 0, "cards_played": {}}},
        {"stats": {"rounds": 3, "busts": 0, "blackjacks": 4, "cards_played": {}}},
        {"stats": {"rounds": 3, "busts": 0, "blackjacks": 0, "cards_played": {"DROP TABLE": 1}}},
        {"game_version": "latest"},
        {"act": "Act 3!"},
        {"player_name": "!!!"},
    ],
)
def test_invalid_runs_are_rejected(over):
    with pytest.raises(ValidationError):
        RunIn(**run(**over))
