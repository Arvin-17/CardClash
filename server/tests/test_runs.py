import datetime as dt

from sqlmodel import Session, select

from app.models import Run
from tests.conftest import make_run


def test_submit_run_returns_201_with_id_and_rank(client):
    r = client.post("/run", json=make_run())
    assert r.status_code == 201
    assert r.json() == {"id": 1, "rank": 1}


def test_rank_orders_winners_then_battles_then_time(client):
    client.post("/run", json=make_run(player_name="fast", time_ms=300_000))
    client.post("/run", json=make_run(player_name="slow", time_ms=600_000))
    middle = client.post("/run", json=make_run(player_name="middle", time_ms=450_000))
    three_wins = client.post("/run", json=make_run(player_name="three", won=False, battles_won=3, time_ms=90_000))
    four_wins = client.post("/run", json=make_run(player_name="four", won=False, battles_won=4, time_ms=100_000))
    assert middle.json()["rank"] == 2  # only "fast" is quicker
    assert three_wins.json()["rank"] == 4  # every winner beats a loss, however fast
    assert four_wins.json()["rank"] == 4  # more battles won beats a faster loss


def test_rank_ignores_your_own_better_runs(client):
    client.post("/run", json=make_run(player_name="alice", time_ms=200_000))
    again = client.post("/run", json=make_run(player_name="Alice", time_ms=400_000))
    assert again.json()["rank"] == 1


def test_server_stores_cleaned_name_and_server_time(client, app):
    before = dt.datetime.now(dt.UTC).replace(tzinfo=None)
    client.post("/run", json=make_run(player_name="  Mad Hatter!! ", created_at="1999-01-01T00:00:00"))
    with Session(app.state.engine) as s:
        run = s.exec(select(Run)).one()
    assert run.player_name == "Mad Hatter"
    assert run.created_at.replace(tzinfo=None) >= before
    assert run.cards_played == {"drink_me": 4}


def test_invalid_payload_is_422(client):
    assert client.post("/run", json=make_run(battles_won=9)).status_code == 422
    assert client.post("/run", json={"player_name": "alice"}).status_code == 422


def test_outdated_game_version_is_rejected(client):
    r = client.post("/run", json=make_run(game_version="0.0.9"))
    assert r.status_code == 422
    assert "outdated" in r.json()["detail"]
    assert client.post("/run", json=make_run(game_version="0.2.0")).status_code == 201


def test_unknown_card_ids_are_rejected(client):
    r = client.post("/run", json=make_run(stats={"rounds": 3, "busts": 0, "blackjacks": 0, "cards_played": {"ace_of_cheats": 1}}))
    assert r.status_code == 422
    assert "ace_of_cheats" in r.json()["detail"]
