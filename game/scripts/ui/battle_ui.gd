extends Control
## The battle table. Listens to Events and draws; sends player requests to the controller.
## It never changes game state itself.
##
## Layers, back to front: the act's animated room, a red tint when the boss is enraged, the
## enemy sprite (behind the table edge the room draws), cards and Alice's hand on the felt,
## mood vignettes, the HUD (pocket watch, HP bars, intent bar, totals), then effects.
## Art comes from game/art/anim (exported by tools/sprites); anything missing falls back
## to plain shapes so the game always runs.

@onready var controller: BattleController = get_parent().get_node("BattleController")

var _enemy_row: Control
var _player_row: Control
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
var _watch: WatchTimer
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

var _room: AnimatedSprite2D
var _rage_tint: ColorRect
var _enemy: AnimatedSprite2D
var _enemy_flash: ShaderMaterial
var _alice: AnimatedSprite2D
var _fx: BattleFx
var _tension: TextureRect
var _rage_edge: TextureRect
var _player_hp_fill: ColorRect
var _enemy_hp_fill: ColorRect
var _deck_pile: Control
var _row_counts := {"player": 0, "enemy": 0}
var _enraged: bool = false
var _busted_shown: bool = false
var _blackjack_shown: bool = false
var _tension_on: bool = false
var _pulse_t: float = 0.0

const INTENT_W := 118.0
const HP_W := 90.0
const ENEMY_HP_W := 138.0
const ENEMY_POS := Vector2(112, 0)
const DECK_POS := Vector2(340, 200)
const CARD_STEP := 27.0
const TENSION_AT := 18


func _ready() -> void:
	_build()
	Events.round_started.connect(_on_round_started)
	Events.battle_phase_changed.connect(func(_phase: int) -> void: _refresh())
	Events.card_dealt.connect(_on_card_dealt)
	Events.card_removed.connect(func(_who: String, _card: Card) -> void: _refresh())
	Events.card_played.connect(_on_card_played)
	Events.total_changed.connect(_on_total_changed)
	Events.hand_changed.connect(_refresh)
	Events.hp_changed.connect(_on_hp_changed)
	Events.timer_changed.connect(_on_timer_changed)
	Events.intent_changed.connect(_on_intent_changed)
	Events.peeked.connect(_on_peeked)
	Events.surprise_attack.connect(_on_surprise)
	Events.surprise_blocked.connect(_on_blocked)
	Events.attack_incoming.connect(_on_attack_incoming)
	Events.round_resolved.connect(_on_round_resolved)
	Events.boss_phase_changed.connect(func(_phase: int) -> void: _set_enraged(true))
	Events.battle_started.connect(func(_id: String) -> void: _set_enemy())
	Events.message.connect(func(text: String) -> void: _message.text = text)
	Events.battle_won.connect(func(_id: String) -> void: _show_end(true))
	Events.battle_lost.connect(func(_id: String) -> void: _show_end(false))


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# The act's room (its table edge sits at y = 168).
	var room_key := AnimLib.room_key(RunState.act_id)
	if not room_key.is_empty():
		_room = AnimLib.sprite({"loop": room_key})
		add_child(_room)
	else:
		var felt := Panel.new()
		felt.add_theme_stylebox_override("panel", Palette.box(Palette.GREEN, Palette.CREAM))
		felt.position = Vector2(0, 168)
		felt.size = Vector2(480, 102)
		add_child(felt)
	_rage_tint = ColorRect.new()
	_rage_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rage_tint.color = Color(Palette.RED_DARK, 0.0)
	_rage_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rage_tint)

	# The enemy across the table: an animated sprite drawn at 2x, or a still as a fallback.
	_portrait = TextureRect.new()
	_portrait.position = ENEMY_POS
	_portrait.size = Vector2(256, 224)
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_enemy = AnimatedSprite2D.new()
	_enemy.centered = false
	_enemy.position = ENEMY_POS
	_enemy.scale = Vector2(2, 2)
	_enemy_flash = ShaderMaterial.new()
	_enemy_flash.shader = load("res://art/shaders/flash.gdshader")
	_enemy.material = _enemy_flash
	_enemy.animation_finished.connect(_on_enemy_anim_finished)
	add_child(_enemy)

	# Mood, behind the table UI so cards stay readable: dark pulsing edges when you're close
	# to busting, red edges when the boss rages.
	_tension = _overlay_texture("res://art/anim/vignette_tension.png")
	_rage_edge = _overlay_texture("res://art/anim/vignette_rage.png")

	# On the felt: totals plaque, enemy cards (right), your cards (centre), the deck.
	var plaque := Panel.new()
	plaque.add_theme_stylebox_override("panel", Palette.box(Color(Palette.INK, 0.85), Palette.GOLD_DARK))
	plaque.position = Vector2(150, 176)
	plaque.size = Vector2(180, 20)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plaque)
	_player_total = Palette.label("", Palette.CREAM, true)
	_player_total.position = Vector2(6, 1)
	_player_total.size = Vector2(84, 18)
	plaque.add_child(_player_total)
	_enemy_total = Palette.label("", Palette.CREAM, true)
	_enemy_total.position = Vector2(90, 1)
	_enemy_total.size = Vector2(84, 18)
	_enemy_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	plaque.add_child(_enemy_total)
	_enemy_row = _free_row(Vector2(372, 179))
	_player_row = _free_row(Vector2(150, 200))
	_deck_pile = Control.new()
	_deck_pile.position = DECK_POS
	_deck_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_pile)
	for i in 3:
		var back := TextureRect.new()
		back.texture = AnimLib.card_texture("", "", true)
		back.position = Vector2(2 * (2 - i), -(2 - i))
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_deck_pile.add_child(back)

	# Alice's hand, bottom-left; her built-deck cards beside it.
	if AnimLib.has("alice_idle"):
		_alice = AnimLib.sprite({"idle": "alice_idle", "hit": "alice_hit", "stay": "alice_stay", "pump": "alice_pump"})
		_alice.position = Vector2(0, 190)
		_alice.animation_finished.connect(func() -> void: _alice.play("idle"))
		add_child(_alice)
	_hand_row = HBoxContainer.new()
	_hand_row.position = Vector2(126, 235)
	_hand_row.add_theme_constant_override("separation", 1)
	add_child(_hand_row)
	_hit = _button(Vector2(340, 240), "HIT [H]", controller.hit)
	_stay = _button(Vector2(408, 240), "READY [SPC]", controller.stay)

	# HUD, top-left: pocket-watch timer, round, Alice's HP; then flags, plays, peek.
	_watch = WatchTimer.new()
	_watch.position = Vector2(6, 2)
	add_child(_watch)
	_round = _label(Vector2(54, 6), "ROUND 1", Palette.CREAM)
	_player_hp = _label(Vector2(10, 60), "", Palette.CREAM)
	_player_hp_fill = _bar(Vector2(10, 70), HP_W, Palette.HP_GREEN)
	_flags = _label(Vector2(10, 82), "", Palette.TEAL)
	_plays = _label(Vector2(10, 92), "", Palette.CREAM)
	_peek = _label(Vector2(10, 102), "", Palette.GOLD_HI)

	# HUD, top-right: enemy name, HP, attack, card counting. Intent bar top-centre.
	_enemy_name = _label(Vector2(332, 4), "", Palette.CREAM)
	_enemy_name.size = Vector2(ENEMY_HP_W + 2, 8)
	_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_hp_fill = _bar(Vector2(332, 14), ENEMY_HP_W, Palette.RED)
	_enemy_hp = _label(Vector2(332, 24), "", Palette.CREAM)
	_enemy_attack = _label(Vector2(332, 34), "", Palette.LAVENDER)
	_counts = _label(Vector2(332, 44), "", Palette.LAVENDER)
	var intent_bg := ColorRect.new()
	intent_bg.color = Palette.INK
	intent_bg.position = Vector2(180, 3)
	intent_bg.size = Vector2(INTENT_W + 2, 7)
	add_child(intent_bg)
	_intent_bar = ColorRect.new()
	_intent_bar.color = Palette.GOLD_HI
	_intent_bar.position = Vector2(181, 4)
	_intent_bar.size = Vector2(0, 5)
	add_child(_intent_bar)
	_alert = Palette.shadow_label("!", Palette.RED_HI, true)
	_alert.position = Vector2(304, 0)
	_alert.visible = false
	add_child(_alert)

	_message = _label(Vector2(0, 156), "", Palette.CREAM)
	_message.size = Vector2(480, 10)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_stylebox_override("normal", Palette.box(Color(Palette.INK, 0.65), Color(Palette.INK, 0.0), 0))
	_debug = _label(Vector2(6, 116), "", Palette.CREAM)
	_debug.visible = false

	_fx = BattleFx.new()
	add_child(_fx)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(Palette.RED, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_rect)

	_overlay = Panel.new()
	_overlay.add_theme_stylebox_override("panel", Palette.box(Color(Palette.INK, 0.92), Palette.GOLD))
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
	var l := Palette.shadow_label(text, color)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _free_row(pos: Vector2) -> Control:
	var row := Control.new()
	row.position = pos
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	return row


func _bar(pos: Vector2, width: float, color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.color = Palette.INK
	back.position = pos
	back.size = Vector2(width + 2, 7)
	add_child(back)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = pos + Vector2(1, 1)
	fill.size = Vector2(width, 5)
	add_child(fill)
	return fill


func _overlay_texture(path: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path) if ResourceLoader.exists(path) else null
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate.a = 0.0
	add_child(r)
	return r


func _button(pos: Vector2, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(64, 18)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Palette.box(Palette.INK, Palette.CREAM))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.PLUM, Palette.GOLD_HI))
	b.add_theme_stylebox_override("pressed", Palette.box(Palette.RED, Palette.CREAM))
	b.add_theme_stylebox_override("disabled", Palette.box(Palette.INK, Palette.GREEN))
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
	_busted_shown = false
	_blackjack_shown = false
	_row_counts = {"player": 0, "enemy": 0}
	if _alice:
		_alice.play("idle")
	_refresh()
	var b := controller.battle
	if b and b.player.total(b.target) == b.target:
		_blackjack_shown = true
		_fx.banner("21!", Palette.GOLD_HI, 96.0, 3.0)
		_fx.sparkles(Vector2(240, 186), [Palette.GOLD_HI, Color.WHITE], 18, 60.0)
		if _alice:
			_alice.play("pump")


func _refresh() -> void:
	var b := controller.battle
	if b == null:
		return
	_fill(_enemy_row, b.enemy.table, "enemy")
	_fill(_player_row, b.player.table, "player")
	_enemy_name.text = b.enemy.display_name.to_upper()
	_enemy_attack.text = "ATK %d  STAYS %d" % [b.enemy.base_attack, b.enemy_stay_at]
	var et := b.enemy.total(b.target)
	_enemy_total.text = "HER %d" % et
	_enemy_total.add_theme_color_override("font_color", Palette.RED_HI if et > b.target else Palette.CREAM)
	var pt := b.player.total(b.target)
	_player_total.text = "YOU %d" % pt
	var pt_color := Palette.CREAM
	if pt > b.target:
		pt_color = Palette.RED_HI
	elif pt == b.target:
		pt_color = Palette.GOLD_HI
	_player_total.add_theme_color_override("font_color", pt_color)
	var deck_text := "DECK %d" % (b.player_deck.count() if b.player_deck else 0)
	_plays.text = deck_text if b.plays_per_round <= 0 else "CARDS %d/%d  %s" % [b.cards_played, b.plays_per_round, deck_text]
	_plays.add_theme_color_override("font_color", Palette.RED_HI if b.at_play_limit() else Palette.CREAM)
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
	_set_tension(pt >= TENSION_AT and pt <= b.target and not b.player.stayed)


## Card counting: how many 10-value and low cards are still unseen in the blind deck.
func _count_text(deck: HitDeck) -> String:
	var counts := deck.remaining_by_value()
	var low := 0
	for v in range(2, 7):
		low += int(counts.get(v, 0))
	return "BLIND %d  10S %d  LOW %d" % [deck.remaining(), int(counts.get(10, 0)), low]


## Lays a row of table cards out by hand; cards new since the last refresh slide in from the deck.
func _fill(row: Control, cards: Array[Card], who: String) -> void:
	for child in row.get_children():
		child.queue_free()
	var before: int = _row_counts.get(who, 0)
	for i in cards.size():
		var v := CardView.new()
		v.show_card(cards[i])
		var dest := Vector2(i * CARD_STEP, 0)
		row.add_child(v)
		if i >= before and is_inside_tree():
			v.position = DECK_POS - row.position
			var t := v.create_tween()
			t.tween_property(v, "position", dest, 0.18).set_delay(0.06 * (i - before)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		else:
			v.position = dest
	_row_counts[who] = cards.size()


# --- the enemy sprite ---------------------------------------------------------

func _set_enemy() -> void:
	var b := controller.battle
	if b == null:
		return
	var id := b.enemy_id()
	var anims := {"idle": id + "_idle", "tell": id + "_tell", "rage": id + "_rage", "laugh": id + "_laugh"}
	for key: String in AnimLib.manifest():
		if key.begins_with(id + "_attack_"):
			anims["attack_" + key.trim_prefix(id + "_attack_")] = key
	_enemy.sprite_frames = AnimLib.frames(anims)
	_enemy.scale = Vector2(2, 2)
	_enemy.position = ENEMY_POS
	_enemy.modulate = Color.WHITE
	var has_art := _enemy.sprite_frames.has_animation("idle")
	_enemy.visible = has_art
	_portrait.visible = not has_art
	if has_art:
		_enemy.play("idle")
	else:
		var path := "res://art/%s.png" % str(b.enemy_def.get("sprite", ""))
		_portrait.texture = load(path) if ResourceLoader.exists(path) else null
	_set_enraged(b.phase >= 2)


func _enemy_play(anim: String) -> bool:
	if _enemy.visible and _enemy.sprite_frames and _enemy.sprite_frames.has_animation(anim):
		_enemy.play(anim)
		return true
	return false


func _enemy_rest() -> void:
	if not _enemy_play("rage" if _enraged else "idle"):
		_enemy_play("idle")


func _on_enemy_anim_finished() -> void:
	# Tell holds its last frame until the attack lands; everything else returns to rest.
	if String(_enemy.animation) != "tell":
		_enemy_rest()


func _hurt_flash(color: Color = Color.WHITE) -> void:
	_enemy_flash.set_shader_parameter("flash_color", color)
	_enemy_flash.set_shader_parameter("amount", 1.0)
	var t := create_tween()
	t.tween_property(_enemy_flash, "shader_parameter/amount", 0.0, 0.25)
	var k := create_tween()
	for dx: float in [5.0, -4.0, 3.0, -1.0, 0.0]:
		k.tween_property(_enemy, "position:x", ENEMY_POS.x + dx, 0.04)


func _set_enraged(on: bool) -> void:
	var was := _enraged
	_enraged = on
	_rage_tint.color.a = 0.15 if on else 0.0
	_rage_edge.modulate.a = 0.65 if on else 0.0
	_fx.embers(on)
	if on and String(_enemy.animation) in ["idle", ""]:
		_enemy_rest()
	if on and not was:
		_fx.banner("ENRAGED!", Palette.RED_HI, 96.0, 2.0)
		_fx.screen_flash(Palette.RED, 0.4, 0.4)


func _set_tension(on: bool) -> void:
	_tension_on = on


# --- events -------------------------------------------------------------------

func _on_card_dealt(who: String, _card: Card) -> void:
	if who == "player" and _alice and controller.state == BattleController.State.ROUND_ACTIVE:
		_alice.play("hit")
	_refresh()


func _on_total_changed(who: String, total: int) -> void:
	_refresh()
	var b := controller.battle
	if b == null or controller.state == BattleController.State.DEAL:
		return
	if who == "player":
		if total > b.target and not _busted_shown:
			_busted_shown = true
			_fx.banner("BUST!", Palette.RED_HI, 96.0, 3.0)
			_fx.screen_flash(Palette.RED, 0.35, 0.4)
			_shake()
			_enemy_play("laugh")
		elif total == b.target and not _blackjack_shown:
			_blackjack_shown = true
			_fx.banner("21!", Palette.GOLD_HI, 96.0, 3.0)
			_fx.sparkles(Vector2(240, 186), [Palette.GOLD_HI, Color.WHITE], 18, 60.0)
			if _alice:
				_alice.play("pump")
	elif total > b.target:
		_fx.pop("SHE BUSTS!", Vector2(208, 120), Palette.GOLD_HI)


## Special cards: the shared zoom-and-flip cutscene, then a touch that fits the effect.
func _on_card_played(card: Card) -> void:
	var b := controller.battle
	var from := Vector2(146 + 41 * 2, 250)
	var target := _player_row.position + Vector2(maxf(0, b.player.table.size() - 1) * CARD_STEP + 13, 18) if b else Vector2(240, 210)
	if card.is_number():
		_fx.sparkles(target, [Palette.CREAM, Palette.GOLD_HI], 8, 14.0)
		return
	_fx.card_cutscene(card.id, from, target)
	var params: Dictionary = card.def.get("params", {})
	match card.effect_name():
		"freeze_timer":
			_fx.sepia(float(params.get("seconds", 5)))
			_watch.frozen = true
			get_tree().create_timer(float(params.get("seconds", 5))).timeout.connect(func() -> void: _watch.frozen = false)
		"crit_boost":
			_fx.slash()
			_fx.pop("CRITICAL READY", Vector2(194, 130), Palette.GOLD_HI)
		"copy_enemy":
			_fx.sparkles(Vector2(240, 112), [Palette.TEAL, Color.WHITE], 20, 70.0)
		"shield":
			_fx.pop("SHIELD UP", Vector2(206, 130), Palette.TEAL)
		"heal":
			_fx.pop("+%d HP" % int(params.get("amount", 6)), Vector2(20, 56), Palette.HP_GREEN)
		"hide_total":
			_fx.sparkles(Vector2(240, 186), [Palette.LAVENDER, Palette.CREAM], 16, 50.0)


func _set_portrait(enraged: bool) -> void:
	_set_enraged(enraged)


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
	_chooser.add_theme_stylebox_override("panel", Palette.box(Palette.INK, Palette.RED))
	_chooser.position = Vector2(8, 120)
	_chooser.custom_minimum_size = Vector2(464, 0)
	var flow := HFlowContainer.new()
	_chooser.add_child(flow)
	flow.add_child(Palette.label(title, Palette.RED))
	for opt: Array in options:
		var b := Button.new()
		b.text = opt[0]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Palette.box(Palette.INK, Palette.CREAM))
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
	var ratio := clampf(float(hp) / maxf(float(max_hp), 1.0), 0.0, 1.0)
	if who == "player":
		_player_hp.text = "ALICE %d/%d" % [hp, max_hp]
		create_tween().tween_property(_player_hp_fill, "size:x", roundf(HP_W * ratio), 0.3)
		_player_hp_fill.color = Palette.RED_HI if ratio < 0.3 else Palette.HP_GREEN
	else:
		_enemy_hp.text = "HP %d/%d" % [hp, max_hp]
		create_tween().tween_property(_enemy_hp_fill, "size:x", roundf(ENEMY_HP_W * ratio), 0.3)


func _on_timer_changed(seconds_left: float) -> void:
	_watch.set_time(seconds_left, float(GameData.rule("round.seconds", 15)))


func _on_intent_changed(_enemy_id: String, percent: float) -> void:
	_intent_bar.size.x = roundf(INTENT_W * percent)


func _on_peeked(card: Card) -> void:
	if card:
		_peek.text = "NEXT: %s%s" % [card.face(), Palette.SUIT_GLYPH.get(card.suit, "")]
		_fx.sparkles(DECK_POS + Vector2(13, 0), [Palette.CREAM, Palette.LAVENDER], 10, 16.0)


func _on_attack_incoming(_enemy_id: String) -> void:
	_warning = true
	_blink_t = 0.0
	_enemy_play("tell")


## The attack lands: the enemy's attack animation, a shake, a red flash, and what it did,
## never what it's called.
func _on_surprise(_enemy_id: String, kind: String) -> void:
	_clear_warning()
	if not _enemy_play("attack_" + kind):
		_enemy_rest()
	var what := _message.text
	_message.text = "THE ENEMY STRIKES!" + (" " + what if not what.is_empty() else "")
	var word: String = {"bonk": "+2!", "dig": "BURIED!", "pilfer": "STOLEN!", "off_with_it": "OFF WITH IT!", "off_with_its_head": "OFF WITH ITS HEAD!"}.get(kind, "")
	if not word.is_empty():
		_fx.pop(word, Vector2(240 - word.length() * 3, 186), Palette.GOLD_HI, true)
	_flash("")
	_shake()


func _on_blocked(_enemy_id: String, _kind: String) -> void:
	_clear_warning()
	_enemy_rest()
	_message.text = "ATTACK BLOCKED!"
	_fx.pop("BLOCKED!", Vector2(214, 140), Palette.TEAL, true)
	_fx.sparkles(Vector2(240, 160), [Palette.TEAL, Color.WHITE], 16, 40.0)
	_flash("")


func _clear_warning() -> void:
	_warning = false
	_alert.visible = false
	_portrait.modulate = Color.WHITE
	_enemy_flash.set_shader_parameter("amount", 0.0)
	_intent_bar.color = Palette.GOLD_HI


func _shake() -> void:
	_flash_rect.color = Color(Palette.RED, 0.35)
	var fade := create_tween()
	fade.tween_property(_flash_rect, "color:a", 0.0, 0.35)
	var shake := create_tween()
	for offset: Vector2 in [Vector2(3, 0), Vector2(-3, 1), Vector2(2, -1), Vector2(-1, 0), Vector2.ZERO]:
		shake.tween_property(self, "position", offset, 0.04)


## While an attack is incoming the enemy blinks red, a big "!" flashes and the bar pulses.
## Close to busting, the edges of the screen darken with a heartbeat.
func _process(delta: float) -> void:
	_pulse_t += delta
	var beat := 0.25 if fmod(_pulse_t, 1.1) < 0.12 else 0.0
	var tension_target := (0.7 + beat) if _tension_on else 0.0
	_tension.modulate.a = move_toward(_tension.modulate.a, tension_target, delta * 4.0)
	if not _warning:
		return
	_blink_t += delta
	var on := int(_blink_t / 0.15) % 2 == 0
	_alert.visible = on
	_portrait.modulate = Color(1.0, 0.45, 0.45) if on else Color.WHITE
	_enemy_flash.set_shader_parameter("flash_color", Palette.RED_HI)
	_enemy_flash.set_shader_parameter("amount", 0.35 if on else 0.0)
	_intent_bar.color = Palette.RED_HI if on else Palette.GOLD_HI


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
	_set_tension(false)
	var text := ""
	var damage := int(r.get("damage", 0))
	match str(r["kind"]):
		"both_bust":
			text = "Both bust! Messy round: -%d each." % int(r["messy_damage"])
			_fx.banner("MESSY!", Palette.LAVENDER, 96.0, 2.0)
			_hurt_flash()
		"tie":
			text = "Tie. No damage."
			_fx.banner("TIE", Palette.CREAM, 96.0, 2.0)
		_:
			var won: bool = r["winner"] == "player"
			text = "%s: %d damage%s" % ["You win" if won else "Enemy wins", damage, " CRITICAL!" if r["critical"] else ""]
			if won:
				if r["critical"]:
					_fx.slash()
					_fx.banner("CRITICAL!", Palette.GOLD_HI, 120.0, 2.0)
				_hurt_flash()
				_fx.pop("-%d" % damage, Vector2(232, 70), Palette.RED_HI, true)
			else:
				_fx.pop("-%d" % damage, Vector2(40, 52), Palette.RED_HI, true)
				_fx.screen_flash(Palette.RED, 0.3, 0.3)
				if not _enemy_play("laugh"):
					_enemy_rest()
	_message.text = text
	_hit.disabled = true
	_stay.disabled = true


func _show_end(won: bool) -> void:
	_clear_warning()
	_set_tension(false)
	var delay := 0.0
	if won:
		delay = 1.2
		_defeat_enemy()
	elif not _enemy_play("laugh"):
		_enemy_rest()
	_overlay_title.text = "VICTORY!" if won else "OFF WITH HER HEAD!"
	_overlay_title.add_theme_color_override("font_color", Palette.GOLD_HI if won else Palette.RED_HI)
	_overlay_detail.text = "GOLD %d   HP %d/%d" % [RunState.gold, RunState.hp, RunState.max_hp] if won else ""
	if delay > 0.0 and is_inside_tree() and not Autoplay.enabled():
		await get_tree().create_timer(delay).timeout
	_overlay.visible = true
	if Autoplay.enabled():
		Autoplay.after(self, 0.5, _on_continue)


## Card soldiers fold flat and burst into cards; the Queen flashes and fades (the ending
## scene does the rest).
func _defeat_enemy() -> void:
	var b := controller.battle
	_hurt_flash()
	if b and bool(b.enemy_def.get("boss", false)):
		create_tween().tween_property(_enemy, "modulate:a", 0.0, 0.8).set_delay(0.3)
		_fx.screen_flash(Color.WHITE, 0.6, 0.5)
		return
	_fx.card_burst(Vector2(227, 120))
	_fx.pop("FOLDED!", Vector2(218, 40), Palette.GOLD_HI, true)
	var t := create_tween().set_parallel()
	t.tween_property(_enemy, "scale:y", 0.0, 0.35).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_enemy, "position:y", ENEMY_POS.y + 168.0, 0.35).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _on_continue() -> void:
	if _overlay.visible:
		_overlay.visible = false
		Transition.go(RunState.scene_after_battle())
