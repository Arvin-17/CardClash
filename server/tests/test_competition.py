from tests.conftest import make_run


def post(client, **over):
    r = client.post("/run", json=make_run(**over))
    assert r.status_code == 201, r.text
    return r.json()


def test_leaderboard_orders_and_keeps_each_players_best_run(client):
    post(client, player_name="alice", time_ms=400_000)
    post(client, player_name="ALICE", time_ms=300_000)  # same player, better
    post(client, player_name="bob", time_ms=350_000)
    post(client, player_name="cat", won=False, battles_won=4, time_ms=60_000)
    post(client, player_name="dodo", won=False, battles_won=2, time_ms=50_000)
    board = client.get("/leaderboard").json()
    assert [(e["rank"], e["player_name"], e["time_ms"]) for e in board] == [
        (1, "ALICE", 300_000),
        (2, "bob", 350_000),
        (3, "cat", 60_000),
        (4, "dodo", 50_000),
    ]
    assert set(board[0]) == {"rank", "player_name", "won", "battles_won", "time_ms"}


def test_daily_leaderboard_only_shows_todays_daily_runs(client):
    seed = client.get("/daily-seed").json()["seed"]
    post(client, player_name="daily", is_daily=True, seed=seed, time_ms=500_000)
    post(client, player_name="normal", time_ms=100_000)
    assert [e["player_name"] for e in client.get("/leaderboard?daily=true").json()] == ["daily"]
    assert [e["player_name"] for e in client.get("/leaderboard").json()] == ["normal", "daily"]


def test_leaderboard_limit(client, no_rate_limit):
    for i in range(12):
        post(client, player_name=f"p{i}", time_ms=100_000 + i)
    assert len(client.get("/leaderboard").json()) == 10
    assert len(client.get("/leaderboard?limit=3").json()) == 3
    assert client.get("/leaderboard?limit=51").status_code == 422
    assert client.get("/leaderboard?limit=0").status_code == 422


def test_stats_aggregates(client):
    assert client.get("/stats").json() == {
        "total_runs": 0, "win_rate": 0.0, "bust_rate": 0.0, "blackjack_rate": 0.0, "most_played_cards": [], "queen_kills": 0
    }
    post(client, stats={"rounds": 10, "busts": 2, "blackjacks": 1, "cards_played": {"drink_me": 4, "teacup": 1}})
    post(client, player_name="b", won=False, battles_won=3,
         stats={"rounds": 10, "busts": 4, "blackjacks": 1, "cards_played": {"drink_me": 2, "eat_me": 3}})
    s = client.get("/stats").json()
    assert s["total_runs"] == 2
    assert s["win_rate"] == 0.5
    assert s["queen_kills"] == 1
    assert s["bust_rate"] == 0.3
    assert s["blackjack_rate"] == 0.1
    assert s["most_played_cards"][:2] == [{"id": "drink_me", "count": 6}, {"id": "eat_me", "count": 3}]


def test_post_run_is_rate_limited_per_ip(client):
    codes = [client.post("/run", json=make_run(player_name=f"spam{i}")).status_code for i in range(11)]
    assert codes[:10] == [201] * 10
    assert codes[10] == 429


def test_admin_delete_needs_the_key(client):
    run_id = post(client)["id"]
    assert client.delete(f"/run/{run_id}").status_code == 403
    assert client.delete(f"/run/{run_id}", headers={"X-Admin-Key": "nope"}).status_code == 403
    assert client.delete(f"/run/{run_id}", headers={"X-Admin-Key": "test-admin"}).status_code == 204
    assert client.delete(f"/run/{run_id}", headers={"X-Admin-Key": "test-admin"}).status_code == 404
    assert client.get("/leaderboard").json() == []


def test_admin_delete_disabled_without_a_configured_key(client, app):
    app.state.settings.admin_key = ""
    run_id = post(client)["id"]
    assert client.delete(f"/run/{run_id}", headers={"X-Admin-Key": ""}).status_code == 403


def test_board_page_lists_runs(client):
    post(client, player_name="Hatter")
    page = client.get("/board")
    assert page.status_code == 200
    assert "Hatter" in page.text and "beat the Queen" in page.text
