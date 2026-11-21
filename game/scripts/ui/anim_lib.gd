class_name AnimLib
extends RefCounted
## Loads the pixel-art animations exported by tools/sprites (game/art/anim/manifest.json)
## and turns them into SpriteFrames. Every sheet is a grid of equal frames, left to right.

const MANIFEST := "res://art/anim/manifest.json"

static var _manifest: Dictionary = {}
static var _frames_cache: Dictionary = {}
static var _deck_cache: Dictionary = {}


static func manifest() -> Dictionary:
	if _manifest.is_empty() and FileAccess.file_exists(MANIFEST):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest


static func has(key: String) -> bool:
	return manifest().has(key)


## One SpriteFrames holding several named animations: {"idle": "queen_of_hearts_idle", ...}.
## Missing sheets are skipped, so a half-finished art set still runs.
static func frames(anims: Dictionary) -> SpriteFrames:
	var cache_key := JSON.stringify(anims)
	if _frames_cache.has(cache_key):
		return _frames_cache[cache_key]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim_name: String in anims:
		var key: String = anims[anim_name]
		var m: Dictionary = manifest().get(key, {})
		var path := "res://art/" + str(m.get("file", ""))
		if m.is_empty() or not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(m.get("fps", 10)))
		sf.set_animation_loop(anim_name, bool(m.get("loop", true)))
		var w := int(m["w"])
		var h := int(m["h"])
		var cols := int(m["cols"])
		for i in int(m["frames"]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((i % cols) * w, (i / cols) * h, w, h)
			sf.add_frame(anim_name, at)
	_frames_cache[cache_key] = sf
	return sf


## A sprite playing one or more animations, top-left anchored.
static func sprite(anims: Dictionary, first: String = "") -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.centered = false
	s.sprite_frames = frames(anims)
	var start: String = first if not first.is_empty() else (str(anims.keys()[0]) if not anims.is_empty() else "")
	if s.sprite_frames.has_animation(start):
		s.play(start)
	return s


## Frame size of an exported animation (0x0 if missing).
static func size_of(key: String) -> Vector2:
	var m: Dictionary = manifest().get(key, {})
	return Vector2(int(m.get("w", 0)), int(m.get("h", 0)))


## A blind-deck card face (rank "A".."K", suit "spades"...) or the card back.
static func card_texture(rank: String, suit: String, back: bool = false) -> Texture2D:
	var key := "back" if back else rank + suit
	if _deck_cache.has(key):
		return _deck_cache[key]
	var d: Dictionary = manifest().get("deck", {})
	if d.is_empty() or not ResourceLoader.exists("res://art/" + str(d["file"])):
		return null
	var ranks: Array = d["ranks"]
	var suits: Array = d["suits"]
	var col := 13 if back else ranks.find(rank)
	var row := 0 if back else suits.find(suit)
	if col < 0 or row < 0:
		return null
	var at := AtlasTexture.new()
	at.atlas = load("res://art/" + str(d["file"]))
	at.region = Rect2(col * int(d["w"]), row * int(d["h"]), int(d["w"]), int(d["h"]))
	_deck_cache[key] = at
	return at


## Built-deck card art: the big face (56x78) used when a card is played.
static func card_face(card_id: String) -> Texture2D:
	var path := "res://art/cards/big/%s.png" % card_id
	return load(path) if ResourceLoader.exists(path) else null


## The room behind the table for an act ("act3_court" -> room_act3_court).
static func room_key(act_id: String) -> String:
	for key: String in ["room_" + act_id, "room_act3_court"]:
		if has(key):
			return key
	return ""
