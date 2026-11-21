# CardClash

CardClash is a pixel-art card battler built for a Wonderland-themed hackathon. You fall into a deck of cards and fight through waves of card-soldier enemies in fast blackjack rounds. Hit, play up to 2 special cards a round from your hand whenever you like, and hit READY when you are happy with your total. Whoever ends closer to 21 deals the damage. Enemies can strike before, during, or after your turn. It has a retro look.

Win the run and the Queen of Hearts loses her head; lose, and Alice does.

## How a round works

- Each round, you and the enemy get 2 cards from the shared **blind deck** (a standard 52). Your hand draws up to 3 cards from your own **built deck**.
- You have 10 seconds:
  - **Hit**: draw a blind card.
  - **Play**: play up to **2 hand cards per round**, any time the round is live, even after Ready (numbers 1–4, or effects like Drink Me). Hand cards are never greyed out: a third play just tells you the limit. The count resets every round.
  - **Ready**: you're done drawing. The enemy stops stalling, and the round ends **the moment you've both stayed**, without waiting for the timer.
- The enemy plays on its own clock. Its **intent bar** fills toward a surprise attack. In the last 2 seconds before one lands, the enemy flashes red with a **!** and a warning beep plays. You never see the attack's name, only what it did to you.
- Closer to 21 wins: the loser takes the difference plus the winner's base attack. Exactly 21 is a critical (×2). Busting costs you `total − 21` plus the enemy's attack.

## Repo layout

```
/game     Godot 4 project (GDScript)
  /data   cards, enemies, acts, rules, trinkets JSON: the shared contract
/server   FastAPI backend (leaderboards, daily runs, run stats, card data)
```

## Shared data

`game/data/*.json` is the single source of truth. Design edits names, text and art paths. Game logic edits numbers and effects. The backend serves the same files. Review JSON changes in pull requests so nobody silently changes balance.

| File | What's in it |
| --- | --- |
| `cards.json` | Every card: `id, name, type, value, rarity, pool, effect, params, art, anim, text` |
| `enemies.json` | The four suit soldiers and the Queen: HP, attack, AI numbers, surprise attack |
| `acts.json` | Act 3, The Queen's Court: 4 shuffled soldiers, then the Queen |
| `rules.json` | Every tunable number: HP, timer, plays per round (0 = no limit), attack warning time, damage table, gold, rewards |
| `trinkets.json` | Passive items (stretch goal) |

## Run the API locally

```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app.main:app --reload      # http://localhost:8000/docs
python -m pytest                   # tests
```

Settings come from environment variables; see `server/.env.example`.

### API

| Method + path | Purpose |
| --- | --- |
| `GET /health` | Is the server up (the game shows online/offline) |
| `GET /daily-seed` | Today's shared seed `{date, seed}` |
| `GET /cards` | `cards.json` with an ETag (the game falls back to its bundled copy) |
| `POST /run` | Submit a finished run → `201 {id, rank}`; invalid → `422` |
| `GET /leaderboard?daily=&limit=` | Top runs: winners, then battles won, then time |
| `GET /stats` | Win rate, bust rate, blackjack rate, Queen kills, top cards |

Stretch extras: `DELETE /run/{id}` with an `X-Admin-Key` header, and `GET /board`, an auto-refreshing leaderboard page for a second screen.

**Anti-cheat basics.** Any run sent from a browser can be faked, so the server stops junk and casual cheating:
- It checks every range (battles 0–5, at least 30 s, busts ≤ rounds, `won` only with 5 battles).
- It cleans names and rate-limits `POST /run`.
- It rejects old game versions, and daily runs that don't use today's seed.

## Run the game

1. Install [Godot 4.7](https://godotengine.org/download) (standard build, not .NET).
2. Open `game/project.godot` and press **F5**. Any scene also runs on its own with **F6**.
3. Controls:
   - **H** hit, **Space** ready (or **S**), **1–5** play a hand card, **M** mute
   - debug builds only: **F1** overlay, **F2** instant win, **F3** print seed
4. The game talks to the API at `http://127.0.0.1:8000` by default. To point it elsewhere, run `godot --path game -- --api=https://...`, or edit `cardclash/api/base_url` in Project Settings. Offline, everything still works except the leaderboard and the daily run.

Unit tests use [GUT](https://github.com/bitwes/Gut). Install **GUT 9.7.1** from the Asset Library (it lands in `game/addons/gut`, which git ignores), then:

```bash
cd game
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
godot --headless --fixed-fps 60 -- --autoplay    # a bot plays a whole run
```

CI does all of this on every pull request (`.github/workflows/game.yml`). `test_balance` also prints a balance report (rounds per fight, win and bust rates) to compare with the targets.

Placeholder art, fonts and sounds come from `python3 tools/export_art.py`. The designer's files replace them at the same paths.

## How the game is built

- **Logic never depends on art.**
  - `scripts/core` holds plain classes with no scene code: `Card`, `Rules`, `HitDeck`, `PlayerDeck`, `BattleState`.
  - `BattleController` drives them in real time (Timer nodes for the round, the AI tick and the intent bar) and re-emits every change on the `Events` bus.
  - The UI and `Audio` only listen.
- **All numbers live in `game/data`.** Balancing is editing JSON.
- **One seeded RNG** (`Rng`). Same seed, same run: needed for the daily run and bug reports.
- **Cards are data plus one small script.** `effect` names map to `scripts/effects/<name>.gd`, and enemy surprise attacks to `scripts/effects/enemy/<name>.gd`.
- **`Api`** is the only thing that touches the network. It fails silently, and scenes pass callbacks so leaving a screen mid-request is safe.

## Deploy

**API → Render** (`render.yaml`):
1. In Render, choose **New → Blueprint** and pick this repo. You get the `cardclash-api` web service and a free Postgres database. On a free host SQLite can reset on redeploy, so Postgres is used here; locally it stays SQLite.
2. Set `ALLOWED_ORIGINS` to the game's origin. itch.io serves web games from `https://html-classic.itch.zone`.
3. Open `https://<service>.onrender.com/docs` to check it.

**Web build → itch.io:**
1. In Godot: **Project → Export → Web → Export Project** (this needs the 4.7.2 export templates).
   - The preset ships the data JSON and leaves out tests and GUT.
   - Threads are off, so itch.io needs no SharedArrayBuffer headers.
   - The web build calls `cardclash/api/base_url.web`. Change it if your Render URL differs.
2. Zip `game/build/web/` and upload it to itch.io as an HTML game.

**Desktop backup:** the **Windows Desktop** and **Linux** presets build a single-file game. Keep one on a USB stick.

### Demo-day checklist

- [ ] Open `/health` a few minutes before judging. Free servers sleep and take 30+ s to wake.
- [ ] Have a local backup server ready: `cd server && uvicorn app.main:app`, and run the game with `-- --api=http://127.0.0.1:8000`.
- [ ] Remember the game is fully playable offline: a dead Wi-Fi only costs the leaderboard.
- [ ] Put `GET /board` on a second screen as a live leaderboard.
- [ ] Use `DELETE /run/{id}` with `X-Admin-Key` to remove junk entries (the key is in Render's env vars).
