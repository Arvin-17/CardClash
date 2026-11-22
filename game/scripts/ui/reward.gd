extends Control
## The shop after each win (and between acts): your whole deck is on show, the offered cards have gold
## prices, and you can buy and remove as many cards as you can afford before moving on.
## Prices, removal cost and the minimum deck size: rules.json "shop".

var _offer: Array[String] = []
var _sold: Array[bool] = []
var _offer_buttons: Array[Button] = []
var _price_labels: Array[Label] = []
var _gold_label: Label
var _deck_label: Label
var _deck_row: HFlowContainer
var _message: Label
## The card id waiting for a second click to confirm its removal.
var _pending_remove: String = ""
var _shop_rules: Dictionary = {}
var _done: bool = false


func _ready() -> void:
	_shop_rules = GameData.rule("shop", {})
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
	_center(Palette.label("THE SHOP", Palette.RED, true), 8)
	_gold_label = _center(Palette.label("", Palette.GOLD_HI), 26)

	_offer = Rewards.roll(GameData.cards, GameData.rule("run.rarity_weights", {}), int(GameData.rule("run.reward_choices", 3)), Rng.rng)
	for i in _offer.size():
		_sold.append(false)
		_build_offer(i)

	_deck_label = Palette.label("", Palette.CREAM)
	_deck_label.position = Vector2(12, 130)
	add_child(_deck_label)
	_deck_row = HFlowContainer.new()
	_deck_row.position = Vector2(12, 142)
	_deck_row.custom_minimum_size = Vector2(456, 0)
	_deck_row.size = Vector2(456, 0)
	_deck_row.add_theme_constant_override("h_separation", 2)
	_deck_row.add_theme_constant_override("v_separation", 2)
	add_child(_deck_row)

	_message = _center(Palette.label("", Palette.CREAM), 226)
	if not RunState.last_trinket.is_empty():
		var t: Dictionary = GameData.trinkets.get(RunState.last_trinket, {})
		_center(Palette.label("TRINKET FOUND: %s - %s" % [str(t.get("name", "")).to_upper(), str(t.get("text", "")).to_upper()], Palette.RED), 238)
	_button("DONE [ENTER]", Vector2(180, 250), _finish)
	_refresh()
	if Autoplay.enabled():
		Autoplay.after(self, 0.3, _autoplay_shop)


func _build_offer(i: int) -> void:
	var d: Dictionary = GameData.card(_offer[i])
	var b := Button.new()
	b.position = Vector2(44 + i * 136, 38)
	b.size = Vector2(120, 84)
	b.focus_mode = Control.FOCUS_NONE
	var rare := str(d.get("rarity", "")) == "rare"
	b.add_theme_stylebox_override("normal", Palette.box(Palette.CREAM, Palette.RED if rare else Palette.BLACK, 2 if rare else 1))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.CREAM, Palette.RED, 2))
	b.add_theme_stylebox_override("disabled", Palette.box(Palette.CREAM, Palette.BLACK))
	b.pressed.connect(_buy.bind(i))
	add_child(b)
	_in(b, "%d  %s" % [i + 1, str(d.get("name", "")).to_upper()], Palette.BLACK, Vector2(6, 5))
	_in(b, str(d.get("rarity", "")).to_upper(), Palette.RED if rare else Palette.GREEN, Vector2(6, 15))
	# Width and wrap mode go in before the text, so the label can't grow past the card.
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	text.custom_minimum_size = Vector2(108, 0)
	text.size = Vector2(108, 40)
	text.position = Vector2(6, 26)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_color_override("font_color", Palette.BLACK)
	text.text = str(d.get("text", "")).to_upper()
	b.add_child(text)
	_price_labels.append(_in(b, "", Palette.GREEN, Vector2(6, 70)))
	_offer_buttons.append(b)


func _refresh() -> void:
	_gold_label.text = "GOLD %d   HP %d/%d" % [RunState.gold, RunState.hp, RunState.max_hp]
	for i in _offer.size():
		var price := Shop.card_price(GameData.card(_offer[i]), _shop_rules)
		var l := _price_labels[i]
		if _sold[i]:
			l.text = "SOLD"
			l.add_theme_color_override("font_color", Palette.BLACK)
			_offer_buttons[i].disabled = true
			_offer_buttons[i].modulate = Color(1, 1, 1, 0.45)
		else:
			l.text = "BUY [%d]: %d GOLD" % [i + 1, price]
			l.add_theme_color_override("font_color", Palette.GREEN if price <= RunState.gold else Palette.RED)
	_deck_label.text = "YOUR DECK: %d CARDS.  CLICK A CARD TWICE TO REMOVE IT (%d GOLD)" % [RunState.deck.size(), Shop.remove_price(_shop_rules)]
	for child in _deck_row.get_children():
		child.queue_free()
	for g: Dictionary in Shop.grouped(RunState.deck):
		var id := str(g["id"])
		var count := int(g["count"])
		var chip := Button.new()
		chip.focus_mode = Control.FOCUS_NONE
		var card_name := str(GameData.card(id).get("name", id)).to_upper()
		if id == _pending_remove:
			chip.text = "REMOVE ONE %s?" % card_name
			chip.add_theme_stylebox_override("normal", Palette.box(Palette.RED_DARK, Palette.RED_HI))
		else:
			chip.text = card_name + (" X%d" % count if count > 1 else "")
			chip.add_theme_stylebox_override("normal", Palette.box(Palette.INK, Palette.CREAM))
		chip.add_theme_stylebox_override("hover", Palette.box(Palette.PLUM, Palette.GOLD_HI))
		chip.pressed.connect(_deck_click.bind(id))
		_deck_row.add_child(chip)


## Buy an offered card, if you can afford it. Each offer sells once.
func _buy(i: int) -> void:
	if _done or i < 0 or i >= _offer.size():
		return
	if _sold[i]:
		_say("ALREADY BOUGHT.")
		return
	var d: Dictionary = GameData.card(_offer[i])
	var price := Shop.card_price(d, _shop_rules)
	_pending_remove = ""
	if not RunState.buy_card(_offer[i], price):
		_say("NOT ENOUGH GOLD: %s COSTS %d." % [str(d.get("name", "")).to_upper(), price])
		_refresh()
		return
	_sold[i] = true
	RunState.save()
	_say("BOUGHT %s FOR %d GOLD." % [str(d.get("name", "")).to_upper(), price])
	_refresh()


## Remove a deck card: the first click asks, the second click on the same card pays and removes one copy.
func _deck_click(id: String) -> void:
	if _done:
		return
	var card_name := str(GameData.card(id).get("name", id)).to_upper()
	var price := Shop.remove_price(_shop_rules)
	if _pending_remove != id:
		_pending_remove = id
		_say("CLICK %s AGAIN TO REMOVE ONE FOR %d GOLD." % [card_name, price])
		_refresh()
		return
	_pending_remove = ""
	var index := -1
	for g: Dictionary in Shop.grouped(RunState.deck):
		if str(g["id"]) == id:
			index = int(g["index"])
	var min_deck := Shop.min_deck(_shop_rules)
	if RunState.deck.size() <= min_deck:
		_say("YOUR DECK CAN'T GO BELOW %d CARDS." % min_deck)
	elif price > RunState.gold:
		_say("NOT ENOUGH GOLD: REMOVING COSTS %d." % price)
	elif RunState.remove_card_for(index, price, min_deck):
		RunState.save()
		_say("REMOVED %s FOR %d GOLD." % [card_name, price])
	_refresh()


func _say(text: String) -> void:
	_message.text = text
	_message.modulate = Palette.RED_HI
	create_tween().tween_property(_message, "modulate", Color.WHITE, 0.6)


## The bot buys whatever it can afford, left to right, then leaves.
func _autoplay_shop() -> void:
	for i in _offer.size():
		_buy(i)
	Autoplay.after(self, 0.3, _finish)


func _center(l: Label, y: int) -> Label:
	l.position = Vector2(0, y)
	l.size = Vector2(480, 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	return l


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


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1, KEY_2, KEY_3:
			_buy(key.keycode - KEY_1)
		KEY_ENTER, KEY_KP_ENTER, KEY_K:
			_finish()
		KEY_ESCAPE:
			_pending_remove = ""
			_message.text = ""
			_refresh()


func _finish() -> void:
	if _done:
		return
	_done = true
	RunState.save()
	# The act's boss is down: fall down the rabbit hole into the next act.
	if RunState.act_complete() and not RunState.is_final_act():
		RunState.advance_act()
		Transition.rabbit_hole(RunState.MAP_SCENE, str(GameData.act(RunState.act_id).get("name", "")))
	else:
		Transition.go(RunState.MAP_SCENE)
