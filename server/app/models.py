"""Database tables: one row per finished run, one row per day's seed.

Stats are computed from runs, never stored separately.
"""

import datetime as dt

from sqlalchemy import JSON, BigInteger, Column, Index
from sqlmodel import Field, SQLModel


def _now() -> dt.datetime:
    return dt.datetime.now(dt.UTC)


class Run(SQLModel, table=True):
    __tablename__ = "runs"
    # Keeps the daily leaderboard query fast.
    __table_args__ = (Index("ix_runs_daily_board", "is_daily", "daily_date", "won", "time_ms"),)

    id: int | None = Field(default=None, primary_key=True)
    player_name: str = Field(max_length=16, index=True)
    seed: int = Field(sa_type=BigInteger)
    is_daily: bool = False
    daily_date: dt.date | None = None
    won: bool
    act: str = Field(max_length=32)
    battles_won: int
    time_ms: int
    rounds: int
    busts: int
    blackjacks: int
    cards_played: dict[str, int] = Field(default_factory=dict, sa_column=Column(JSON, nullable=False))
    game_version: str = Field(max_length=16)
    # Server time, never client time.
    created_at: dt.datetime = Field(default_factory=_now)


class DailySeed(SQLModel, table=True):
    __tablename__ = "daily_seeds"

    date: dt.date = Field(primary_key=True)
    seed: int = Field(sa_type=BigInteger)
