extends Control
## After each win: choose 1 of 3 random reward cards, or remove one card from your deck, or skip.

var _offer: Array[String] = []
var _list: VBoxContainer
var _done: bool = false


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_center(Palette.label("SPOILS OF THE COURT", Palette.RED, true), 14)
	_center(Palette.label("GOLD %d   HP %d/%d   DECK %d" % [RunState.gold, RunState.hp, RunState.max_hp, RunState.deck.size()], Palette.GREEN), 36)
	_center(Palette.label("TAKE ONE CARD [1-3], REMOVE A CARD [R] OR SKIP [K]", Palette.CREAM), 50)
	if not RunState.last_trinket.is_empty():
		var t: Dictionary = GameData.trinkets.get(RunState.last_trinket, {})
		_center(Palette.label("TRINKET FOUND: %s - %s" % [str(t.get("name", "")).to_upper(), str(t.get("text", "")).to_upper()], Palette.RED), 254)

	_offer = Rewards.roll(GameData.cards, GameData.rule("run.rarity_weights", {}), int(GameData.rule("run.reward_choices", 3)), Rng.rng)
	for i in _offer.size():
		var d: Dictionary = GameData.card(_offer[i])
		var b := Button.new()
		b.position = Vector2(44 + i * 136, 68)
		b.size = Vector2(120, 96)
		b.focus_mode = Control.FOCUS_NONE
		var rare := str(d.get("rarity", "")) == "rare"
		b.add_theme_stylebox_override("normal", Palette.box(Palette.CREAM, Palette.RED if rare else Palette.BLACK, 2 if rare else 1))
		b.add_theme_stylebox_override("hover", Palette.box(Palette.CREAM, Palette.RED, 2))
		b.pressed.connect(_take.bind(i))
		add_child(b)
		_in(b, "%d  %s" % [i + 1, str(d.get("name", "")).to_upper()], Palette.BLACK, Vector2(6, 6))
		_in(b, str(d.get("rarity", "")).to_upper(), Palette.RED if rare else Palette.GREEN, Vector2(6, 16))
		# Width and wrap mode go in before the text, so the label can't grow past the card.
		var text := Label.new()
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		text.custom_minimum_size = Vector2(108, 0)
		text.size = Vector2(108, 56)
		text.position = Vector2(6, 32)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_color_override("font_color", Palette.BLACK)
		text.text = str(d.get("text", "")).to_upper()
		b.add_child(text)

	_button("REMOVE A CARD [R]", Vector2(120, 176), _show_removals)
	_button("SKIP [K]", Vector2(272, 176), _skip)
	_list = VBoxContainer.new()
	_list.position = Vector2(120, 198)
	add_child(_list)
	if Autoplay.enabled():
		Autoplay.after(self, 0.3, _take.bind(0))


func _center(l: Label, y: int) -> void:
	l.position = Vector2(0, y)
	l.size = Vector2(480, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


func _in(parent: Control, text: String, color: Color, pos: Vector2) -> Label:
	var l := Palette.label(text, color)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(text: String, pos: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(120, 16)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.CREAM))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.BLACK, Palette.RED))
	b.pressed.connect(action)
	add_child(b)


## Remove one card: list the deck as small buttons.
func _show_removals() -> void:
	for child in _list.get_children():
		child.queue_free()
	var row := HFlowContainer.new()
	row.custom_minimum_size = Vector2(240, 0)
	_list.add_child(row)
	for i in RunState.deck.size():
		var d: Dictionary = GameData.card(RunState.deck[i])
		var b := Button.new()
		b.text = str(d.get("name", RunState.deck[i])).to_upper()
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.GREEN))
		b.add_theme_stylebox_override("hover", Palette.box(Palette.RED, Palette.CREAM))
		b.pressed.connect(_remove.bind(i))
		row.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1, KEY_2, KEY_3:
			_take(key.keycode - KEY_1)
		KEY_R:
			_show_removals()
		KEY_K:
			_skip()


func _take(i: int) -> void:
	if i < _offer.size():
		RunState.add_card(_offer[i])
		_finish()


func _remove(i: int) -> void:
	RunState.remove_card(i)
	_finish()


func _skip() -> void:
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	RunState.save()
	get_tree().change_scene_to_file(RunState.MAP_SCENE)
