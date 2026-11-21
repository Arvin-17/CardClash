"""Engine + session. SQLModel/SQLAlchemy parameterize every query (never build SQL with f-strings)."""

import datetime as dt
from collections.abc import Iterator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.pool import StaticPool
from sqlmodel import Session, SQLModel, create_engine
from sqlalchemy.engine import Engine


def make_engine(url: str) -> Engine:
    kwargs: dict = {}
    if url.startswith("sqlite"):
        kwargs["connect_args"] = {"check_same_thread": False}
        if url in ("sqlite://", "sqlite:///:memory:"):
            # One shared in-memory database (used by the tests).
            kwargs["poolclass"] = StaticPool
    return create_engine(url, **kwargs)


def create_tables(engine: Engine) -> None:
    from . import models  # noqa: F401  (registers the tables)

    SQLModel.metadata.create_all(engine)


def get_session(request: Request) -> Iterator[Session]:
    with Session(request.app.state.engine) as session:
        yield session


def utc_today() -> dt.date:
    """Today's UTC date: the daily run rolls over at midnight UTC. Overridden in tests."""
    return dt.datetime.now(dt.UTC).date()


SessionDep = Annotated[Session, Depends(get_session)]
TodayDep = Annotated[dt.date, Depends(utc_today)]
