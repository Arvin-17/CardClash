"""Player-name cleaning: the only personal data we keep is a display name."""

import re

MAX_NAME_LENGTH = 16

# Deliberately short: catches casual junk at a demo table, not a moderation system.
BLOCKLIST = (
    "fuck",
    "shit",
    "cunt",
    "bitch",
    "dick",
    "cock",
    "penis",
    "porn",
    "nazi",
    "hitler",
)

_ALLOWED = re.compile(r"[^A-Za-z0-9 _-]")
_SPACES = re.compile(r"\s+")


def clean_name(raw: str) -> str:
    """Strip whitespace, keep letters, digits, spaces, _ and -; max 16 chars.

    Raises ValueError when nothing usable is left or the name is blocked.
    """
    name = _ALLOWED.sub("", raw or "")
    name = _SPACES.sub(" ", name).strip()[:MAX_NAME_LENGTH].strip()
    if not name:
        raise ValueError("player_name must contain letters or digits")
    squashed = re.sub(r"[^a-z]", "", name.lower())
    if any(word in squashed for word in BLOCKLIST):
        raise ValueError("player_name is not allowed")
    return name
