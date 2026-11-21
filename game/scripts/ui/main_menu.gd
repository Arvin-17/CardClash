extends Control
## Title screen: start a run, see whether the server is reachable.

var _status: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Palette.label("CARDCLASH", Palette.RED, true)
	title.position = Vector2(0, 60)
	title.size = Vector2(480, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := Palette.label("A BLACKJACK WONDERLAND", Palette.CREAM)
	sub.position = Vector2(0, 84)
	sub.size = Vector2(480, 8)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var start := Button.new()
	start.text = "NEW RUN [ENTER]"
	start.position = Vector2(180, 130)
	start.size = Vector2(120, 18)
	start.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.CREAM))
	start.add_theme_stylebox_override("hover", Palette.box(Palette.BLACK, Palette.RED))
	start.pressed.connect(_new_run)
	add_child(start)

	_status = Palette.label("CHECKING SERVER...", Palette.GREEN)
	_status.position = Vector2(4, 260)
	add_child(_status)
	var online: bool = await Api.health()
	if is_inside_tree():
		_status.text = "ONLINE" if online else "OFFLINE (LEADERBOARD UNAVAILABLE)"


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_SPACE):
		_new_run()


func _new_run() -> void:
	RunState.new_run(Rng.new_seed())
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
