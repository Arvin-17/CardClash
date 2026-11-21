class_name PlayerDeck
extends RefCounted
## Alice's built deck: her collected cards (small numbers and effects).
## Partial control: she draws into her hand at random, then chooses what to play.

var draw_pile: Array[Card] = []
var discard_pile: Array[Card] = []
var _rng: RandomNumberGenerator


func _init(card_ids: Array, card_defs: Dictionary, rng: RandomNumberGenerator) -> void:
	_rng = rng
	for id: Variant in card_ids:
		var card_def: Dictionary = card_defs.get(str(id), {})
		if not card_def.is_empty():
			draw_pile.append(Card.from_def(card_def))
	Shuffle.shuffle(draw_pile, _rng)


func draw() -> Card:
	if draw_pile.is_empty():
		_recycle()
	if draw_pile.is_empty():
		return null
	return draw_pile.pop_back()


func discard(card: Card) -> void:
	card.modifier = 0
	discard_pile.append(card)


## Dig: the top card of the built deck goes to the bottom.
func bury_top() -> Card:
	if draw_pile.is_empty():
		_recycle()
	if draw_pile.size() < 2:
		return null
	var top: Card = draw_pile.pop_back()
	draw_pile.push_front(top)
	return top


func top() -> Card:
	return null if draw_pile.is_empty() else draw_pile.back()


func count() -> int:
	return draw_pile.size() + discard_pile.size()


func _recycle() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	Shuffle.shuffle(draw_pile, _rng)
