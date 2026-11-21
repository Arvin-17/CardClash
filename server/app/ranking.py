"""Ranking: winners first, then most battles won, then fastest time."""

import datetime as dt

from sqlalchemy import ColumnElement, and_, func, or_, true
from sqlmodel import Session, col, select

from .models import Run


def board_scope(daily: bool, day: dt.date | None = None) -> ColumnElement[bool]:
    """Which runs a board covers: one day's daily runs, or every run."""
    if daily:
        return and_(col(Run.is_daily).is_(True), col(Run.daily_date) == day)
    return true()


def beats(won: bool, battles_won: int, time_ms: int) -> ColumnElement[bool]:
    """Runs strictly better than (won, battles_won, time_ms)."""
    same_result = col(Run.won) == won
    conditions = [
        and_(same_result, col(Run.battles_won) > battles_won),
        and_(same_result, col(Run.battles_won) == battles_won, col(Run.time_ms) < time_ms),
    ]
    if not won:
        conditions.append(col(Run.won).is_(True))
    return or_(*conditions)


def rank_of(session: Session, run: Run) -> int:
    """1 + how many other players have a run that beats this one on the same board."""
    better_players = session.exec(
        select(func.count(func.distinct(func.lower(Run.player_name)))).where(
            board_scope(run.is_daily, run.daily_date),
            beats(run.won, run.battles_won, run.time_ms),
            func.lower(Run.player_name) != run.player_name.lower(),
        )
    ).one()
    return int(better_players) + 1
