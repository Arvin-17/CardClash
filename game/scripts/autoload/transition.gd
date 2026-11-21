extends CanvasLayer
## Scene changes with style.
##   go(path):           the card wipe - card backs flip in a diagonal wave to cover the screen,
##                       the scene changes underneath, then they flip away to reveal it.
##   rabbit_hole(path):  Alice falls down the rabbit hole (start of a run), the act's name
##                       appears, then a white fade into the next scene. Any key skips it.
## Headless runs (tests, autoplay, CI) change scenes instantly.

const COLS := 8
const ROWS := 5
const FLIP := 0.16
const WAVE := 0.28

var busy: bool = false
var _cells: Array[TextureRect] = []
var _root: Control
var _hole: AnimatedSprite2D
var _title: Label
var _white: ColorRect
var _skip: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)


func _instant() -> bool:
	return DisplayServer.get_name() == "headless" or Autoplay.enabled()


func go(path: String) -> void:
	if busy:
		return
	if _instant() or not is_inside_tree():
		get_tree().change_scene_to_file(path)
		return
	busy = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_make_cells()
	await _wave(true)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _wave(false)
	_clear_cells()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false


func _make_cells() -> void:
	_clear_cells()
	var back := _card_back()
	var w := 480.0 / COLS
	var h := 270.0 / ROWS
	for j in ROWS:
		for i in COLS:
			var c := TextureRect.new()
			c.texture = back
			c.stretch_mode = TextureRect.STRETCH_SCALE
			c.size = Vector2(w, h)
			c.position = Vector2(i * w, j * h)
			c.pivot_offset = Vector2(w / 2.0, h / 2.0)
			c.scale = Vector2(0.0, 1.0)
			c.set_meta("d", float(i + j) / float(COLS + ROWS - 2))
			_root.add_child(c)
			_cells.append(c)


## Covering: each card flips in from edge-on; uncovering: each flips back out.
func _wave(cover: bool) -> void:
	var t := create_tween().set_parallel()
	for c in _cells:
		var d: float = c.get_meta("d")
		t.tween_property(c, "scale:x", 1.0 if cover else 0.0, FLIP).set_delay(d * WAVE)
	await t.finished


func _clear_cells() -> void:
	for c in _cells:
		c.queue_free()
	_cells.clear()


## A big card back drawn from the deck atlas (falls back to a red panel colour).
func _card_back() -> Texture2D:
	var tex := AnimLib.card_texture("", "", true)
	if tex:
		return tex
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Palette.RED_DARK)
	return ImageTexture.create_from_image(img)


func rabbit_hole(path: String, act_name: String) -> void:
	if busy:
		return
	if _instant() or not AnimLib.has("rabbit_hole"):
		go(path)
		return
	busy = true
	_skip = false
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_hole = AnimLib.sprite({"fall": "rabbit_hole"})
	_root.add_child(_hole)
	_title = Palette.shadow_label(act_name.to_upper(), Palette.GOLD_HI, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size = Vector2(480, 18)
	_title.position = Vector2(0, 118)
	_title.pivot_offset = Vector2(240, 9)
	_title.scale = Vector2(2, 2)
	_title.modulate.a = 0.0
	_root.add_child(_title)
	_white = ColorRect.new()
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.color = Color(Color.WHITE, 0.0)
	_root.add_child(_white)
	var t := create_tween()
	t.tween_interval(4.6)
	t.tween_property(_title, "modulate:a", 1.0, 0.4)
	t.tween_interval(1.2)
	t.tween_property(_white, "color:a", 1.0, 0.5)
	while t.is_running() and not _skip:
		await get_tree().process_frame
	t.kill()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_hole.queue_free()
	_title.queue_free()
	_white.color.a = 1.0
	var fade := create_tween()
	fade.tween_property(_white, "color:a", 0.0, 0.4)
	await fade.finished
	_white.queue_free()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false


func _unhandled_input(event: InputEvent) -> void:
	if _hole and is_instance_valid(_hole) and event.is_pressed():
		_skip = true
		get_viewport().set_input_as_handled()
