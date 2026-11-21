import secrets

from fastapi import APIRouter
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session

from ..db import SessionDep, TodayDep
from ..models import DailySeed
from ..schemas import DailySeed as DailySeedOut

router = APIRouter(tags=["daily"])


def todays_seed(session: Session, today) -> DailySeed:
    """Generate-and-store (not computed from the date) so nobody can predict tomorrow's run."""
    row = session.get(DailySeed, today)
    if row:
        return row
    row = DailySeed(date=today, seed=secrets.randbelow(2**31))
    session.add(row)
    try:
        session.commit()
    except IntegrityError:  # another request created it first
        session.rollback()
        return session.get(DailySeed, today)
    session.refresh(row)
    return row


@router.get("/daily-seed", response_model=DailySeedOut)
def daily_seed(session: SessionDep, today: TodayDep) -> DailySeedOut:
    """Today's shared seed (UTC). Every player on the same day gets the same run."""
    row = todays_seed(session, today)
    return DailySeedOut(date=row.date, seed=row.seed)
