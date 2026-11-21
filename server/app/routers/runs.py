from collections import Counter

from fastapi import APIRouter, HTTPException, Request, status
from sqlalchemy import case, func
from sqlmodel import select

from ..db import SessionDep, TodayDep
from ..models import DailySeed, Run
from ..ranking import rank_of
from ..schemas import CardCount, RunCreated, RunIn, Stats

router = APIRouter(tags=["runs"])


def _version(v: str) -> tuple[int, ...]:
    return tuple(int(p) for p in v.split("."))


def _reject(msg: str) -> HTTPException:
    return HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, msg)


@router.post("/run", response_model=RunCreated, status_code=status.HTTP_201_CREATED)
def submit_run(body: RunIn, request: Request, session: SessionDep, today: TodayDep) -> RunCreated:
    """Submit a finished run. Returns its id and rank so the ending can say "You placed #3 today!"."""
    settings = request.app.state.settings
    if _version(body.game_version) < _version(settings.game_version):
        raise _reject(f"game_version {body.game_version} is outdated; current is {settings.game_version}")

    cards = request.app.state.cards
    if cards is not None:
        unknown = sorted(set(body.stats.cards_played) - cards.ids)
        if unknown:
            raise _reject(f"unknown card ids: {', '.join(unknown)}")

    if body.is_daily:
        stored = session.exec(select(DailySeed).where(DailySeed.date == today)).first()
        if stored is None or stored.seed != body.seed:
            raise _reject("daily runs must use today's seed")

    run = Run(
        player_name=body.player_name,
        seed=body.seed,
        is_daily=body.is_daily,
        daily_date=today if body.is_daily else None,
        won=body.won,
        act=body.act,
        battles_won=body.battles_won,
        time_ms=body.time_ms,
        rounds=body.stats.rounds,
        busts=body.stats.busts,
        blackjacks=body.stats.blackjacks,
        cards_played=body.stats.cards_played,
        game_version=body.game_version,
    )
    session.add(run)
    session.commit()
    session.refresh(run)
    return RunCreated(id=run.id, rank=rank_of(session, run))


@router.get("/stats", response_model=Stats)
def stats(session: SessionDep) -> Stats:
    """Aggregates across every run: how players actually manage risk."""
    total, wins, rounds, busts, blackjacks = session.exec(
        select(
            func.count(Run.id),
            func.coalesce(func.sum(case((Run.won, 1), else_=0)), 0),
            func.coalesce(func.sum(Run.rounds), 0),
            func.coalesce(func.sum(Run.busts), 0),
            func.coalesce(func.sum(Run.blackjacks), 0),
        )
    ).one()
    played: Counter[str] = Counter()
    for cards_played in session.exec(select(Run.cards_played)):
        played.update(cards_played or {})
    return Stats(
        total_runs=total,
        win_rate=round(wins / total, 4) if total else 0.0,
        bust_rate=round(busts / rounds, 4) if rounds else 0.0,
        blackjack_rate=round(blackjacks / rounds, 4) if rounds else 0.0,
        most_played_cards=[CardCount(id=card, count=n) for card, n in played.most_common(5)],
        queen_kills=wins,
    )

