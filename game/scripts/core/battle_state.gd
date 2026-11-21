class_name BattleState
extends RefCounted
## All the rules state of one battle, with no timing and no UI, so it can be unit-tested.
## BattleController drives it in real time; effects mutate it; it emits signals after
## every change.

signal card_dealt(who: String, card: Card)
signal total_changed(who: String, total: int)
signal hp_changed(who: String, hp: int, max_hp: int)
signal round_resolved(result: Dictionary)
signal message(text: String)

var rules: Dictionary
var enemy_def: Dictionary
var rng: RandomNumberGenerator
var target: int = Rules.DEFAULT_TARGET
var player: Combatant
var enemy: Combatant
var hit_deck: HitDeck
var round_number: int = 0
var enemy_stay_at: int = 17
var enemy_risk: float = 0.0
## Per-round flags set by effects.
var hide_total: bool = false
var crit_boost: bool = false


func _init(p_rules: Dictionary, p_enemy_def: Dictionary, p_rng: RandomNumberGenerator, player_hp: int, player_max_hp: int) -> void:
	rules = p_rules
	enemy_def = p_enemy_def
	rng = p_rng
	target = int(rules.get("blackjack", Rules.DEFAULT_TARGET))
	var player_rules: Dictionary = rules.get("player", {})
	player = Combatant.new("player", "Alice", player_hp, player_max_hp, int(player_rules.get("base_attack", 3)))
	var enemy_hp := int(enemy_def.get("hp", 10))
	enemy = Combatant.new("enemy", str(enemy_def.get("name", "Enemy")), enemy_hp, enemy_hp, int(enemy_def.get("base_attack", 3)))
	enemy_stay_at = int(enemy_def.get("stay_at", 17))
	enemy_risk = float(enemy_def.get("risk", 0.0))
	hit_deck = HitDeck.new(rng)


func enemy_id() -> String:
	return str(enemy_def.get("id", ""))


func round_rule(key: String, fallback: Variant) -> Variant:
	var round_rules: Dictionary = rules.get("round", {})
	return round_rules.get(key, fallback)


## DEAL: clear the table and deal 2 blind cards each.
func start_round() -> void:
	round_number += 1
	hit_deck.discard(player.clear_table())
	hit_deck.discard(enemy.clear_table())
	hide_total = false
	crit_boost = false
	for _i in int(round_rule("blind_cards_dealt", 2)):
		_deal(player)
		_deal(enemy)


func _deal(c: Combatant) -> Card:
	var card := hit_deck.draw()
	if card == null:
		return null
	c.table.append(card)
	card_dealt.emit(c.side, card)
	total_changed.emit(c.side, c.total(target))
	return card


## Hit: draw the top blind card. Going bust ends your turn.
func player_hit() -> Card:
	if player.stayed:
		return null
	var card := _deal(player)
	if player.is_bust(target):
		player.stayed = true
	return card


## Stay: lock your total for this round (surprise attacks can still hit you).
func player_stay() -> void:
	player.stayed = true


func enemy_hit() -> Card:
	if enemy.stayed:
		return null
	var card := _deal(enemy)
	if enemy.is_bust(target):
		enemy.stayed = true
	return card


func enemy_stay() -> void:
	enemy.stayed = true


func both_done() -> bool:
	return player.stayed and enemy.stayed


## The round timer ran out: everyone stays.
func force_stay() -> void:
	player.stayed = true
	enemy.stayed = true


## RESOLVE: compare totals and apply the damage table.
func resolve_round() -> Dictionary:
	var pt := player.total(target)
	var et := enemy.total(target)
	var result := Rules.resolve(pt, et, player.base_attack, enemy.base_attack, rules, crit_boost)
	if result["kind"] == "both_bust":
		player.take_damage(result["messy_damage"])
		enemy.take_damage(result["messy_damage"])
	elif result["loser"] == "player":
		player.take_damage(result["damage"])
	elif result["loser"] == "enemy":
		enemy.take_damage(result["damage"])
	result["round"] = round_number
	result["player_bust"] = pt > target
	result["blackjack"] = pt == target
	result["player_hp"] = player.hp
	result["enemy_hp"] = enemy.hp
	hp_changed.emit("player", player.hp, player.max_hp)
	hp_changed.emit("enemy", enemy.hp, enemy.max_hp)
	round_resolved.emit(result)
	return result


func is_over() -> bool:
	return player.is_dead() or enemy.is_dead()


## Alice must still be standing: if both drop to 0 in a messy round, she loses.
func player_won() -> bool:
	return enemy.is_dead() and not player.is_dead()
