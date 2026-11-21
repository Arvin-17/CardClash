def test_health_reports_ok_and_version(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"ok": True, "version": "0.1.0"}


def test_docs_are_served(client):
    assert client.get("/docs").status_code == 200
    assert "CardClash API" in client.get("/openapi.json").json()["info"]["title"]


def test_cors_allows_the_local_web_build(client):
    r = client.get("/health", headers={"Origin": "http://localhost:8060"})
    assert r.headers.get("access-control-allow-origin") == "http://localhost:8060"


def test_postgres_urls_get_an_explicit_driver():
    from app.db import normalize_url

    assert normalize_url("postgres://u:p@host/db") == "postgresql+psycopg://u:p@host/db"
    assert normalize_url("postgresql://u:p@host/db") == "postgresql+psycopg://u:p@host/db"
    assert normalize_url("sqlite:///./cardclash.db") == "sqlite:///./cardclash.db"
