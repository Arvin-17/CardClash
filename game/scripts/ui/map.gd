extends Control
## Act progress: this act's fights (shuffled soldiers, then its boss), and which act of three.

const SUIT_ICON := {"spades": "♠", "clubs": "♣", "diamonds": "♦", "hearts": "♥"}


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# The act's room, dimmed, so the run feels like one place.
	var room_key := AnimLib.room_key(RunState.act_id)
	if not room_key.is_empty():
		var room := AnimLib.sprite({"loop": room_key})
		room.modulate = Color(0.32, 0.3, 0.38)
		add_child(room)
	var act: Dictionary = GameData.act(RunState.act_id)
	_add(Palette.label("ACT %d: %s" % [RunState.act_index + 1, str(act.get("name", "")).to_upper()], Palette.RED, true), Vector2(0, 24), 480)
	_add(Palette.label("SEED %d   ACT %d OF %d   BATTLES WON %d/%d" % [RunState.run_seed, RunState.act_index + 1, RunState.act_ids().size(), RunState.battles_won, RunState.total_battles()], Palette.GREEN), Vector2(0, 46), 480)

	var n: int = RunState.battles.size()
	var spacing := 80
	var x0 := 240 - (n - 1) * spacing / 2
	for i in n:
		var enemy: Dictionary = GameData.enemy(RunState.battles[i])
		var done := i < RunState.battle_index
		var current := i == RunState.battle_index
		var node := Panel.new()
		var border := Palette.RED if current else (Palette.GREEN if done else Palette.CREAM)
		node.add_theme_stylebox_override("panel", Palette.box(Palette.CREAM if not done else Palette.BLACK, border, 2 if current else 1))
		node.position = Vector2(x0 + i * spacing - 16, 90)
		node.size = Vector2(32, 44)
		add_child(node)
		var boss := bool(enemy.get("boss", false))
		var glyph := str(enemy.get("icon", "Q" if boss else SUIT_ICON.get(str(enemy.get("suit", "")), "?")))
		var icon := Palette.label(glyph, Palette.suit_color(str(enemy.get("suit", ""))), true)
		icon.position = Vector2(0, 12)
		icon.size = Vector2(32, 16)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.add_child(icon)
		var name_label := Palette.label("X" if done else str(enemy.get("name", "")).to_upper().replace(" SOLDIER", ""), Palette.GREEN if done else Palette.CREAM)
		_add(name_label, Vector2(x0 + i * spacing - 40, 140), 80)
		if i < n - 1:
			var line := ColorRect.new()
			line.color = Palette.GREEN
			line.position = Vector2(x0 + i * spacing + 18, 111)
			line.size = Vector2(spacing - 36, 2)
			add_child(line)

	var next: Dictionary = GameData.enemy(RunState.current_enemy_id())
	_add(Palette.label("NEXT: %s" % str(next.get("name", "")).to_upper(), Palette.CREAM), Vector2(0, 166), 480)
	_add(Palette.label(str(next.get("text", "")).to_upper(), Palette.GREEN), Vector2(0, 178), 480)
	_add(Palette.label("HP %d/%d   GOLD %d   DECK %d" % [RunState.hp, RunState.max_hp, RunState.gold, RunState.deck.size()], Palette.RED), Vector2(0, 204), 480)

	var fight := Button.new()
	fight.text = "FIGHT [ENTER]"
	fight.position = Vector2(190, 226)
	fight.size = Vector2(100, 18)
	fight.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.CREAM))
	fight.add_theme_stylebox_override("hover", Palette.box(Palette.BLACK, Palette.RED))
	fight.pressed.connect(_fight)
	add_child(fight)
	if Autoplay.enabled():
		Autoplay.after(self, 0.3, _fight)


func _add(label: Label, pos: Vector2, width: int) -> void:
	label.position = pos
	label.size = Vector2(width, 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_SPACE):
		_fight()


func _fight() -> void:
	if is_inside_tree():
		Transition.go(RunState.BATTLE_SCENE)
