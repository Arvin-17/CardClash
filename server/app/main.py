"""CardClash API: leaderboards, daily runs, run stats and card data.

The game must stay fully playable without this server; it only adds
competition and data on top.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .card_data import CardData
from .config import Settings, get_settings
from .db import create_tables, make_engine
from .routers import cards, daily, runs
from .schemas import Health


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        app.state.engine = make_engine(settings.database_url)
        create_tables(app.state.engine)
        # One copy of every card: the game's own data file.
        app.state.cards = CardData.load(settings.data_dir)
        yield
        app.state.engine.dispose()

    app = FastAPI(
        title="CardClash API",
        version=settings.game_version,
        description="Backend for CardClash (Blackjack Wonderland). The game calls it; only it touches the database.",
        lifespan=lifespan,
    )
    app.state.settings = settings
    # The web build runs on another domain (itch.io), so CORS must list its origin.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.origins,
        allow_methods=["GET", "POST", "DELETE"],
        allow_headers=["*"],
        expose_headers=["ETag"],
    )

    @app.get("/health", response_model=Health, tags=["meta"])
    def health() -> Health:
        """Is the server up? The game calls this at start to show online/offline."""
        return Health(version=settings.game_version)

    app.include_router(cards.router)
    app.include_router(daily.router)
    app.include_router(runs.router)
    return app


app = create_app()
