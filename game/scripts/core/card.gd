class_name Card
extends RefCounted
## One card instance on the table, in a hand or in a deck.
## base_value and modifier are stored separately so effects (Drink Me, Eat Me)
## can change a card. Totals are never stored: Rules.total() recomputes them.

const FACE_VALUE := 10
const ACE_HIGH := 11
const FACES := ["J", "Q", "K"]

## "blind" for standard-deck cards, the cards.json id for built-deck cards,
## or a pseudo id for things like "bonk" and "copy".
var id: String = ""
## Standard-deck rank: A, 2-10, J, Q, K. Empty for built-deck cards.
var rank: String = ""
var suit: String = ""
var base_value: int = 0
var modifier: int = 0
var is_ace: bool = false
## The cards.json entry for built-deck cards.
var def: Dictionary = {}


static func blind(rank_name: String, suit_name: String) -> Card:
	var c := Card.new()
	c.id = "blind"
	c.rank = rank_name
	c.suit = suit_name
	c.is_ace = rank_name == "A"
	if c.is_ace:
		c.base_value = ACE_HIGH
	elif rank_name in FACES:
		c.base_value = FACE_VALUE
	else:
		c.base_value = int(rank_name)
	return c


static func from_def(card_def: Dictionary) -> Card:
	var c := Card.new()
	c.id = str(card_def.get("id", ""))
	c.def = card_def
	c.base_value = int(card_def.get("value", 0))
	return c


static func pseudo(card_id: String, amount: int) -> Card:
	var c := Card.new()
	c.id = card_id
	c.base_value = amount
	return c


## This card's own value (an ace counts 11 here; Rules.total() drops aces to 1 when needed).
func value() -> int:
	return maxi(0, base_value + modifier)


func is_blind() -> bool:
	return id == "blind"


func is_number() -> bool:
	return str(def.get("type", "")) == "number"


func effect_name() -> String:
	return str(def.get("effect", ""))


func display_name() -> String:
	if is_blind():
		return rank
	if def.is_empty():
		return id.to_upper()
	return str(def.get("name", id))


## The short text shown on a table card, e.g. "K", "7" or "4*" when modified.
func face() -> String:
	var shown := rank if is_blind() else str(value())
	if is_blind() and modifier != 0:
		shown = str(value())
	return shown


func clone() -> Card:
	var c := Card.new()
	c.id = id
	c.rank = rank
	c.suit = suit
	c.base_value = base_value
	c.modifier = modifier
	c.is_ace = is_ace
	c.def = def
	return c
