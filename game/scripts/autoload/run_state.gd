extends Node
## The current run: HP, deck, gold, where we are in the act, and the RNG seed.

var run_seed: int = 0
var hp: int = 30
var max_hp: int = 30
var gold: int = 0
var deck: Array[String] = []
var trinkets: Array[String] = []
var act_id: String = "act3_court"
var battle_index: int = 0
var stats := {"rounds": 0, "busts": 0, "blackjacks": 0, "cards_played": {}}


func new_run(seed_value: int) -> void:
	run_seed = seed_value
	Rng.set_seed(seed_value)
	max_hp = int(GameData.rule("player.max_hp", 30))
	hp = max_hp
	gold = 0
	deck.clear()
	for id: Variant in GameData.rule("starter_deck", []):
		deck.append(str(id))
	trinkets.clear()
	battle_index = 0
	stats = {"rounds": 0, "busts": 0, "blackjacks": 0, "cards_played": {}}


func battles() -> Array:
	return GameData.act(act_id).get("battles", [])


func current_enemy_id() -> String:
	var list := battles()
	if list.is_empty():
		return ""
	return str(list[clampi(battle_index, 0, list.size() - 1)])
