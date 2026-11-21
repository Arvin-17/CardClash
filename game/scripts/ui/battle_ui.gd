extends Control
## The battle table. Listens to Events and draws; sends player requests to the controller.
## It never changes game state itself.

@onready var controller: BattleController = get_parent().get_node("BattleController")

var _enemy_row: HBoxContainer
var _player_row: HBoxContainer
var _enemy_total: Label
var _player_total: Label
var _enemy_name: Label
var _enemy_hp: Label
var _player_hp: Label
var _round: Label
var _message: Label
var _hit: Button
var _stay: Button
var _overlay: Panel
var _overlay_title: Label
var _overlay_button: Button


func _ready() -> void:
	_build()
	Events.round_started.connect(_on_round_started)
	Events.card_dealt.connect(func(_who: String, _card: Card) -> void: _refresh())
	Events.total_changed.connect(func(_who: String, _total: int) -> void: _refresh())
	Events.hp_changed.connect(_on_hp_changed)
	Events.round_resolved.connect(_on_round_resolved)
	Events.message.connect(func(text: String) -> void: _message.text = text)
	Events.battle_won.connect(func(_id: String) -> void: _show_end(true))
	Events.battle_lost.connect(func(_id: String) -> void: _show_end(false))


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var felt := Panel.new()
	felt.add_theme_stylebox_override("panel", Palette.box(Palette.GREEN, Palette.CREAM))
	felt.position = Vector2(8, 80)
	felt.size = Vector2(464, 104)
	add_child(felt)

	# Enemy across the table (placeholder portrait until the designer's sprite lands).
	var portrait := ColorRect.new()
	portrait.color = Palette.RED
	portrait.position = Vector2(216, 18)
	portrait.size = Vector2(48, 56)
	add_child(portrait)
	_enemy_name = _label(Vector2(120, 24), "", Palette.CREAM)
	_enemy_hp = _label(Vector2(120, 34), "", Palette.RED)

	_round = _label(Vector2(6, 4), "ROUND 1", Palette.CREAM)
	_enemy_row = _row(Vector2(180, 86))
	_enemy_total = _label(Vector2(360, 96), "", Palette.CREAM)
	_message = _label(Vector2(0, 126), "", Palette.CREAM)
	_message.size = Vector2(480, 8)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_row = _row(Vector2(180, 146))
	_player_total = _label(Vector2(360, 156), "", Palette.CREAM)
	_player_hp = _label(Vector2(8, 240), "", Palette.RED)

	_hit = _button(Vector2(330, 236), "HIT [H]", controller.hit)
	_stay = _button(Vector2(400, 236), "STAY [S]", controller.stay)

	_overlay = Panel.new()
	_overlay.add_theme_stylebox_override("panel", Palette.box(Palette.BLACK, Palette.CREAM))
	_overlay.position = Vector2(140, 90)
	_overlay.size = Vector2(200, 80)
	_overlay.visible = false
	add_child(_overlay)
	_overlay_title = Palette.label("", Palette.CREAM, true)
	_overlay_title.position = Vector2(0, 14)
	_overlay_title.size = Vector2(200, 16)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(_overlay_title)
	_overlay_button = Button.new()
	_overlay_button.text = "CONTINUE"
	_overlay_button.position = Vector2(60, 50)
	_overlay_button.size = Vector2(80, 16)
	_overlay_button.pressed.connect(_on_continue)
	_overlay.add_child(_overlay_button)


func _label(pos: Vector2, text: String, color: Color) -> Label:
	var l := Palette.label(text, color)
	l.position = pos
	add_child(l)
	return l


func _row(pos: Vector2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.position = pos
	row.add_theme_constant_override("separation", 3)
	add_child(row)
	return row


func _button(pos: Vector2, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(64, 18)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.CREAM))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.BLACK, Palette.RED))
	b.add_theme_stylebox_override("pressed", Palette.box(Palette.RED, Palette.CREAM))
	b.add_theme_stylebox_override("disabled", Palette.box(Palette.BLACK, Palette.GREEN))
	b.pressed.connect(action)
	add_child(b)
	return b


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_H:
			controller.hit()
		KEY_S:
			controller.stay()
		KEY_ENTER, KEY_SPACE:
			if _overlay.visible:
				_on_continue()


func _on_round_started(n: int) -> void:
	_round.text = "ROUND %d" % n
	_message.text = ""
	_refresh()


func _refresh() -> void:
	var b := controller.battle
	if b == null:
		return
	_fill(_enemy_row, b.enemy.table)
	_fill(_player_row, b.player.table)
	_enemy_name.text = b.enemy.display_name.to_upper()
	_enemy_total.text = "= %d" % b.enemy.total(b.target)
	var pt := b.player.total(b.target)
	_player_total.text = "= %d%s" % [pt, "  BUST" if pt > b.target else ""]
	_player_total.add_theme_color_override("font_color", Palette.RED if pt > b.target else Palette.CREAM)
	var can_act := controller.state == BattleController.State.ROUND_ACTIVE and not b.player.stayed
	_hit.disabled = not can_act
	_stay.disabled = not can_act


func _fill(row: HBoxContainer, cards: Array[Card]) -> void:
	for child in row.get_children():
		child.queue_free()
	for c: Card in cards:
		var v := CardView.new()
		v.show_card(c)
		row.add_child(v)


func _on_hp_changed(who: String, hp: int, max_hp: int) -> void:
	if who == "player":
		_player_hp.text = "ALICE HP %d/%d" % [hp, max_hp]
	else:
		_enemy_hp.text = "HP %d/%d" % [hp, max_hp]


func _on_round_resolved(r: Dictionary) -> void:
	_refresh()
	var text := ""
	match str(r["kind"]):
		"both_bust":
			text = "Both bust! Messy round: -%d each." % int(r["messy_damage"])
		"tie":
			text = "Tie. No damage."
		_:
			var who := "You win" if r["winner"] == "player" else "Enemy wins"
			text = "%s: %d damage%s" % [who, int(r["damage"]), " CRITICAL!" if r["critical"] else ""]
	_message.text = text
	_hit.disabled = true
	_stay.disabled = true


func _show_end(won: bool) -> void:
	_overlay_title.text = "VICTORY!" if won else "OFF WITH HER HEAD!"
	_overlay_title.add_theme_color_override("font_color", Palette.CREAM if won else Palette.RED)
	_overlay.visible = true


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
