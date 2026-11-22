extends Control
## Title screen: new run, how to play, the Queen demo, continue a saved run.
## First launch opens How to Play before anything else. Single player, fully offline.


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
	_button("NEW RUN [ENTER]", Vector2(104, y), _new_run)
	_button("HOW TO PLAY [T]", Vector2(248, y), _how_to_play)
	y += 22
	if RunState.has_save():
		_button("QUEEN DEMO [Q]", Vector2(104, y), _demo)
		_button("CONTINUE [C]", Vector2(248, y), _continue)
	else:
		_button("QUEEN DEMO [Q]", Vector2(176, y), _demo)

	_center(Palette.shadow_label("H HIT   SPACE STAND   E HEAL   1-5 CARDS (2 PER ROUND)", Palette.GOLD_HI), 246)

	if Autoplay.enabled():
		Autoplay.after(self, 0.2, _demo if Autoplay.demo() else _new_run)
	elif not RunState.seen_how_to_play:
		_how_to_play.call_deferred()  # first launch: the rules before anything else


func _center(l: Label, y: int) -> void:
	l.position = Vector2(0, y)
	l.size = Vector2(480, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


func _button(text: String, pos: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(128, 18)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Palette.box(Color(Palette.INK, 0.9), Palette.CREAM))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.PLUM, Palette.GOLD_HI))
	b.pressed.connect(action)
	add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ENTER or key.keycode == KEY_SPACE:
		_new_run()
	elif key.keycode == KEY_C and RunState.has_save():
		_continue()
	elif key.keycode == KEY_T:
		_how_to_play()
	elif key.keycode == KEY_Q:
		_demo()


func _how_to_play() -> void:
	if is_inside_tree():
		Transition.go(RunState.HOWTO_SCENE)


## Demo mode: down the rabbit hole straight to the Queen. Doesn't touch a saved run.
func _demo() -> void:
	if not is_inside_tree():
		return
	RunState.new_demo(Rng.new_seed())
	Transition.rabbit_hole(RunState.BATTLE_SCENE, str(GameData.act(RunState.act_id).get("name", "")))


func _new_run() -> void:
	if not is_inside_tree():
		return
	RunState.clear_save()
	RunState.new_run(Rng.new_seed())
	Transition.rabbit_hole(RunState.MAP_SCENE, str(GameData.act(RunState.act_id).get("name", "")))


func _continue() -> void:
	if RunState.load_saved():
		Transition.go(RunState.scene_after_battle() if not RunState.outcome.is_empty() else RunState.MAP_SCENE)
