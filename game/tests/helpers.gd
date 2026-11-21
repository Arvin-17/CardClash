class_name TestHelpers
extends RefCounted
## Builders shared by the GUT tests.


static func rng(seed_value: int = 5) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


static func card_defs() -> Dictionary:
	var out := {}
	for c: Dictionary in GameData.read_json("cards.json")["cards"]:
		out[c["id"]] = c
	return out


static func enemy(id: String) -> Dictionary:
	for e: Dictionary in GameData.read_json("enemies.json")["enemies"]:
		if e["id"] == id:
			return e
	return {}


## A battle against `enemy_id` with Alice holding exactly `hand_ids` (and the rest of `deck_ids` in her deck).
static func battle(enemy_id: String = "club_soldier", deck_ids: Array = [], hand_ids: Array = [], seed_value: int = 5) -> BattleState:
	var b := BattleState.new(GameData.read_json("rules.json"), enemy(enemy_id), rng(seed_value), 30, 30)
	b.setup_deck(card_defs(), deck_ids)
	var defs := card_defs()
	for id: String in hand_ids:
		b.hand.append(Card.from_def(defs[id]))
	b.plays_left = 2
	return b


static func set_table(c: Combatant, ranks: Array) -> void:
	c.table.clear()
	for r: String in ranks:
		c.table.append(Card.blind(r, "spades"))


static func hand_index(b: BattleState, id: String) -> int:
	for i in b.hand.size():
		if b.hand[i].id == id:
			return i
	return -1
