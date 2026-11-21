# CardClash

CardClash is a pixel-art card battler built for a Wonderland-themed hackathon. You fall into a deck of cards and fight through waves of card-soldier enemies in fast blackjack rounds. Hit, stay, or play a special card from your hand. Whoever ends closer to 21 deals the damage. Enemies can strike before, during, or after your turn. It has a retro look.

Win the run and the Queen of Hearts loses her head; lose, and Alice does.

## How a round works

- Each round, you and the enemy get 2 cards from the shared **blind deck** (a standard 52). Your hand draws up to 3 cards from your own **built deck**.
- You have 15 seconds:
  - **Hit**: draw a blind card.
  - **Stay**: lock your total.
  - **Play**: play up to 2 hand cards (numbers 1–4, or effects like Drink Me).
- The enemy plays on its own clock. Its **intent bar** fills toward a surprise attack.
- Closer to 21 wins: the loser takes the difference plus the winner's base attack. Exactly 21 is a critical (×2). Busting costs you `total − 21` plus the enemy's attack.

## Design

![Title screen mockup](docs/gifs/title_screen.gif)

*Title screen mockup (it uses the working title "Wonderjack").*

A first-person, pixel-art blackjack battler: Alice sits at a card table across from Wonderland's card soldiers and bosses. This section explains how it looks and moves, and why.

### Design pillars

| Pillar | What it means | Why |
| --- | --- | --- |
| **Risk with partial control** | Two decks: a blind **hit deck** you can't control, and a **built deck** of cards you collect and choose from. | Pure blackjack is luck; pure deckbuilding removes tension. Half-random, half-chosen keeps every hit nerve-wracking but every loss feels fixable. |
| **Read the table** | Enemies telegraph surprise attacks with an intent bar and a visible tell. | Hidden attacks feel unfair; telegraphed ones turn into decisions ("hit now before she bonks me?"). |
| **Short, repeatable runs** | 10 to 20 second rounds, 5 fights per act, a fresh deck every run. | A loop you want to replay, not a story you finish once. |
| **Wonderland, our way** | Based on Lewis Carroll's book and the public-domain Tenniel illustrations, not any film adaptation. | Original designs we can own, and a stronger identity than a copy. |
| **Teach without lecturing** | A visible discard pile and bust odds build probability intuition. | Players learn card counting and risk by playing, which is the game's purpose. |

### Art direction

- **Pixel art at 480×270**, scaled up by whole numbers. Big enough for expressive faces, small enough that a three-person team can finish the art in a hackathon.
- **First-person POV at the table.** The enemy sits across from you, lit from below by one warm lamp; your hands and cards sit at the bottom of the screen. It feels personal and tense, like a real high-stakes game.
- **Moody palette with bright accents.** Deep purples and wine reds for rooms; Queen reds, card cream and lamp gold for anything you need to read quickly.
- **Every sprite has a 1-pixel dark outline**, so characters pop off busy backgrounds.

### The cast

Every character has an **idle** loop (left) and an **action** (right). The action is their surprise attack.

#### Alice (you)
![Alice hands](docs/gifs/alice_hands.gif)

Only her hands and lavender sleeves are visible. **Why:** the hands are the player's body language. They drum while you think, tap to hit, wave off to stay, and pump a fist on 21. Lavender instead of the famous blue keeps her ours.

#### Card soldiers
| Spade: Dig | Club: Bonk | Diamond: Pilfer | Heart: Off with it |
| --- | --- | --- | --- |
| ![](docs/gifs/soldier_spade.gif) | ![](docs/gifs/soldier_club.gif) | ![](docs/gifs/soldier_diamond.gif) | ![](docs/gifs/soldier_heart.gif) |

One shared body (a playing card with arms, a suit helmet and a halberd) with four attacks. **Why:** one base sprite recoloured four times saves art time, and each suit's attack teaches one mechanic before the boss combines them.

#### Cheshire Cat (Act 2 boss)
![Cheshire Cat](docs/gifs/cheshire_cat.gif)

Fades until only his grin is left, and your total shows as `??`. **Why:** his attack is information denial, matching a cat famous for vanishing.

#### Knave of Hearts
![Knave](docs/gifs/knave_of_hearts.gif)

A card-sharp who steals from your hand and winks. **Why:** in the book he's the tart thief, so his move is theft.

#### Mad Hatter (Act 1 boss)
![Mad Hatter](docs/gifs/mad_hatter.gif)

His "Move down!" swaps hands with you, straight from the tea party where everyone changes seats. The 10/6 hat tag comes from the book.

#### Queen of Hearts (final boss)
![Queen](docs/gifs/queen_of_hearts.gif)

Idle, "Off with its head!", and enraged below 50% HP. Her heart-shaped hairdo is our own silhouette. She also learns every soldier's trick:

![Queen extra moves](docs/gifs/queen_extra_moves.gif)

**Why:** the final boss tests everything the soldiers taught. She cycles her attacks in a fixed order, so players who pay attention can predict her.

### Battle backgrounds: one room per act

| Act 1: Tea Party | Act 2: Tulgey Wood | Act 3: Queen's Court |
| --- | --- | --- |
| ![](docs/gifs/room_tea_party.gif) | ![](docs/gifs/room_tulgey_wood.gif) | ![](docs/gifs/room_queens_court.gif) |
| Warm, silly sunset garden so new players relax. | Cold, crooked night forest: the creepiest act. | Rich reds and gold: the stakes are highest. |

**Why separate rooms:** each act's mood rises in tension, and players can tell at a glance how far they've come. Every room is split into moving layers (lanterns, fog, flames, curtains) so the engine can animate them separately.

#### The room reacts to the game
| Close to bust (18+) | Boss enraged (below 50% HP) |
| --- | --- |
| ![](docs/gifs/mood_close_to_bust.gif) | ![](docs/gifs/mood_enraged.gif) |

**Why:** the background tells you your danger level without reading a number. A heartbeat vignette means "careful"; a red room with embers means "she's angry".

### The battle screen

![Battle demo](docs/gifs/battle_demo.gif)

A 3-round demo: a hit and the Queen's +2 Bonk, then a **BUST!**, then a dealt **21** with a critical Vorpal slash.

| Element | Where | Why there |
| --- | --- | --- |
| Pocket-watch timer | Top left | A Wonderland object that is also the round clock. It flashes red for the last 3 seconds. |
| Your HP / enemy HP | Top left / top right | Mirrored, so you compare at a glance. |
| Intent bar | Above the enemy's head | Right where you're already looking; fills before a surprise attack. |
| Totals strip | Table edge | Between you and the enemy, the one number that matters most. |
| Your cards and deck | Bottom centre | On the table, like real blackjack. |
| Special cards | Bottom right | Your hand of choices, apart from the blind cards. |

### Special cards

| Drink Me | Eat Me | Teacup |
| --- | --- | --- |
| ![](docs/gifs/card_drink.gif) | ![](docs/gifs/card_eat.gif) | ![](docs/gifs/card_tea.gif) |
| Last card −3 | Last card +3 | Peek at the next card |

| Pocket Watch | Looking Glass | Vorpal Blade |
| --- | --- | --- |
| ![](docs/gifs/card_watch.gif) | ![](docs/gifs/card_glass.gif) | ![](docs/gifs/card_vorpal.gif) |
| Freeze the timer | Copy the enemy's last card | This round counts as a critical |

Every special card shares one cutscene: rise from your hand, zoom, flip with a flash, play its effect. **Why:** one shared animation means a new card only needs new art, and the flip makes every play feel like an event.

### Enemy reactions: tell, hurt, defeat

| Soldier | Cheshire Cat | Knave |
| --- | --- | --- |
| ![](docs/gifs/reactions_soldier.gif) | ![](docs/gifs/reactions_cheshire.gif) | ![](docs/gifs/reactions_knave.gif) |

| Mad Hatter | Queen |
| --- | --- |
| ![](docs/gifs/reactions_hatter.gif) | ![](docs/gifs/reactions_queen.gif) |

- **Tell:** a wind-up pose and a flashing `!`, giving skilled players a beat to react.
- **Hurt:** white flash, knockback and a damage number, so every hit feels earned.
- **Defeat:** unique to each character (the soldier folds into a burst of cards, the Cat goes POOF, the Knave gets dragged off, the Hatter falls asleep), so each victory is memorable.

### Endings

| Win: off with hers | Lose: off with yours |
| --- | --- |
| ![](docs/gifs/ending_win.gif) | ![](docs/gifs/ending_lose.gif) |

The run's payoff. **Win:** the world drains to grey, an axe shadow passes, and her head flips into a Queen card that lands on the table. **Lose:** the axe swings at the camera and your view drops to table level while she laughs. Both stay stylized (card flips, silhouettes, no blood), which is funnier and fits Wonderland's storybook tone.

### Transitions

| Between acts: down the rabbit hole | Between fights: card wipe |
| --- | --- |
| ![](docs/gifs/transition_rabbit_hole.gif) | ![](docs/gifs/transition_card_wipe.gif) |

**Why:** falling down the rabbit hole is the most famous moment in the book, so it marks moving to a new act. The card wipe is quick and on-theme for fights within an act.


#### About these animations
These GIFs come from code-drawn reference sprites made during design. They set the layout, timing, palette and feel; the final sprites are redrawn by hand in Aseprite using the same sizes and frame counts.

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
| `rules.json` | Every tunable number: HP, timer, plays per round, damage table, gold, rewards |
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
2. Open `game/project.godot` and press **F5**.
3. Controls: **H** hit, **S** stay.

Unit tests use [GUT](https://github.com/bitwes/Gut). Install **GUT 9.7.1** from the Asset Library (it lands in `game/addons/gut`, which git ignores), then:

```bash
cd game
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

CI does the same on every pull request (`.github/workflows/game.yml`).

Placeholder fonts come from `python3 tools/export_art.py`.
