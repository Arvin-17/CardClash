class_name BattleState
extends RefCounted
## All the rules state of one battle, with no timing and no UI, so it can be unit-tested.
## BattleController drives it in real time; effects mutate it through the helpers below;
## it emits a signal after every change.

signal card_dealt(who: String, card: Card)
signal card_removed(who: String, card: Card)
signal card_played(card: Card)
signal total_changed(who: String, total: int)
signal hand_changed()
signal hp_changed(who: String, hp: int, max_hp: int)
signal peeked(card: Card)
signal timer_freeze_requested(seconds: float)
signal surprise_attack(enemy_id: String, kind: String)
signal surprise_blocked(enemy_id: String, kind: String)
signal round_resolved(result: Dictionary)
signal boss_phase_changed(phase: int)
signal message(text: String)

var rules: Dictionary
var enemy_def: Dictionary
var rng: RandomNumberGenerator
var target: int = Rules.DEFAULT_TARGET
var player: Combatant
var enemy: Combatant
var hit_deck: HitDeck
var player_deck: PlayerDeck
var card_defs: Dictionary = {}
var hand: Array[Card] = []
## Cards the Diamond Soldier pilfered; gone for the rest of this battle.
var stolen: Array[Card] = []
var round_number: int = 0
var plays_left: int = 0
var enemy_stay_at: int = 17
var enemy_risk: float = 0.0
var surprise_count: int = 0
## Boss phase: 2 once the Queen is enraged.
var phase: int = 1
## Hedgehog Shield charges: each blocks one surprise attack.
var shield: int = 0
## Per-round flags set by effects.
var hide_total: bool = false
var crit_boost: bool = false
var peeked_card: Card = null


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


## Alice's built deck for this battle (card ids from RunState.deck).
func setup_deck(p_card_defs: Dictionary, deck_ids: Array) -> void:
	card_defs = p_card_defs
	player_deck = PlayerDeck.new(deck_ids, card_defs, rng)


func enemy_id() -> String:
	return str(enemy_def.get("id", ""))


func round_rule(key: String, fallback: Variant) -> Variant:
	var round_rules: Dictionary = rules.get("round", {})
	return round_rules.get(key, fallback)


# --- DEAL --------------------------------------------------------------------

## Clear the table, deal 2 blind cards each, draw the hand up to 3, reset plays.
func start_round() -> void:
	round_number += 1
	_clear_table(player)
	_clear_table(enemy)
	hide_total = false
	crit_boost = false
	peeked_card = null
	plays_left = int(round_rule("plays_per_round", 2))
	for _i in int(round_rule("blind_cards_dealt", 2)):
		_deal(player)
		_deal(enemy)
	draw_hand()


func _clear_table(c: Combatant) -> void:
	for card: Card in c.clear_table():
		_discard(card)


## Blind cards back to the blind discard; built-deck cards to Alice's discard; pseudo cards vanish.
func _discard(card: Card) -> void:
	if card.is_blind():
		hit_deck.discard([card])
	elif not card.def.is_empty() and player_deck != null:
		player_deck.discard(card)


func _deal(c: Combatant) -> Card:
	var card := hit_deck.draw()
	if card == null:
		return null
	if card == peeked_card:
		peeked_card = null
	add_table_card(c, card)
	return card


## Unplayed hand cards carry over; draw up to hand_draw_to, never above hand_max.
func draw_hand() -> void:
	var draw_to := mini(int(round_rule("hand_draw_to", 3)), int(round_rule("hand_max", 5)))
	draw_cards(maxi(0, draw_to - hand.size()))


func draw_cards(n: int) -> void:
	if player_deck == null:
		return
	var hand_max := int(round_rule("hand_max", 5))
	for _i in n:
		if hand.size() >= hand_max:
			break
		var card := player_deck.draw()
		if card == null:
			break
		hand.append(card)
	hand_changed.emit()


# --- ROUND_ACTIVE: player actions --------------------------------------------

## Hit: draw the top blind card. Going bust ends your turn.
func player_hit() -> Card:
	if player.stayed:
		return null
	var card := _deal(player)
	_check_player_bust()
	return card


## Stay: lock your total for this round (surprise attacks can still hit you).
func player_stay() -> void:
	player.stayed = true


func can_play(index: int) -> bool:
	if player.stayed or plays_left <= 0 or index < 0 or index >= hand.size():
		return false
	var effect := EffectRegistry.card_effect(hand[index].effect_name())
	return effect != null and effect.can_play(self, params_for(hand[index]))


## Play a hand card. `choice` holds the player's picks (e.g. {"value": 3} for Painted Rose).
func play_card(index: int, choice: Dictionary = {}) -> bool:
	if not can_play(index):
		return false
	var card: Card = hand[index]
	hand.remove_at(index)
	plays_left -= 1
	var params := params_for(card)
	params.merge(choice, true)
	params["_card"] = card
	EffectRegistry.card_effect(card.effect_name()).apply(self, params)
	# Numbers stay on the table until the round ends; effect cards go straight to the discard.
	if not card.is_number():
		player_deck.discard(card)
	card_played.emit(card)
	hand_changed.emit()
	_check_player_bust()
	return true


func params_for(card: Card) -> Dictionary:
	var params: Dictionary = card.def.get("params", {})
	return params.duplicate(true)


func _check_player_bust() -> void:
	if player.is_bust(target):
		player.stayed = true


# --- helpers used by effect scripts -----------------------------------------

func add_table_card(c: Combatant, card: Card) -> void:
	c.table.append(card)
	card_dealt.emit(c.side, card)
	emit_total_changed(c)


func remove_table_card(c: Combatant, card: Card) -> void:
	var index := c.table.find(card)
	if index < 0:
		return
	c.table.remove_at(index)
	_discard(card)
	card_removed.emit(c.side, card)
	emit_total_changed(c)


func emit_total_changed(c: Combatant) -> void:
	total_changed.emit(c.side, c.total(target))


func peek_next() -> Card:
	peeked_card = hit_deck.peek()
	peeked.emit(peeked_card)
	return peeked_card


func request_timer_freeze(seconds: float) -> void:
	timer_freeze_requested.emit(seconds)


# --- enemy -------------------------------------------------------------------

func enemy_hit() -> Card:
	if enemy.stayed:
		return null
	var card := _deal(enemy)
	if enemy.is_bust(target):
		enemy.stayed = true
	return card


func enemy_stay() -> void:
	enemy.stayed = true


## Seconds for the intent bar to fill (the Queen speeds up when enraged).
func intent_seconds() -> float:
	var rage: Dictionary = enemy_def.get("rage", {})
	if phase >= 2 and rage.has("intent_seconds"):
		return float(rage["intent_seconds"])
	return float(enemy_def.get("intent_seconds", 9))


## Rage meter: below 50% HP the Queen is enraged (stays at 19, attacks faster).
func _check_boss_phase() -> void:
	var rage: Dictionary = enemy_def.get("rage", {})
	if rage.is_empty() or phase != 1 or enemy.is_dead():
		return
	if float(enemy.hp) < float(enemy.max_hp) * float(rage.get("below_hp_ratio", 0.5)):
		phase = 2
		enemy_stay_at = int(rage.get("stay_at", enemy_stay_at))
		boss_phase_changed.emit(2)


## Which surprise attack fires next (the Queen cycles a learnable pattern).
func next_surprise() -> String:
	var kind := str(enemy_def.get("surprise", ""))
	if kind == "queen_rotation":
		var surprise_params: Dictionary = enemy_def.get("surprise_params", {})
		var pattern: Array = surprise_params.get("pattern", [])
		if pattern.is_empty():
			return ""
		return str(pattern[surprise_count % pattern.size()])
	return kind


## SURPRISE: the intent bar filled. Returns the attack's kind.
func fire_surprise() -> String:
	var kind := next_surprise()
	surprise_count += 1
	if kind.is_empty():
		return kind
	if shield > 0:
		shield -= 1
		surprise_blocked.emit(enemy_id(), kind)
		return kind
	var effect := EffectRegistry.enemy_effect(kind)
	var params: Dictionary = enemy_def.get("surprise_params", {})
	params = params.duplicate(true)
	if effect != null and effect.can_play(self, params):
		effect.apply(self, params)
	surprise_attack.emit(enemy_id(), kind)
	_check_player_bust()
	return kind


# --- RESOLVE -------------------------------------------------------------------

func both_done() -> bool:
	return player.stayed and enemy.stayed


## The round timer ran out: everyone stays.
func force_stay() -> void:
	player.stayed = true
	enemy.stayed = true


## Compare totals and apply the damage table.
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
	# Heart Soldier heals when it wins a round.
	var heal_on_win := int(enemy_def.get("heal_on_win", 0))
	if result["winner"] == "enemy" and heal_on_win > 0 and not enemy.is_dead():
		enemy.heal(heal_on_win)
	_check_boss_phase()
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
