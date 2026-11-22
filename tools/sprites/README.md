# tools/sprites

Renders all of CardClash's pixel art and animation into `game/art/`:

| Output | What |
| --- | --- |
| `game/art/anim/*.png` | Sprite sheets: every enemy (idle, tell, attacks, rage, laugh), the three act rooms, the title screen, both endings, the rabbit hole, Alice's hand, mood vignettes |
| `game/art/anim/manifest.json` | Frame size, frame count, columns, fps and looping for each sheet (read by `AnimLib` in the game) |
| `game/art/cards/deck.png` | All 52 blind-deck card faces plus the back |
| `game/art/cards/*.png`, `cards/big/*.png` | Built-deck card icons and the big faces shown when a card is played |
| `game/art/enemies/*.png` | Stills (first idle frame) |

`engine.js` draws everything in code, frame by frame. It is the same engine as the design canvas,
so a change made here (a pose, a colour, a new attack) shows up in the game after a re-export.

```bash
cd tools/sprites
npm install
npm run export
cd ../../game && godot --headless --import   # creates the .import files for new sheets
```

`@napi-rs/canvas` is pinned to **0.1.65**: newer 0.1.x releases drop the layered character
bodies (only hands and faces render). Re-exporting with the pinned version reproduces the
committed art pixel for pixel.

Every sheet is a grid of equal frames, left to right, top to bottom, at most 3840 px wide.
To add an animation, draw it in `engine.js`, add a `sheet(...)` line in `export.js`, then
reference its manifest key from the game (`AnimLib.frames({...})`).
