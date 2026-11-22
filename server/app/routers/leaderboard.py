import datetime as dt
import html
from typing import Annotated

from fastapi import APIRouter, Query
from fastapi.responses import HTMLResponse
from sqlalchemy import func
from sqlmodel import Session, col, select

from ..db import SessionDep, TodayDep
from ..models import Run
from ..ranking import board_scope
from ..schemas import BATTLES_PER_RUN, LeaderboardEntry

router = APIRouter(tags=["leaderboard"])


def top_runs(session: Session, daily: bool, day: dt.date, limit: int) -> list[LeaderboardEntry]:
    """Each player's best run only, sorted winners first, then most battles won, then fastest."""
    best_first = (col(Run.won).desc(), col(Run.battles_won).desc(), col(Run.time_ms).asc(), col(Run.id).asc())
    ranked = (
        select(
            Run.id,
            Run.player_name,
            Run.won,
            Run.battles_won,
            Run.time_ms,
            func.row_number().over(partition_by=func.lower(Run.player_name), order_by=best_first).label("nth"),
        )
        .where(board_scope(daily, day))
        .subquery()
    )
    rows = session.exec(
        select(ranked.c.player_name, ranked.c.won, ranked.c.battles_won, ranked.c.time_ms)
        .where(ranked.c.nth == 1)
        .order_by(ranked.c.won.desc(), ranked.c.battles_won.desc(), ranked.c.time_ms.asc(), ranked.c.id.asc())
        .limit(limit)
    ).all()
    return [
        LeaderboardEntry(rank=i, player_name=name, won=won, battles_won=battles, time_ms=time_ms)
        for i, (name, won, battles, time_ms) in enumerate(rows, start=1)
    ]


@router.get("/leaderboard", response_model=list[LeaderboardEntry])
def leaderboard(
    session: SessionDep,
    today: TodayDep,
    daily: bool = False,
    limit: Annotated[int, Query(ge=1, le=50)] = 10,
) -> list[LeaderboardEntry]:
    """Top runs. `daily=true` shows today's daily run only."""
    return top_runs(session, daily, today, limit)


def _fmt_time(ms: int) -> str:
    s = ms // 1000
    return f"{s // 60}:{s % 60:02d}"


def _table(title: str, entries: list[LeaderboardEntry]) -> str:
    rows = "".join(
        f"<tr><td>{e.rank}</td><td>{html.escape(e.player_name)}</td>"
        f"<td>{'beat the Queen' if e.won else f'{e.battles_won}/{BATTLES_PER_RUN}'}</td><td>{_fmt_time(e.time_ms)}</td></tr>"
        for e in entries
    ) or '<tr><td colspan="4">No runs yet. Be the first!</td></tr>'
    return f"<section><h2>{title}</h2><table><tr><th>#</th><th>Name</th><th>Result</th><th>Time</th></tr>{rows}</table></section>"


@router.get("/board", response_class=HTMLResponse, include_in_schema=False)
def board(session: SessionDep, today: TodayDep) -> HTMLResponse:
    """A tiny auto-refreshing leaderboard page for a second screen at the demo table."""
    daily = _table(f"Daily run · {today.isoformat()}", top_runs(session, True, today, 10))
    all_time = _table("All time", top_runs(session, False, today, 10))
    page = f"""<!doctype html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="15">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CardClash leaderboard</title>
<style>
body{{margin:0;background:#1b1a26;color:#f2e6c9;font:20px/1.4 ui-monospace,Menlo,monospace;display:flex;gap:48px;justify-content:center;padding:32px}}
h1{{position:absolute;top:8px;left:0;right:0;text-align:center;color:#c8323c;font-size:28px;margin:0}}
section{{margin-top:48px}}h2{{color:#c8323c;font-size:22px}}table{{border-collapse:collapse}}
td,th{{padding:6px 14px;border-bottom:1px solid #3f7d3a;text-align:left}}th{{color:#3f7d3a}}
</style></head><body><h1>&#9829; CardClash</h1>{daily}{all_time}</body></html>"""
    return HTMLResponse(page)
