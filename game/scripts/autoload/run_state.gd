extends Node
## The current run: everything that survives between battles. Saved to user://run.json
## after every battle so a crash doesn't wipe the run. `stats` (rounds, busts, blackjacks)
## feeds the ending screen and is incremented from battle signals.

const SAVE_PATH := "user://run.json"
const SETTINGS_PATH := "user://settings.cfg"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const MAP_SCENE := "res://scenes/map.tscn"
const BATTLE_SCENE := "res://scenes/battle.tscn"
const REWARD_SCENE := "res://scenes/reward.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"
const HOWTO_SCENE := "res://scenes/how_to_play.tscn"

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
## Wins across the whole run (all acts), for the map and the ending.
var battles_won: int = 0
## Demo mode: straight to the final boss. Never saved over a real run, never submitted.
var is_demo: bool = false
var stats: Dictionary = {}
var active: bool = false
## How the run ended, for the ending screen: {"won": bool, "enemy": id}.
var outcome: Dictionary = {}
## A trinket found after the last win (shown on the reward screen), or "".
var last_trinket: String = ""
## Has this player seen How to Play? It opens by itself on first launch until they have.
var seen_how_to_play: bool = false

var _elapsed_ms: int = 0
var _segment_start: int = 0


func _ready() -> void:
	_load_settings()
	stats = _empty_stats()
	Events.round_resolved.connect(_on_round_resolved)


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
	act_index = 0
	act_id = act_ids()[0]
	battle_index = 0
	battles_won = 0
	is_demo = false
	stats = _empty_stats()
	outcome = {}
	last_trinket = ""
	_elapsed_ms = 0
	_segment_start = Time.get_ticks_msec()
	battles = act_order(act_id, Rng.rng)
	active = true


## Demo mode: the final act, one fight (rules.json demo.enemy, the Queen), and the starter
## deck plus demo.extra_cards so there's something to show off.
func new_demo(seed_value: int) -> void:
	new_run(seed_value)
	is_demo = true
	act_index = act_ids().size() - 1
	act_id = act_ids()[act_index]
	battles.assign([str(GameData.rule("demo.enemy", "queen_of_hearts"))])
	battle_index = 0
	for id: Variant in GameData.rule("demo.extra_cards", []):
		deck.append(str(id))


## Fights in this run: all eight, or the demo's one.
func battles_in_run() -> int:
	return battles.size() if is_demo else total_battles()


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


func end_run() -> void:
	active = false
	if not is_demo:
		clear_save()  # a demo leaves any saved real run alone


# --- stats from battle signals ---------------------------------------------------

func _empty_stats() -> Dictionary:
	return {"rounds": 0, "busts": 0, "blackjacks": 0}


func _on_round_resolved(result: Dictionary) -> void:
	if not active:
		return
	stats["rounds"] = int(stats["rounds"]) + 1
	if bool(result.get("player_bust", false)):
		stats["busts"] = int(stats["busts"]) + 1
	if bool(result.get("blackjack", false)):
		stats["blackjacks"] = int(stats["blackjacks"]) + 1


# --- save / continue -------------------------------------------------------------

func save() -> void:
	if is_demo:
		return  # never overwrite a real run's save
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
	stats = data.get("stats", _empty_stats())
	outcome = data.get("outcome", {})
	_elapsed_ms = int(data.get("elapsed_ms", 0))
	_segment_start = Time.get_ticks_msec()
	is_demo = false
	active = true
	# Saved right after an act's boss: carry on into the next act.
	if outcome.is_empty() and act_complete() and not is_final_act():
		advance_act()
	return true


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# --- settings ----------------------------------------------------------------------

func mark_how_to_play_seen() -> void:
	seen_how_to_play = true
	_save_setting("player", "seen_how_to_play", true)


## Settings share one file: load it, change one key, save, so other keys survive.
func _save_setting(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		seen_how_to_play = bool(cfg.get_value("player", "seen_how_to_play", false))
