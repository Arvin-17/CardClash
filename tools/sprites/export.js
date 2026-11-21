#!/usr/bin/env node
// Renders every CardClash animation from engine.js into game/art/.
//   cd tools/sprites && npm install && npm run export
// Writes sprite sheets to game/art/anim/ plus game/art/anim/manifest.json, card art to
// game/art/cards/, and first frames to game/art/enemies/ (used as stills).
const fs = require('fs');
const path = require('path');
const { createCanvas } = require('@napi-rs/canvas');

global.OffscreenCanvas = class { constructor(w, h) { return createCanvas(w, h); } };
const Engine = eval('(class Engine { ' + fs.readFileSync(path.join(__dirname, 'engine.js'), 'utf8') + ' })');
const E = new Engine().E();
const ART = path.resolve(__dirname, '../../game/art');
const CARDS = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../game/data/cards.json'), 'utf8')).cards;
fs.mkdirSync(path.join(ART, 'anim'), { recursive: true });
fs.mkdirSync(path.join(ART, 'cards/big'), { recursive: true });
const manifest = {};

// Draws one frame: a character with no room behind it and its body cut at the table line
// (characters sit behind the table that the room background already draws).
function charFrame(el, scene, o, t, clip = true) {
  const sc = E.S[scene](o);
  E.render(el, Object.assign({}, sc, { bg: () => {}, table: clip ? (tt, W, H) => { el.getContext('2d').clearRect(0, 84, W, H - 84); } : () => {} }), t, o);
}
function rawFrame(el, scene, o, t) { E.render(el, E.S[scene](o), t, o); }

function sheet(name, { w, h, frames, fps, loop, draw, t0 = 0, opaque = false }) {
  const cols = Math.max(1, Math.min(frames, Math.floor(3840 / w)));
  const rows = Math.ceil(frames / cols);
  const out = createCanvas(cols * w, rows * h);
  const ox = out.getContext('2d');
  const el = createCanvas(w, h);
  for (let f = 0; f < frames; f++) {
    el.getContext('2d').clearRect(0, 0, w, h);
    draw(el, t0 + f / fps);
    ox.drawImage(el, (f % cols) * w, Math.floor(f / cols) * h);
  }
  const file = `anim/${name}.png`;
  fs.writeFileSync(path.join(ART, file), out.toBuffer('image/png'));
  manifest[name] = { file, w, h, frames, cols, fps, loop };
  return out;
}
const still = (file, w, h, draw) => { const el = createCanvas(w, h); draw(el); fs.writeFileSync(path.join(ART, file), el.toBuffer('image/png')); };

const C = { w: 128, h: 112 };
const SUITS = { spade_soldier: 'spade', club_soldier: 'club', diamond_soldier: 'diamond', heart_soldier: 'heart' };
const ATTACK = { spade: 'dig', club: 'bonk', diamond: 'pilfer', heart: 'off_with_it' };

// Card soldiers: idle loop, the tell (wind-up, holds on its last frame) and their one attack.
for (const [id, suit] of Object.entries(SUITS)) {
  sheet(`${id}_idle`, { ...C, frames: 34, fps: 10, loop: true, draw: (el, t) => charFrame(el, 'soldier', { mode: 'idle', suit }, t) });
  sheet(`${id}_tell`, { ...C, frames: 6, fps: 10, loop: false, draw: (el, t) => charFrame(el, 'soldier', { mode: 'action', suit }, t * 1.0) });
  sheet(`${id}_attack_${ATTACK[suit]}`, { ...C, frames: 24, fps: 10, loop: false, draw: (el, t) => charFrame(el, 'soldier', { mode: 'action', suit }, t) });
  still(`enemies/${id}.png`, C.w, C.h, (el) => charFrame(el, 'soldier', { mode: 'idle', suit }, 0));
}
// The Queen: idle, enraged idle, laugh, tell, and every move in her rotation.
const Q = 'queen_of_hearts';
sheet(`${Q}_idle`, { ...C, frames: 34, fps: 10, loop: true, draw: (el, t) => charFrame(el, 'queen', { mode: 'idle' }, t) });
sheet(`${Q}_rage`, { ...C, frames: 20, fps: 10, loop: true, draw: (el, t) => charFrame(el, 'queen', { mode: 'rage' }, t) });
sheet(`${Q}_laugh`, { ...C, frames: 10, fps: 10, loop: true, draw: (el, t) => charFrame(el, 'queen', { mode: 'laugh' }, t) });
sheet(`${Q}_tell`, { ...C, frames: 7, fps: 10, loop: false, draw: (el, t) => charFrame(el, 'queen', { mode: 'action' }, t) });
sheet(`${Q}_attack_off_with_its_head`, { ...C, frames: 34, fps: 10, loop: false, draw: (el, t) => charFrame(el, 'queen', { mode: 'action' }, t) });
for (const m of ['bonk', 'pilfer', 'dig']) sheet(`${Q}_attack_${m}`, { ...C, frames: 26, fps: 10, loop: false, draw: (el, t) => charFrame(el, 'queen', { mode: m }, t) });
still(`enemies/${Q}.png`, C.w, C.h, (el) => charFrame(el, 'queen', { mode: 'idle' }, 0));
still(`enemies/${Q}_rage.png`, C.w, C.h, (el) => charFrame(el, 'queen', { mode: 'rage' }, 0));

// Rooms (one per act), the title screen, endings and the rabbit hole: full 480x270 screens.
const S = { w: 480, h: 270 };
const room = (scene) => (el, t) => rawFrame(el, scene, { mood: 'calm', boss: 'none' }, t);
sheet('room_act1_tea', { ...S, frames: 48, fps: 8, loop: true, draw: room('roomTea') });
sheet('room_act2_wood', { ...S, frames: 48, fps: 8, loop: true, draw: room('roomWood') });
sheet('room_act3_court', { ...S, frames: 48, fps: 8, loop: true, draw: room('roomCourt') });
sheet('title', { ...S, frames: 48, fps: 8, loop: true, draw: (el, t) => rawFrame(el, 'title', { name: 'CARDCLASH', noPress: true }, t) });
sheet('ending_win', { ...S, frames: 80, fps: 10, loop: false, draw: (el, t) => rawFrame(el, 'ending', { kind: 'win', noPress: true }, t) });
sheet('ending_lose', { ...S, frames: 70, fps: 10, loop: false, draw: (el, t) => rawFrame(el, 'ending', { kind: 'lose', noPress: true }, t) });
sheet('rabbit_hole', { ...S, frames: 70, fps: 10, loop: false, draw: (el, t) => rawFrame(el, 'hole', { noText: true }, t) });

// Alice's hand, bottom-left of the battle screen.
const HAND = { w: 128, h: 80 };
sheet('alice_idle', { ...HAND, frames: 12, fps: 10, loop: true, draw: (el, t) => rawFrame(el, 'aliceHand', { kind: 'idle' }, t) });
sheet('alice_hit', { ...HAND, frames: 6, fps: 10, loop: false, draw: (el, t) => rawFrame(el, 'aliceHand', { kind: 'hit' }, t) });
sheet('alice_stay', { ...HAND, frames: 6, fps: 10, loop: false, draw: (el, t) => rawFrame(el, 'aliceHand', { kind: 'stay' }, t) });
sheet('alice_pump', { ...HAND, frames: 10, fps: 10, loop: true, draw: (el, t) => rawFrame(el, 'aliceHand', { kind: 'pump' }, t) });

// Mood overlays: dark edges when you're close to busting, red edges when the boss is enraged.
still('anim/vignette_tension.png', 480, 270, (el) => rawFrame(el, 'vignette', { reach: 64, lv: 0.85 }, 0));
still('anim/vignette_rage.png', 480, 270, (el) => rawFrame(el, 'vignette', { reach: 72, lv: 0.75, col: '#7a1428' }, 0));

// Cards: the 52 blind-deck faces plus the back (one atlas), and built-deck card art.
const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
const SUIT_ROWS = ['spade', 'heart', 'club', 'diamond'];
{ const cw = 26, ch = 36, out = createCanvas(cw * 14, ch * 4), ox = out.getContext('2d'), el = createCanvas(cw, ch);
  SUIT_ROWS.forEach((s, r) => { RANKS.forEach((rk, i) => { rawFrame(el, 'cardFace', { rank: rk, suit: s }, 0); ox.drawImage(el, i * cw, r * ch); }); rawFrame(el, 'cardFace', { back: true }, 0); ox.drawImage(el, 13 * cw, r * ch); });
  fs.writeFileSync(path.join(ART, 'cards/deck.png'), out.toBuffer('image/png'));
  manifest.deck = { file: 'cards/deck.png', w: cw, h: ch, cols: 14, ranks: RANKS, suits: ['spades', 'hearts', 'clubs', 'diamonds'] }; }
const ARTKEY = { drink_me: ['drink', 'DRINK ME'], eat_me: ['eat', 'EAT ME'], teacup: ['tea', 'TEACUP'], pocket_watch: ['watch', 'WATCH'], white_rabbit: ['rabbit', 'RABBIT'], looking_glass: ['glass', 'MIRROR'], painted_rose: ['rose', 'ROSE'], mushroom: ['mushroom', 'MUSHROOM'], croquet_swing: ['croquet', 'CROQUET'], hedgehog_shield: ['hedgehog', 'HEDGEHOG'], caterpillar_smoke: ['smoke', 'SMOKE'], vorpal_blade: ['vorpal', 'VORPAL'], tweedle_twins: ['twins', 'TWEEDLES'], unbirthday_gift: ['gift', 'GIFT'] };
const FRAME = { starter: E.P.greyHi, common: E.P.greyHi, uncommon: E.P.teal, rare: E.P.gold };
for (const card of CARDS) {
  const frame = FRAME[card.rarity] || E.P.greyHi;
  if (card.type === 'number') { still(`cards/big/${card.id}.png`, 56, 78, (el) => rawFrame(el, 'cardArt', { num: String(card.value), name: 'PLUS ' + card.value, frame }, 0)); continue; }
  const k = ARTKEY[card.id]; if (!k) continue;
  still(`cards/big/${card.id}.png`, 56, 78, (el) => rawFrame(el, 'cardArt', { art: k[0], name: k[1], frame }, 0));
  still(`cards/${card.id}.png`, 32, 32, (el) => rawFrame(el, 'cardArt', { art: k[0], icon: true }, 0));
}

fs.writeFileSync(path.join(ART, 'anim/manifest.json'), JSON.stringify(manifest, null, 1) + '\n');
console.log(`wrote ${Object.keys(manifest).length} animations to game/art/anim/`);
