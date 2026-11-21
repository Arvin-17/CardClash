extends Control
## Title screen: new run, continue a saved run, set your leaderboard name, see if the server is up.

var _status: Label
var _name: LineEdit


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# The animated title screen (logo, crown, pocket-watch moon, falling cards, checkerboard
	# floor) from game/art/anim; plain text if the art isn't there.
	var y := 112
	if AnimLib.has("title"):
		add_child(AnimLib.sprite({"loop": "title"}))
		y = 140
	else:
		_center(Palette.label("CARDCLASH", Palette.RED, true), 50)
		_center(Palette.label("A BLACKJACK WONDERLAND", Palette.CREAM), 74)
		_center(Palette.label("GET CLOSER TO 21 THAN THE QUEEN'S SOLDIERS", Palette.GREEN), 86)
	_button("NEW RUN [ENTER]", y, _new_run)
	y += 22
	_button("DAILY RUN [D]", y, _daily_run)
	if RunState.has_save():
		y += 22
		_button("CONTINUE [C]", y, _continue)

	var name_label := Palette.label("NAME", Palette.CREAM)
	name_label.position = Vector2(180, y + 26)
	add_child(name_label)
	_name = LineEdit.new()
	_name.text = RunState.player_name
	_name.max_length = 16
	_name.position = Vector2(204, y + 22)
	_name.size = Vector2(96, 14)
	_name.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.GREEN))
	_name.add_theme_stylebox_override("focus", Palette.box(Palette.BLACK, Palette.RED))
	_name.text_changed.connect(RunState.set_player_name)
	_name.text_submitted.connect(func(_t: String) -> void: _name.release_focus())
	add_child(_name)

	_center(Palette.shadow_label("H HIT   SPACE READY   1-5 PLAY A CARD (2 PER ROUND)", Palette.GOLD_HI), 246)
	_status = Palette.shadow_label("CHECKING SERVER...", Palette.LAVENDER)
	_status.position = Vector2(4, 260)
	add_child(_status)

	if Autoplay.enabled():
		Autoplay.after(self, 0.2, _new_run)
	Api.health(_on_health)


func _on_health(online: bool) -> void:
	_status.text = "ONLINE" if online else "OFFLINE (THE GAME STILL WORKS; NO LEADERBOARD)"
	if online:
		Api.refresh_cards()


func _center(l: Label, y: int) -> void:
	l.position = Vector2(0, y)
	l.size = Vector2(480, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


func _button(text: String, y: int, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = Vector2(176, y)
	b.size = Vector2(128, 18)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Palette.box(Color(Palette.INK, 0.9), Palette.CREAM))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.PLUM, Palette.GOLD_HI))
	b.pressed.connect(action)
	add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _name.has_focus():
		return
	if key.keycode == KEY_ENTER or key.keycode == KEY_SPACE:
		_new_run()
	elif key.keycode == KEY_C and RunState.has_save():
		_continue()
	elif key.keycode == KEY_D:
		_daily_run()


func _new_run() -> void:
	if not is_inside_tree():
		return
	RunState.clear_save()
	RunState.new_run(Rng.new_seed())
	Transition.rabbit_hole(RunState.MAP_SCENE, str(GameData.act(RunState.act_id).get("name", "")))


## Daily Run: everyone gets the same seed today (from GET /daily-seed). Needs the server.
func _daily_run() -> void:
	_status.text = "FETCHING TODAY'S SEED..."
	Api.daily_seed(_on_daily_seed)


func _on_daily_seed(daily: Variant) -> void:
	if not (daily is Dictionary):
		_status.text = "DAILY RUN NEEDS THE SERVER. TRY A NEW RUN!"
		return
	RunState.clear_save()
	RunState.new_run(int(daily["seed"]), true, str(daily["date"]))
	Transition.rabbit_hole(RunState.MAP_SCENE, str(GameData.act(RunState.act_id).get("name", "")))


func _continue() -> void:
	if RunState.load_saved():
		Transition.go(RunState.scene_after_battle() if not RunState.outcome.is_empty() else RunState.MAP_SCENE)
