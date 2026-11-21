import datetime as dt
import json

from app.config import REPO_ROOT
from tests.conftest import TODAY, make_run


def test_daily_seed_is_generated_once_per_day(client, day):
    first = client.get("/daily-seed").json()
    assert first["date"] == TODAY.isoformat()
    assert 0 <= first["seed"] < 2**31
    assert client.get("/daily-seed").json() == first

    day["today"] = TODAY + dt.timedelta(days=1)
    tomorrow = client.get("/daily-seed").json()
    assert tomorrow["date"] == (TODAY + dt.timedelta(days=1)).isoformat()


def test_daily_run_must_use_todays_seed(client):
    seed = client.get("/daily-seed").json()["seed"]
    ok = client.post("/run", json=make_run(is_daily=True, seed=seed))
    assert ok.status_code == 201
    wrong = client.post("/run", json=make_run(is_daily=True, seed=seed + 1))
    assert wrong.status_code == 422


def test_daily_run_without_a_seed_today_is_rejected(client):
    assert client.post("/run", json=make_run(is_daily=True, seed=5)).status_code == 422


def test_cards_serves_the_shared_file_with_an_etag(client):
    r = client.get("/cards")
    assert r.status_code == 200
    on_disk = json.loads((REPO_ROOT / "game" / "data" / "cards.json").read_text())
    assert r.json() == on_disk
    assert r.json()["version"] >= 1
    etag = r.headers["etag"]
    again = client.get("/cards", headers={"If-None-Match": etag})
    assert again.status_code == 304
    assert again.content == b""
