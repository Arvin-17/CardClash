extends Node
## The current run: everything that survives between battles. Saved to user://run.json
## after every battle so a crash doesn't wipe the demo. `stats` feeds the backend's stats
## screen and is incremented from battle signals.

const SAVE_PATH := "user://run.json"
const SETTINGS_PATH := "user://settings.cfg"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const MAP_SCENE := "res://scenes/map.tscn"
const BATTLE_SCENE := "res://scenes/battle.tscn"
const REWARD_SCENE := "res://scenes/reward.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"

var run_seed: int = 0
var hp: int = 30
var max_hp: int = 30
var gold: int = 0
var deck: Array[String] = []
var trinkets: Array[String] = []
## The act being played: act1_tea, then act2_wood, then act3_court (acts.json order).
var act_id: String = "act1_tea"
var act_index: int = 0
## This act's battle order: shuffled soldiers, boss last.
var battles: Array[String] = []
var battle_index: int = 0
## Wins across the whole run (all acts), for the ending and the leaderboard.
var battles_won: int = 0
var is_daily: bool = false
var daily_date: String = ""
var stats: Dictionary = {}
var active: bool = false
## How the run ended, for the ending screen: {"won": bool, "enemy": id}.
var outcome: Dictionary = {}
## A trinket found after the last win (shown on the reward screen), or "".
var last_trinket: String = ""
var player_name: String = "ALICE"

var _elapsed_ms: int = 0
var _segment_start: int = 0


func _ready() -> void:
	_load_settings()
	stats = _empty_stats()
	Events.round_resolved.connect(_on_round_resolved)
	Events.card_played.connect(_on_card_played)


func new_run(seed_value: int, daily: bool = false, date: String = "") -> void:
	run_seed = seed_value
	Rng.set_seed(seed_value)
	is_daily = daily
	daily_date = date
	max_hp = int(GameData.rule("player.max_hp", 30))
	hp = max_hp
	gold = 0
	deck.clear()
	for id: Variant in GameData.rule("starter_deck", []):
		deck.append(str(id))
	trinkets.clear()
	act_index = 0
	act_id = act_ids()[0]
	battle_index = 0
	battles_won = 0
	stats = _empty_stats()
	outcome = {}
	last_trinket = ""
	_elapsed_ms = 0
	_segment_start = Time.get_ticks_msec()
	battles = act_order(act_id, Rng.rng)
	active = true


## The acts in play order (acts.json order): Tea Party, Tulgey Wood, Queen's Court.
static func act_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: Variant in GameData.acts:
		ids.append(str(id))
	return ids


## Every fight in a full run, across all acts.
static func total_battles() -> int:
	var n := 0
	for id: String in act_ids():
		n += (GameData.act(id).get("battles", []) as Array).size()
	return n


## Shuffle the soldiers with the run seed so each run's order differs; the boss is always last.
static func act_order(id: String, rng: RandomNumberGenerator) -> Array[String]:
	var act: Dictionary = GameData.act(id)
	var soldiers: Array[String] = []
	var bosses: Array[String] = []
	for enemy_id: Variant in act.get("battles", []):
		if bool(GameData.enemy(str(enemy_id)).get("boss", false)):
			bosses.append(str(enemy_id))
		else:
			soldiers.append(str(enemy_id))
	if bool(act.get("shuffle_soldiers", false)):
		Shuffle.shuffle(soldiers, rng)
	soldiers.append_array(bosses)
	return soldiers


func current_enemy_id() -> String:
	if battles.is_empty():
		battles = act_order(act_id, Rng.rng)
	return battles[clampi(battle_index, 0, battles.size() - 1)]


## This act's fights are all won (its boss is down).
func act_complete() -> bool:
	return battle_index >= battles.size()


func is_final_act() -> bool:
	return act_index >= act_ids().size() - 1


## The whole run is won: the last act's boss, the Queen, is down.
func is_complete() -> bool:
	return act_complete() and is_final_act()


## After an act's boss (and the shop): down the rabbit hole into the next act.
func advance_act() -> void:
	if is_final_act():
		return
	act_index += 1
	act_id = act_ids()[act_index]
	battles = act_order(act_id, Rng.rng)
	battle_index = 0
	save()


## After each win: gold (run.gold_per_soldier for soldiers, plus any enemy's bonus_gold, which
## is how the Hatter and the Cat pay for the shop between acts) and a small heal.
## No full heals, so damage carries tension across the act.
func record_win(enemy_id: String) -> Dictionary:
	var enemy: Dictionary = GameData.enemy(enemy_id)
	var earned := int(enemy.get("bonus_gold", 0))
	if not bool(enemy.get("boss", false)):
		earned += int(GameData.rule("run.gold_per_soldier", 10))
	gold += earned
	var healed := mini(int(GameData.rule("run.heal_after_win", 5)), max_hp - hp)
	hp += maxi(0, healed)
	battle_index += 1
	battles_won += 1
	last_trinket = ""
	if battles_won == int(GameData.rule("run.trinket_after_battle", 2)):
		_award_trinket()
	if is_complete():
		outcome = {"won": true, "enemy": enemy_id}
	save()
	return {"gold": earned, "healed": healed}


## Trinkets are given after the 2nd soldier: a random one Alice doesn't own yet.
func _award_trinket() -> void:
	var options: Array = GameData.trinkets.keys().filter(func(id: String) -> bool: return not trinkets.has(id))
	if options.is_empty():
		return
	options.sort()
	last_trinket = str(options[Rng.rng.randi_range(0, options.size() - 1)])
	trinkets.append(last_trinket)


func trinket_defs() -> Array:
	return trinkets.map(func(id: String) -> Dictionary: return GameData.trinkets.get(id, {}))


func record_loss(enemy_id: String) -> void:
	hp = 0
	outcome = {"won": false, "enemy": enemy_id}
	save()


## Where to go after a battle: rewards between fights, the ending when it's over.
func scene_after_battle() -> String:
	return ENDING_SCENE if not outcome.is_empty() else REWARD_SCENE


func add_card(id: String) -> void:
	deck.append(id)


func remove_card(index: int) -> void:
	if index >= 0 and index < deck.size():
		deck.remove_at(index)


## Shop: spend gold on a card. False (and nothing changes) when you can't afford it.
func buy_card(id: String, price: int) -> bool:
	if price < 0 or price > gold:
		return false
	gold -= price
	deck.append(id)
	return true


## Shop: pay to remove a deck card, never going below the minimum deck size.
func remove_card_for(index: int, price: int, min_deck: int) -> bool:
	if price < 0 or price > gold or index < 0 or index >= deck.size() or deck.size() <= min_deck:
		return false
	gold -= price
	deck.remove_at(index)
	return true


func time_ms() -> int:
	return _elapsed_ms + (Time.get_ticks_msec() - _segment_start)


## The POST /run payload (the backend contract: never rename a field without telling backend).
func run_payload() -> Dictionary:
	return {
		"player_name": player_name,
		"seed": run_seed,
		"is_daily": is_daily,
		"won": bool(outcome.get("won", false)),
		"act": act_id,
		"battles_won": battles_won,
		"time_ms": time_ms(),
		"stats": _int_stats(),
		"game_version": GameData.game_version(),
	}


## JSON round-trips turn ints into floats; the backend wants ints.
func _int_stats() -> Dictionary:
	var played := {}
	var source: Dictionary = stats.get("cards_played", {})
	for id: Variant in source:
		played[str(id)] = int(source[id])
	return {
		"rounds": int(stats.get("rounds", 0)),
		"busts": int(stats.get("busts", 0)),
		"blackjacks": int(stats.get("blackjacks", 0)),
		"cards_played": played,
	}


func end_run() -> void:
	active = false
	clear_save()


# --- stats from battle signals ---------------------------------------------------

func _empty_stats() -> Dictionary:
	return {"rounds": 0, "busts": 0, "blackjacks": 0, "cards_played": {}}


func _on_round_resolved(result: Dictionary) -> void:
	if not active:
		return
	stats["rounds"] = int(stats["rounds"]) + 1
	if bool(result.get("player_bust", false)):
		stats["busts"] = int(stats["busts"]) + 1
	if bool(result.get("blackjack", false)):
		stats["blackjacks"] = int(stats["blackjacks"]) + 1


func _on_card_played(card: Card) -> void:
	if not active or card.def.is_empty():
		return
	var played: Dictionary = stats["cards_played"]
	played[card.id] = int(played.get(card.id, 0)) + 1


# --- save / continue -------------------------------------------------------------

func save() -> void:
	var data := {
		"run_seed": run_seed,
		"rng_state": str(Rng.rng.state),  # 64-bit: a JSON float would lose precision
		"hp": hp,
		"max_hp": max_hp,
		"gold": gold,
		"deck": deck,
		"trinkets": trinkets,
		"act_id": act_id,
		"act_index": act_index,
		"battles": battles,
		"battle_index": battle_index,
		"battles_won": battles_won,
		"is_daily": is_daily,
		"daily_date": daily_date,
		"stats": stats,
		"outcome": outcome,
		"elapsed_ms": time_ms(),
		"game_version": GameData.game_version(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_saved() -> bool:
	if not has_save():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY or str(data.get("game_version", "")) != GameData.game_version():
		clear_save()
		return false
	run_seed = int(data["run_seed"])
	Rng.set_seed(run_seed)
	Rng.rng.state = str(data.get("rng_state", str(Rng.rng.state))).to_int()
	hp = int(data["hp"])
	max_hp = int(data["max_hp"])
	gold = int(data["gold"])
	deck.assign((data["deck"] as Array).map(func(x: Variant) -> String: return str(x)))
	trinkets.assign((data.get("trinkets", []) as Array).map(func(x: Variant) -> String: return str(x)))
	act_id = str(data["act_id"])
	act_index = int(data.get("act_index", maxi(0, act_ids().find(act_id))))
	battles.assign((data["battles"] as Array).map(func(x: Variant) -> String: return str(x)))
	battle_index = int(data["battle_index"])
	battles_won = int(data.get("battles_won", battle_index))
	is_daily = bool(data.get("is_daily", false))
	daily_date = str(data.get("daily_date", ""))
	stats = data.get("stats", _empty_stats())
	outcome = data.get("outcome", {})
	_elapsed_ms = int(data.get("elapsed_ms", 0))
	_segment_start = Time.get_ticks_msec()
	active = true
	# Saved right after an act's boss: carry on into the next act.
	if outcome.is_empty() and act_complete() and not is_final_act():
		advance_act()
	return true


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# --- settings ----------------------------------------------------------------------

func set_player_name(value: String) -> void:
	var cleaned := value.strip_edges().left(16)
	player_name = cleaned if not cleaned.is_empty() else "ALICE"
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		player_name = str(cfg.get_value("player", "name", "ALICE"))
