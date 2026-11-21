extends Control
## The battle table. Listens to Events and draws; sends player requests to the controller.
## It never changes game state itself.

@onready var controller: BattleController = get_parent().get_node("BattleController")

var _enemy_row: HBoxContainer
var _player_row: HBoxContainer
var _hand_row: HBoxContainer
var _enemy_total: Label
var _player_total: Label
var _enemy_name: Label
var _enemy_hp: Label
var _enemy_attack: Label
var _player_hp: Label
var _round: Label
var _message: Label
var _plays: Label
var _peek: Label
var _counts: Label
var _timer_bar: ColorRect
var _timer_label: Label
var _intent_bar: ColorRect
var _hit: Button
var _stay: Button
var _overlay: Panel
var _overlay_title: Label
var _overlay_button: Button
var _overlay_detail: Label
var _portrait: TextureRect
var _alert: Label
var _flash_rect: ColorRect
## An attack is about to land (telegraphed, never named).
var _warning: bool = false
var _blink_t: float = 0.0
var _flags: Label
var _debug: Label
var _chooser: PanelContainer

const TIMER_W := 200.0
const INTENT_W := 48.0


func _ready() -> void:
	_build()
	Events.round_started.connect(_on_round_started)
	Events.battle_phase_changed.connect(func(_phase: int) -> void: _refresh())
	Events.card_dealt.connect(func(_who: String, _card: Card) -> void: _refresh())
	Events.card_removed.connect(func(_who: String, _card: Card) -> void: _refresh())
	Events.total_changed.connect(func(_who: String, _total: int) -> void: _refresh())
	Events.hand_changed.connect(_refresh)
	Events.hp_changed.connect(_on_hp_changed)
	Events.timer_changed.connect(_on_timer_changed)
	Events.intent_changed.connect(_on_intent_changed)
	Events.peeked.connect(_on_peeked)
	Events.surprise_attack.connect(_on_surprise)
	Events.surprise_blocked.connect(_on_blocked)
	Events.attack_incoming.connect(_on_attack_incoming)
	Events.round_resolved.connect(_on_round_resolved)
	Events.boss_phase_changed.connect(func(_phase: int) -> void: _set_portrait(true))
	Events.battle_started.connect(func(_id: String) -> void: _set_portrait(false))
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
	felt.position = Vector2(8, 84)
	felt.size = Vector2(464, 98)
	add_child(felt)

	# Top bar: round, timer, blind deck.
	_round = _label(Vector2(6, 4), "ROUND 1", Palette.CREAM)
	var timer_bg := ColorRect.new()
	timer_bg.color = Palette.GREEN
	timer_bg.position = Vector2(140, 5)
	timer_bg.size = Vector2(TIMER_W, 4)
	add_child(timer_bg)
	_timer_bar = ColorRect.new()
	_timer_bar.color = Palette.CREAM
	_timer_bar.position = timer_bg.position
	_timer_bar.size = timer_bg.size
	add_child(_timer_bar)
	_timer_label = _label(Vector2(344, 4), "15", Palette.CREAM)
	_counts = _label(Vector2(370, 4), "", Palette.GREEN)

	# The enemy across the table (placeholder portrait until the designer's sprite lands).
	_portrait = TextureRect.new()
	_portrait.position = Vector2(216, 16)
	_portrait.size = Vector2(48, 56)
	add_child(_portrait)
	var intent_bg := ColorRect.new()
	intent_bg.color = Palette.GREEN
	intent_bg.position = Vector2(216, 75)
	intent_bg.size = Vector2(INTENT_W, 4)
	add_child(intent_bg)
	_intent_bar = ColorRect.new()
	_intent_bar.color = Palette.RED
	_intent_bar.position = intent_bg.position
	_intent_bar.size = Vector2(0, 4)
	add_child(_intent_bar)
	_alert = Palette.label("!", Palette.RED, true)
	_alert.position = Vector2(200, 30)
	_alert.visible = false
	add_child(_alert)
	_enemy_name = _label(Vector2(100, 22), "", Palette.CREAM)
	_enemy_hp = _label(Vector2(100, 32), "", Palette.RED)
	_enemy_attack = _label(Vector2(272, 22), "", Palette.GREEN)

	_enemy_row = _row(Vector2(170, 90))
	_enemy_total = _label(Vector2(372, 100), "", Palette.CREAM)
	_message = _label(Vector2(0, 127), "", Palette.CREAM)
	_message.size = Vector2(480, 8)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_row = _row(Vector2(170, 144))
	_player_total = _label(Vector2(372, 154), "", Palette.CREAM)
	_peek = _label(Vector2(16, 154), "", Palette.CREAM)

	# Alice's hand and actions.
	_hand_row = _row(Vector2(8, 190))
	_hand_row.add_theme_constant_override("separation", 4)
	_player_hp = _label(Vector2(8, 252), "", Palette.RED)
	_plays = _label(Vector2(120, 252), "", Palette.CREAM)
	_flags = _label(Vector2(120, 242), "", Palette.GREEN)
	_debug = _label(Vector2(6, 16), "", Palette.CREAM)
	_debug.visible = false
	_hit = _button(Vector2(330, 236), "HIT [H]", controller.hit)
	_stay = _button(Vector2(400, 236), "READY [SPC]", controller.stay)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(Palette.RED, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	_overlay = Panel.new()
	_overlay.add_theme_stylebox_override("panel", Palette.box(Palette.BLACK, Palette.CREAM))
	_overlay.position = Vector2(120, 86)
	_overlay.size = Vector2(240, 80)
	_overlay.visible = false
	add_child(_overlay)
	_overlay_title = Palette.label("", Palette.CREAM, true)
	_overlay_title.position = Vector2(0, 14)
	_overlay_title.size = Vector2(240, 16)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(_overlay_title)
	_overlay_detail = Palette.label("", Palette.CREAM)
	_overlay_detail.position = Vector2(0, 34)
	_overlay_detail.size = Vector2(240, 8)
	_overlay_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.add_child(_overlay_detail)
	_overlay_button = Button.new()
	_overlay_button.text = "CONTINUE [ENTER]"
	_overlay_button.position = Vector2(64, 50)
	_overlay_button.size = Vector2(112, 16)
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
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			if _chooser == null:
				_request_play(key.keycode - KEY_1)
		KEY_ESCAPE:
			_close_chooser()
		KEY_SPACE:
			if _overlay.visible:
				_on_continue()
			else:
				controller.stay()
		KEY_ENTER:
			if _overlay.visible:
				_on_continue()
		KEY_F1:
			if OS.is_debug_build():
				_debug.visible = not _debug.visible
				_refresh()
		KEY_F2:
			if OS.is_debug_build():
				controller.debug_win()
		KEY_F3:
			if OS.is_debug_build():
				print("CardClash seed: %d" % RunState.run_seed)
				_message.text = "SEED %d (PRINTED)" % RunState.run_seed


func _on_round_started(n: int) -> void:
	_round.text = "ROUND %d" % n
	_message.text = ""
	_peek.text = ""
	_refresh()


func _refresh() -> void:
	var b := controller.battle
	if b == null:
		return
	_fill(_enemy_row, b.enemy.table)
	_fill(_player_row, b.player.table)
	_enemy_name.text = b.enemy.display_name.to_upper()
	_enemy_attack.text = "ATK %d  STAYS %d" % [b.enemy.base_attack, b.enemy_stay_at]
	_enemy_total.text = "= %d" % b.enemy.total(b.target)
	var pt := b.player.total(b.target)
	_player_total.text = "= %d%s" % [pt, "  BUST" if pt > b.target else ""]
	_player_total.add_theme_color_override("font_color", Palette.RED if pt > b.target else Palette.CREAM)
	var deck_text := "DECK %d" % (b.player_deck.count() if b.player_deck else 0)
	_plays.text = deck_text if b.plays_per_round <= 0 else "CARDS %d/%d   %s" % [b.cards_played, b.plays_per_round, deck_text]
	_plays.add_theme_color_override("font_color", Palette.RED if b.at_play_limit() else Palette.CREAM)
	_counts.text = _count_text(b.hit_deck)
	var flags: Array[String] = []
	if b.shield > 0:
		flags.append("SHIELD %d" % b.shield)
	if b.hide_total:
		flags.append("SMOKE")
	if b.crit_boost:
		flags.append("VORPAL")
	for t: Dictionary in b.trinket_defs:
		flags.append(str(t.get("name", "")).to_upper())
	_flags.text = "  ".join(flags)
	if _debug.visible:
		_debug.text = "F1 DEBUG  YOU %d  FOE %d  AI: %s  INTENT %d%%\nBLIND %s" % [
			b.player.total(b.target), b.enemy.total(b.target), EnemyAI.preview(b),
			int(100.0 * (1.0 - controller.intent_timer.time_left / maxf(controller.intent_timer.wait_time, 0.01))),
			str(b.hit_deck.remaining_by_value())]
	var can_act := controller.can_act()
	_hit.disabled = not can_act
	_stay.disabled = not can_act
	for child in _hand_row.get_children():
		child.queue_free()
	for i in b.hand.size():
		var v := HandCardView.new()
		v.show_card(b.hand[i], i)
		v.pressed.connect(_request_play.bind(i))
		v.mouse_entered.connect(func() -> void: _message.text = v.tooltip_text)
		_hand_row.add_child(v)


## Card counting: how many 10-value and low cards are still unseen in the blind deck.
func _count_text(deck: HitDeck) -> String:
	var counts := deck.remaining_by_value()
	var low := 0
	for v in range(2, 7):
		low += int(counts.get(v, 0))
	return "BLIND %d  10S %d  LOW %d" % [deck.remaining(), int(counts.get(10, 0)), low]


func _fill(row: HBoxContainer, cards: Array[Card]) -> void:
	for child in row.get_children():
		child.queue_free()
	for c: Card in cards:
		var v := CardView.new()
		v.show_card(c)
		row.add_child(v)


func _set_portrait(enraged: bool) -> void:
	var b := controller.battle
	if b == null:
		return
	var base := "res://art/%s" % str(b.enemy_def.get("sprite", ""))
	var path := base + ("_rage.png" if enraged else ".png")
	if not ResourceLoader.exists(path):
		path = base + ".png"
	_portrait.texture = load(path) if ResourceLoader.exists(path) else null


## Cards that need a choice (Painted Rose's value, Mushroom's target and sign) open a chooser.
## A play that can't happen says why instead of silently doing nothing.
func _request_play(index: int) -> void:
	var b := controller.battle
	if b == null or index < 0 or index >= b.hand.size() or not controller.round_live():
		return
	if b.at_play_limit():
		_say("ONLY %d CARDS PER ROUND!" % b.plays_per_round)
		return
	if not b.can_play(index):
		_say("%s CAN'T BE PLAYED RIGHT NOW." % b.hand[index].display_name().to_upper())
		return
	var card: Card = b.hand[index]
	var params := b.params_for(card)
	if card.effect_name() == "wild":
		_open_chooser("PAINT IT:", _wild_options(index, params))
	elif card.effect_name() == "modify_value" and str(params.get("target", "")) == "choose":
		_open_chooser("MUSHROOM:", _mushroom_options(index, int(params.get("amount", 2))))
	else:
		controller.play(index)


func _wild_options(index: int, params: Dictionary) -> Array:
	var out: Array = []
	for v in range(int(params.get("min", 1)), int(params.get("max", 5)) + 1):
		out.append([str(v), {"value": v}, index])
	return out


func _mushroom_options(index: int, amount: int) -> Array:
	var b := controller.battle
	var out: Array = []
	for side: Array in [["player", "YOU", b.player], ["enemy", "FOE", b.enemy]]:
		var who: Combatant = side[2]
		for i in who.table.size():
			for dir in [1, -1]:
				out.append(["%s %s%s%d" % [side[1], who.table[i].face(), "+" if dir > 0 else "-", amount],
					{"owner": side[0], "index": i, "dir": dir}, index])
	return out


func _open_chooser(title: String, options: Array) -> void:
	_close_chooser()
	_chooser = PanelContainer.new()
	_chooser.add_theme_stylebox_override("panel", Palette.box(Palette.BLACK, Palette.RED))
	_chooser.position = Vector2(8, 100)
	_chooser.custom_minimum_size = Vector2(464, 0)
	var flow := HFlowContainer.new()
	_chooser.add_child(flow)
	flow.add_child(Palette.label(title, Palette.RED))
	for opt: Array in options:
		var b := Button.new()
		b.text = opt[0]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Palette.box(Palette.BLACK, Palette.CREAM))
		b.add_theme_stylebox_override("hover", Palette.box(Palette.RED, Palette.CREAM))
		b.pressed.connect(_choose.bind(opt[2], opt[1]))
		flow.add_child(b)
	var cancel := Button.new()
	cancel.text = "CANCEL [ESC]"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(_close_chooser)
	flow.add_child(cancel)
	add_child(_chooser)


func _choose(index: int, choice: Dictionary) -> void:
	_close_chooser()
	controller.play(index, choice)


func _close_chooser() -> void:
	if _chooser:
		_chooser.queue_free()
		_chooser = null


func _on_hp_changed(who: String, hp: int, max_hp: int) -> void:
	if who == "player":
		_player_hp.text = "ALICE HP %d/%d" % [hp, max_hp]
	else:
		_enemy_hp.text = "HP %d/%d" % [hp, max_hp]


func _on_timer_changed(seconds_left: float) -> void:
	var total := float(GameData.rule("round.seconds", 15))
	_timer_bar.size.x = roundf(TIMER_W * clampf(seconds_left / total, 0.0, 1.0))
	_timer_label.text = str(ceili(seconds_left))


func _on_intent_changed(_enemy_id: String, percent: float) -> void:
	_intent_bar.size.x = roundf(INTENT_W * percent)


func _on_peeked(card: Card) -> void:
	if card:
		_peek.text = "NEXT: %s%s" % [card.face(), Palette.SUIT_GLYPH.get(card.suit, "")]


func _on_attack_incoming(_enemy_id: String) -> void:
	_warning = true
	_blink_t = 0.0


## The attack lands: shake, flash red, and say what it did, never what it's called.
func _on_surprise(_enemy_id: String, _kind: String) -> void:
	_clear_warning()
	var what := _message.text
	_message.text = "THE ENEMY STRIKES!" + (" " + what if not what.is_empty() else "")
	_flash("")
	_shake()


func _on_blocked(_enemy_id: String, _kind: String) -> void:
	_clear_warning()
	_message.text = "ATTACK BLOCKED!"
	_flash("")


func _clear_warning() -> void:
	_warning = false
	_alert.visible = false
	_portrait.modulate = Color.WHITE
	_intent_bar.color = Palette.RED


func _shake() -> void:
	_flash_rect.color = Color(Palette.RED, 0.35)
	var fade := create_tween()
	fade.tween_property(_flash_rect, "color:a", 0.0, 0.35)
	var shake := create_tween()
	for offset: Vector2 in [Vector2(3, 0), Vector2(-3, 1), Vector2(2, -1), Vector2(-1, 0), Vector2.ZERO]:
		shake.tween_property(self, "position", offset, 0.04)


## While an attack is incoming: the enemy blinks red, a big "!" flashes and the bar pulses.
func _process(delta: float) -> void:
	if not _warning:
		return
	_blink_t += delta
	var on := int(_blink_t / 0.15) % 2 == 0
	_alert.visible = on
	_portrait.modulate = Color(1.0, 0.45, 0.45) if on else Color.WHITE
	_intent_bar.color = Palette.CREAM if on else Palette.RED


func _say(text: String) -> void:
	_message.text = text
	_flash("")


func _flash(text: String) -> void:
	if _message.text.is_empty():
		_message.text = text
	var tween := create_tween()
	_message.modulate = Palette.RED
	tween.tween_property(_message, "modulate", Color.WHITE, 0.6)


func _on_round_resolved(r: Dictionary) -> void:
	_close_chooser()
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
	_clear_warning()
	_overlay_title.text = "VICTORY!" if won else "OFF WITH HER HEAD!"
	_overlay_title.add_theme_color_override("font_color", Palette.CREAM if won else Palette.RED)
	_overlay_detail.text = "GOLD %d   HP %d/%d" % [RunState.gold, RunState.hp, RunState.max_hp] if won else ""
	_overlay.visible = true
	if Autoplay.enabled():
		Autoplay.after(self, 0.5, _on_continue)


func _on_continue() -> void:
	if _overlay.visible:
		_overlay.visible = false
		get_tree().change_scene_to_file(RunState.scene_after_battle())
