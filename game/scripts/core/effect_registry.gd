class_name EffectRegistry
extends RefCounted
## Maps the `effect` names in cards.json / the `surprise` names in enemies.json to scripts
## by convention, so a new card is data plus at most one small script, never battle code:
##   card effects:      res://scripts/effects/<name>.gd
##   surprise attacks:  res://scripts/effects/enemy/<name>.gd

const CARD_DIR := "res://scripts/effects/"
const ENEMY_DIR := "res://scripts/effects/enemy/"

static var _cache: Dictionary = {}


static func card_effect(effect_name: String) -> CardEffect:
	return _load(CARD_DIR + effect_name + ".gd")


static func enemy_effect(kind: String) -> CardEffect:
	return _load(ENEMY_DIR + kind + ".gd")


static func _load(path: String) -> CardEffect:
	if _cache.has(path):
		return _cache[path]
	var effect: CardEffect = null
	if ResourceLoader.exists(path):
		var script: GDScript = load(path)
		effect = script.new()
	_cache[path] = effect
	return effect
