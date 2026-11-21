class_name HitDeck
extends RefCounted
## The blind deck: a standard 52, shared by the player and the enemy, reshuffled each battle.
## "Hit" takes the top card unseen. The discard pile is visible so players can count cards.

const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const SUITS := ["hearts", "diamonds", "clubs", "spades"]

var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng
	reset()


## Fresh 52 cards, shuffled with the run's RNG.
func reset() -> void:
	draw_pile.clear()
	discard_pile.clear()
	for s: String in SUITS:
		for r: String in RANKS:
			draw_pile.append(Card.blind(r, s))
	Shuffle.shuffle(draw_pile, _rng)


func draw() -> Card:
	if draw_pile.is_empty():
		_recycle()
	if draw_pile.is_empty():
		return null
	return draw_pile.pop_back()


## The next card without drawing it (Teacup).
func peek() -> Card:
	if draw_pile.is_empty():
		_recycle()
	if draw_pile.is_empty():
		return null
	return draw_pile.back()


## Blind cards go back face-up onto the discard pile (modifiers are cleared).
func discard(cards: Array) -> void:
	for c: Card in cards:
		if c.is_blind():
			c.modifier = 0
			discard_pile.append(c)


func remaining() -> int:
	return draw_pile.size()


## How many unseen cards are left of each value (aces under 11). For the card-counting UI.
func remaining_by_value() -> Dictionary:
	var counts := {}
	for v in range(2, 12):
		counts[v] = 0
	for c: Card in draw_pile:
		counts[c.base_value] = int(counts.get(c.base_value, 0)) + 1
	return counts


func _recycle() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	Shuffle.shuffle(draw_pile, _rng)
