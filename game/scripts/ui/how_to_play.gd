extends Control
## How to Play: the rules, one page at a time, each with real screenshots of the game
## (art/howto, taken by tools/howto/capture.gd) or a live demo built from the game's own
## sprites and card widgets. Opens on first launch and from the menu's HOW TO PLAY button.
## Left/Right (or the buttons) turn pages; Esc closes; Enter on the last page closes.

const ROOM := "room_act1_tea"
const TEXT_W := 168.0

var _page: int = 0
var _pages: Array[Dictionary] = []
var _content: Control
var _title: Label
var _counter: Label
var _back: Button
var _next: Button
var _demo_t: float = 0.0
## Live demo parts for the enemy-attack page (null on other pages).
var _demo_enemy: AnimatedSprite2D
var _demo_bar: ColorRect
var _demo_alert: Label
var _demo_pop: Label
var _demo_phase: String = ""


func _ready() -> void:
	RunState.mark_how_to_play_seen()
	_pages = _build_pages()
	var bg := ColorRect.new()
	bg.color = Palette.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if AnimLib.has(ROOM):
		var room := AnimLib.sprite({"loop": ROOM})
		room.modulate = Color(0.28, 0.26, 0.34)
		add_child(room)
	_title = Palette.shadow_label("", Palette.RED_HI, true)
	_title.position = Vector2(0, 6)
	_title.size = Vector2(480, 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_counter = Palette.label("", Palette.LAVENDER)
	_counter.position = Vector2(420, 10)
	add_child(_counter)
	_content = Control.new()
	add_child(_content)
	_back = _button("< BACK", Vector2(12, 248), _turn.bind(-1))
	_button("CLOSE [ESC]", Vector2(190, 248), _close)
	_next = _button("NEXT >", Vector2(368, 248), _turn.bind(1))
	_show(0)


## Each page: a title, its text, and either a screenshot ("photo") or a live demo ("demo").
func _build_pages() -> Array[Dictionary]:
	var heal := int(GameData.rule("player.heal_action", 3))
	var plays := int(GameData.rule("round.plays_per_round", 2))
	var seconds := int(GameData.rule("round.seconds", 10))
	var super_at := int(GameData.rule("damage.super_bust_at", 30))
	return [
		{"title": "THE GOAL", "photo": "table", "text": "GET CLOSER TO 21 THAN THE ENEMY WITHOUT GOING OVER.\n\nEACH ROUND YOU BOTH GET 2 CARDS. WHOEVER IS CLOSER WINS THE ROUND: THE LOSER TAKES THE DIFFERENCE PLUS THE WINNER'S ATTACK.\n\nEXACTLY 21 IS A CRITICAL: DOUBLE DAMAGE.\n\nKNOCK THE ENEMY'S HP TO 0 TO WIN THE FIGHT."},
		{"title": "HIT OR STAND", "photo": "buttons", "below": true, "text": "YOU HAVE %d SECONDS A ROUND.\n\nHIT [H]: DRAW A CARD.\n\nSTAND [SPACE]: THE ROUND ENDS RIGHT AWAY. THE ENEMY'S CARDS FREEZE WHERE THEY ARE, SO STANDING FAST CAN CATCH IT SHORT.\n\nRUN OUT OF TIME AND YOU STAND ON WHATEVER YOU HAVE." % seconds},
		{"title": "HAND CARDS AND HEAL", "demo": "cards", "text": "YOUR OWN DECK DEALS YOU UP TO 3 HAND CARDS. PLAY UP TO %d A ROUND WITH 1-5 OR A CLICK.\n\nNUMBERS ADD TO YOUR TOTAL. DRINK ME SHRINKS YOUR LAST CARD BY 3, EAT ME GROWS IT BY 3, TEACUP PEEKS AT THE NEXT CARD.\n\nHEAL [E]: +%d HP. IT USES ONE OF YOUR %d PLAYS." % [plays, heal, plays]},
		{"title": "BUSTING", "photo": "bust", "text": "OVER 21 IS A BUST, BUT YOU'RE NOT OUT YET: PLAY A CARD LIKE DRINK ME TO GET BACK UNDER. YOU CAN'T HIT WHILE YOU'RE OVER.\n\nBUST AT THE END OF A ROUND AND YOU TAKE (TOTAL - 21) + THE ENEMY'S ATTACK.\n\nREACH %d AND IT'S A SUPER BUST: THE ROUND ENDS AND YOU TAKE DOUBLE." % super_at},
		{"title": "ENEMY ATTACKS", "demo": "attack", "text": "THE BAR ABOVE THE ENEMY FILLS DURING EACH ROUND.\n\nJUST BEFORE IT ATTACKS, A ! FLASHES, IT WINDS UP AND YOU HEAR A BEEP.\n\nIT ATTACKS AT MOST ONCE A ROUND. YOU'LL SEE WHAT IT DID (+2 TO YOUR TOTAL, A CARD KNOCKED OFF...) BUT NEVER ITS NAME.\n\nSTAND BEFORE THE BAR FILLS TO DODGE IT."},
		{"title": "THREE ACTS, EIGHT FIGHTS", "demo": "acts", "text": "ACT 1: 2 SOLDIERS, THEN THE MAD HATTER, WHO SWAPS YOUR CARDS WITH HIS.  ACT 2: 2 SOLDIERS, THEN THE CHESHIRE CAT, WHO HIDES YOUR TOTAL.  ACT 3: THE KNAVE OF HEARTS, THEN THE QUEEN.\nYOUR HP CARRIES OVER; YOU HEAL 5 AFTER EACH WIN. BEAT THE QUEEN TO WIN THE RUN."},
		{"title": "THE SHOP", "photo": "shop", "below": true, "text": "AFTER EVERY WIN YOU VISIT THE SHOP. BUY ANY OFFERED CARD YOU CAN AFFORD (10, 15 OR 25 GOLD) AND CLICK A DECK CARD TWICE TO REMOVE IT (5 GOLD). DO AS MANY AS YOU LIKE. SOLDIERS PAY 20 GOLD; BOSSES PAY MORE."},
		{"title": "CONTROLS", "photo": "map", "text": "H  HIT\nSPACE  STAND (OR S)\nE  HEAL\n1-5  PLAY A HAND CARD\nM  MUTE\nENTER  CONTINUE\n\nTHE MAP SHOWS YOUR ACT AND YOUR NEXT FIGHT. GOOD LUCK, ALICE!"},
	]


func _show(index: int) -> void:
	_page = clampi(index, 0, _pages.size() - 1)
	for child in _content.get_children():
		child.queue_free()
	_demo_enemy = null
	_demo_t = 0.0
	var p: Dictionary = _pages[_page]
	_title.text = str(p["title"])
	_counter.text = "%d/%d" % [_page + 1, _pages.size()]
	_back.disabled = _page == 0
	_next.text = "PLAY! [ENTER]" if _page == _pages.size() - 1 else "NEXT >"
	if p.has("photo"):
		_photo(str(p["photo"]), bool(p.get("below", false)), str(p["text"]))
	else:
		match str(p.get("demo", "")):
			"cards":
				_cards_demo(str(p["text"]))
			"attack":
				_attack_demo(str(p["text"]))
			"acts":
				_acts_demo(str(p["text"]))


## A screenshot from art/howto in a frame, with the text beside it (or below a wide one).
func _photo(file_name: String, below: bool, text: String) -> void:
	var path := "res://art/howto/%s.png" % file_name
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	var tex_size := tex.get_size() if tex else Vector2(280, 150)
	var max_size := Vector2(456, 170) if below else Vector2(284, 206)
	var k := minf(1.0, minf(max_size.x / tex_size.x, max_size.y / tex_size.y))
	var shown := (tex_size * k).floor()
	var pos := Vector2(roundf((480 - shown.x) / 2), 30) if below else Vector2(12, 30 + roundf((206 - shown.y) / 2))
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", Palette.box(Palette.INK, Palette.GOLD_HI, 1))
	frame.position = pos - Vector2(2, 2)
	frame.size = shown + Vector2(4, 4)
	_content.add_child(frame)
	if tex:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_SCALE
		img.position = pos
		img.size = shown
		_content.add_child(img)
	if below:
		_text(text, Vector2(24, pos.y + shown.y + 10), 432.0)
	else:
		_text(text, Vector2(pos.x + shown.x + 12, 32), 480.0 - (pos.x + shown.x + 12) - 10)


## The real hand-card widgets, plus the counter and the Heal button as they look in battle.
func _cards_demo(text: String) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(24, 60)
	row.add_theme_constant_override("separation", 4)
	_content.add_child(row)
	var i := 0
	for id: String in ["num_2", "drink_me", "eat_me", "teacup"]:
		var v := HandCardView.new()
		v.show_card(Card.from_def(GameData.card(id)), i)
		row.add_child(v)
		i += 1
	var counter := Palette.label("CARDS 1/%d   (2 PER ROUND)" % int(GameData.rule("round.plays_per_round", 2)), Palette.CREAM)
	counter.position = Vector2(24, 130)
	_content.add_child(counter)
	var heal := Palette.label("HEAL +%d [E]" % int(GameData.rule("player.heal_action", 3)), Palette.HP_GREEN)
	heal.position = Vector2(24, 146)
	_content.add_child(heal)
	_text(text, Vector2(268, 32), 200.0)


## A soldier on a loop: the bar fills, the ! flashes as it winds up, then it attacks.
func _attack_demo(text: String) -> void:
	var id := "club_soldier"
	_demo_enemy = AnimLib.sprite({"idle": id + "_idle", "tell": id + "_tell", "attack": id + "_attack_bonk"})
	if _demo_enemy == null or not _demo_enemy.sprite_frames.has_animation("idle"):
		_demo_enemy = null
		_text(text, Vector2(24, 40), 432.0)
		return
	_demo_enemy.position = Vector2(76, 56)
	_content.add_child(_demo_enemy)
	_demo_enemy.play("idle")
	var bar_bg := ColorRect.new()
	bar_bg.color = Palette.PLUM
	bar_bg.position = Vector2(84, 40)
	bar_bg.size = Vector2(112, 5)
	_content.add_child(bar_bg)
	_demo_bar = ColorRect.new()
	_demo_bar.color = Palette.GOLD_HI
	_demo_bar.position = bar_bg.position
	_demo_bar.size = Vector2(0, 5)
	_content.add_child(_demo_bar)
	_demo_alert = Palette.shadow_label("!", Palette.RED_HI, true)
	_demo_alert.position = Vector2(202, 32)
	_demo_alert.visible = false
	_content.add_child(_demo_alert)
	_demo_pop = Palette.shadow_label("", Palette.GOLD_HI, true)
	_demo_pop.position = Vector2(60, 186)
	_demo_pop.size = Vector2(160, 16)
	_demo_pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_demo_pop)
	_demo_phase = "fill"
	_text(text, Vector2(268, 32), 200.0)


## The three act bosses, animated, above the run's outline.
func _acts_demo(text: String) -> void:
	var acts := [["mad_hatter", "ACT 1: TEA PARTY"], ["cheshire_cat", "ACT 2: TULGEY WOOD"], ["queen_of_hearts", "ACT 3: QUEEN'S COURT"]]
	for i in acts.size():
		var id: String = acts[i][0]
		var x := 32 + i * 144
		if AnimLib.has(id + "_idle"):
			var s := AnimLib.sprite({"idle": id + "_idle"})
			s.position = Vector2(x, 26)
			_content.add_child(s)
			s.play("idle")
		var l := Palette.label(str(acts[i][1]), Palette.GOLD_HI)
		l.position = Vector2(x - 8, 128)
		l.size = Vector2(144, 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content.add_child(l)
	_text(text, Vector2(24, 146), 432.0)


func _process(delta: float) -> void:
	if _demo_enemy == null:
		return
	_demo_t += delta
	match _demo_phase:
		"fill":
			_demo_bar.size.x = 112.0 * clampf(_demo_t / 3.0, 0.0, 1.0)
			_demo_pop.text = ""
			if _demo_t >= 2.0:
				_demo_alert.visible = int(_demo_t / 0.15) % 2 == 0
				if _demo_enemy.animation != "tell":
					_demo_enemy.play("tell")
					Audio.play("warning")
			if _demo_t >= 3.0:
				_demo_phase = "attack"
				_demo_t = 0.0
				_demo_alert.visible = false
				_demo_bar.size.x = 0.0
				_demo_enemy.play("attack")
				_demo_pop.text = "+2 TO YOUR TOTAL!"
		"attack":
			if _demo_t >= 2.6:
				_demo_phase = "fill"
				_demo_t = 0.0
				_demo_enemy.play("idle")


func _text(text: String, pos: Vector2, width: float) -> void:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size = Vector2(width, 0)
	l.size = Vector2(width, 0)
	l.position = pos
	l.add_theme_color_override("font_color", Palette.CREAM)
	l.text = text
	_content.add_child(l)


func _button(text: String, pos: Vector2, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(100, 16)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Palette.box(Color(Palette.INK, 0.9), Palette.CREAM))
	b.add_theme_stylebox_override("hover", Palette.box(Palette.PLUM, Palette.GOLD_HI))
	b.add_theme_stylebox_override("disabled", Palette.box(Color(Palette.INK, 0.6), Palette.PLUM))
	b.pressed.connect(action)
	add_child(b)
	return b


func _turn(step: int) -> void:
	if _page + step >= _pages.size():
		_close()
	else:
		_show(_page + step)


func _close() -> void:
	if is_inside_tree():
		Transition.go(RunState.MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_RIGHT, KEY_D:
			_turn(1)
		KEY_LEFT, KEY_A:
			_turn(-1)
		KEY_ESCAPE:
			_close()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_turn(1)
