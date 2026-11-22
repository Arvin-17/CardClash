"""Pydantic request/response models: the contract with the game.

Field names here are sacred: change one only after telling the game logic owner.
FastAPI turns any violation into a 422 automatically.
"""

import datetime as dt
import re

from pydantic import BaseModel, Field, field_validator, model_validator

from .names import clean_name

# A full run: Act 1 (2 soldiers + the Mad Hatter), Act 2 (2 soldiers + the Cheshire Cat),
# Act 3 (the Knave + the Queen).
BATTLES_PER_RUN = 8
_CARD_ID = re.compile(r"^[a-z0-9_]{1,32}$")


class Health(BaseModel):
    ok: bool = True
    version: str = Field(description="Current game version the server accepts runs from")


class DailySeed(BaseModel):
    date: dt.date
    seed: int


class RunStats(BaseModel):
    rounds: int = Field(ge=0, le=10_000)
    busts: int = Field(ge=0, le=10_000)
    blackjacks: int = Field(ge=0, le=10_000, description="Rounds that ended on exactly 21")
    cards_played: dict[str, int] = Field(default_factory=dict, max_length=64, examples=[{"drink_me": 4}])

    @field_validator("cards_played")
    @classmethod
    def _card_counts(cls, v: dict[str, int]) -> dict[str, int]:
        for card_id, count in v.items():
            if not _CARD_ID.match(card_id):
                raise ValueError(f"bad card id {card_id!r}")
            if not 0 <= count <= 10_000:
                raise ValueError(f"bad count for {card_id!r}")
        return v

    @model_validator(mode="after")
    def _within_rounds(self) -> "RunStats":
        if self.busts > self.rounds:
            raise ValueError("busts cannot exceed rounds")
        if self.blackjacks > self.rounds:
            raise ValueError("blackjacks cannot exceed rounds")
        return self


class RunIn(BaseModel):
    """POST /run: one finished run (win or loss)."""

    player_name: str = Field(min_length=1, max_length=64, examples=["alice"])
    seed: int = Field(ge=0, lt=2**53)
    is_daily: bool = False
    won: bool
    act: str = Field(pattern=r"^[a-z0-9_]{1,32}$", examples=["act3_court"])
    battles_won: int = Field(ge=0, le=BATTLES_PER_RUN)
    time_ms: int = Field(ge=30_000, lt=2 * 60 * 60 * 1000, description="Run length; at least 30 s, under 2 h")
    stats: RunStats
    game_version: str = Field(pattern=r"^\d+\.\d+\.\d+$", examples=["0.1.0"])

    @field_validator("player_name")
    @classmethod
    def _clean(cls, v: str) -> str:
        return clean_name(v)

    @model_validator(mode="after")
    def _won_means_queen_beaten(self) -> "RunIn":
        if self.won != (self.battles_won == BATTLES_PER_RUN):
            raise ValueError(f"won must be true exactly when battles_won == {BATTLES_PER_RUN}")
        return self


class RunCreated(BaseModel):
    id: int
    rank: int = Field(description="Where this run placed (today's board for daily runs)")


class LeaderboardEntry(BaseModel):
    rank: int
    player_name: str
    won: bool
    battles_won: int
    time_ms: int


class CardCount(BaseModel):
    id: str
    count: int


class Stats(BaseModel):
    total_runs: int
    win_rate: float
    bust_rate: float = Field(description="busts / rounds across all runs")
    blackjack_rate: float = Field(description="blackjacks / rounds across all runs")
    most_played_cards: list[CardCount]
    queen_kills: int
