extends Node
## Loads every JSON file under res://data once at startup.
## Lookups: GameData.card("drink_me"), GameData.enemy("club_soldier"), GameData.rule("round.seconds").

const DATA_DIR := "res://data/"

var rules: Dictionary = {}
var cards: Dictionary = {}
var enemies: Dictionary = {}
var acts: Dictionary = {}
var trinkets: Dictionary = {}
var cards_version: int = 0


func _ready() -> void:
	load_all()


func _exit_tree() -> void:
	EffectRegistry.clear_cache()


func load_all() -> void:
	rules = read_json("rules.json")
	apply_cards(read_json("cards.json"))
	enemies = _index(read_json("enemies.json").get("enemies", []))
	acts = _index(read_json("acts.json").get("acts", []))
	trinkets = _index(read_json("trinkets.json").get("trinkets", []))


## Replaces the card table (bundled file at startup, or a newer copy from GET /cards).
func apply_cards(data: Dictionary) -> void:
	var list: Array = data.get("cards", [])
	if list.is_empty():
		return
	cards = _index(list)
	cards_version = int(data.get("version", 0))


func card(id: String) -> Dictionary:
	return cards.get(id, {})


func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


func act(id: String) -> Dictionary:
	return acts.get(id, {})


## Nested lookup with a default, e.g. rule("round.seconds", 15).
func rule(path: String, fallback: Variant = null) -> Variant:
	var node: Variant = rules
	for key in path.split("."):
		if typeof(node) != TYPE_DICTIONARY or not (node as Dictionary).has(key):
			return fallback
		node = (node as Dictionary)[key]
	return node


func game_version() -> String:
	return str(rules.get("game_version", "0.0.0"))


static func read_json(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		push_error("missing data file %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("bad JSON in %s" % path)
		return {}
	return parsed


static func _index(list: Array) -> Dictionary:
	var out := {}
	for entry: Variant in list:
		if typeof(entry) == TYPE_DICTIONARY and (entry as Dictionary).has("id"):
			out[str(entry["id"])] = entry
	return out
