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
