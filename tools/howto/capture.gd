extends SceneTree
## Takes the How to Play screen's screenshots from the real game, in set-up situations.
## It needs a window (no --headless), since screenshots come from the renderer:
##   cd game && godot --path . --resolution 480x270 --script "$PWD/../tools/howto/capture.gd"
## Writes game/art/howto/*.png. Re-run it whenever the battle screen's look changes.
## Crops are sized so the How to Play screen shows them at exactly 1:1 (pixel text stays sharp):
## at most 284x206 beside the text, or 456x170 above it.

const OUT := "res://art/howto/"

var _run_state: Node
var _events: Node


func _initialize() -> void:
	await _frames(3)  # let the autoloads finish _ready
	_run_state = root.get_node("RunState")
	_events = root.get_node("Events")
	await _battle_shots()
	await _shop_shot()
	await _map_shot()
	print("how-to-play screenshots written to ", ProjectSettings.globalize_path(OUT))
	quit()


func _battle_shots() -> void:
	_run_state.new_run(7)
	change_scene_to_file(_run_state.BATTLE_SCENE)
	await _seconds(1.6)  # opening deal
	var c: Node = current_scene.get_node("BattleController")
	var ui: Node = current_scene.get_node("UI")
	for t: Timer in [c.ai_timer, c.intent_timer, c.round_timer]:
		t.paused = true  # freeze the table for the photos
	var b = c.battle
	_table(b.player, [["10", "hearts"], ["Q", "spades"]])
	_table(b.enemy, [["9", "clubs"], ["9", "diamonds"]])
	b.cards_played = 0
	ui._message.text = ""
	ui._refresh()
	await _seconds(0.6)
	_save("table", Rect2i(150, 96, 284, 144))
	_save("buttons", Rect2i(120, 168, 356, 102))

	# A bust: 24, the BUST! banner, and the message that a card can still save you.
	b.player.table.append(_card("4", "clubs"))
	_events.total_changed.emit("player", b.player.total(b.target))
	_events.message.emit("BUST AT 24! A CARD CAN STILL SAVE YOU.")
	await _seconds(0.35)
	_save("bust", Rect2i(98, 56, 284, 176))


func _shop_shot() -> void:
	_run_state.new_run(7)
	_run_state.gold = 35
	change_scene_to_file(_run_state.REWARD_SCENE)
	await _seconds(0.8)
	current_scene._buy(0)
	await _seconds(0.7)
	_save("shop", Rect2i(12, 0, 456, 166))


func _map_shot() -> void:
	_run_state.new_run(7)
	_run_state.record_win(_run_state.current_enemy_id())
	change_scene_to_file(_run_state.MAP_SCENE)
	await _seconds(0.8)
	_save("map", Rect2i(98, 14, 284, 180))


func _table(side: Object, cards: Array) -> void:
	side.table.clear()
	for rc: Array in cards:
		side.table.append(_card(rc[0], rc[1]))


func _card(rank: String, suit: String) -> Object:
	return load("res://scripts/core/card.gd").blind(rank, suit)


func _save(file_name: String, region: Rect2i) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.get_region(region).save_png(OUT + file_name + ".png")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _seconds(s: float) -> void:
	await create_timer(s).timeout
