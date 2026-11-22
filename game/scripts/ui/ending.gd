extends Control
## The endings. Win: the world drains to grey, an axe shadow passes and the Queen's head
## flips into a card. Lose: "Off with her head!", the axe swings at you and your view drops.
## Both play the pixel-art sequences from game/art/anim (tools/sprites), then dim and show the
## stats and leaderboard. Without the art, the old AnimationPlayer placeholders play instead.

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var figure: Control = $Figure
@onready var head: ColorRect = $Figure/Head
@onready var body: ColorRect = $Figure/Body
@onready var title: Label = $Title

var _stats: Label
var _status: Label
var _board: Label


func _ready() -> void:
	var won := bool(RunState.outcome.get("won", false))
	# Placeholders until the designer's art: the Queen in red, Alice in green.
	body.color = Palette.RED if won else Palette.GREEN
	head.color = Palette.CREAM
	title.text = "THE QUEEN LOSES HER HEAD!" if won else "OFF WITH HER HEAD!"
	title.add_theme_color_override("font_color", Palette.CREAM if won else Palette.RED)
	title.add_theme_font_override("font", load("res://art/fonts/pixel_big.fnt"))
	title.add_theme_font_size_override("font_size", 16)

	var s: Dictionary = RunState.stats
	var secs: int = RunState.time_ms() / 1000
	_stats = _label(Vector2(250, 70), "\n".join([
		"BATTLES WON  %d/%d" % [RunState.battles_won, RunState.total_battles()],
		"ROUNDS       %d" % int(s.get("rounds", 0)),
		"BUSTS        %d" % int(s.get("busts", 0)),
		"BLACKJACKS   %d" % int(s.get("blackjacks", 0)),
		"GOLD         %d" % RunState.gold,
		"TIME         %d:%02d" % [secs / 60, secs % 60],
	]), Palette.CREAM)
	_stats.visible = false
	_status = _label(Vector2(250, 130), "", Palette.GREEN)
	_board = _label(Vector2(250, 146), "", Palette.CREAM)

	var key := "ending_win" if won else "ending_lose"
	if AnimLib.has(key) and not Autoplay.enabled():
		figure.visible = false
		title.visible = false
		var seq := AnimLib.sprite({"play": key})
		add_child(seq)
		move_child(seq, 1)
		await seq.animation_finished
		create_tween().tween_property(seq, "modulate", Color(0.45, 0.45, 0.5), 0.6)
		var panel := Panel.new()
		panel.add_theme_stylebox_override("panel", Palette.box(Color(Palette.INK, 0.88), Palette.GOLD_DARK))
		panel.position = Vector2(242, 62)
		panel.size = Vector2(232, 200)
		add_child(panel)
		move_child(panel, seq.get_index() + 1)
	else:
		anim.play("win" if won else "lose")
		await anim.animation_finished
	_stats.visible = true
	_submit()


func _label(pos: Vector2, text: String, color: Color) -> Label:
	var l := Palette.label(text, color)
	l.position = pos
	add_child(l)
	return l


func _submit() -> void:
	var payload: Dictionary = RunState.run_payload()
	RunState.end_run()
	_status.text = "SUBMITTING RUN..."
	Api.submit_run(payload, _on_submitted.bind(payload))


func _on_submitted(result: Variant, payload: Dictionary) -> void:
	var won := bool(payload["won"])
	if result is Dictionary:
		var rank := int((result as Dictionary)["rank"])
		_status.text = "YOU PLACED #%d%s!" % [rank, " TODAY" if payload["is_daily"] else ""]
		_status.add_theme_color_override("font_color", Palette.RED)
	else:
		_status.text = "OFFLINE: RUN NOT SUBMITTED"
	if Autoplay.enabled():
		Autoplay.log_line("run %s, battles won %d, rounds %d" % ["won" if won else "lost", payload["battles_won"], payload["stats"]["rounds"]])
		get_tree().quit()
		return
	_board.text = "LOADING LEADERBOARD..." if result is Dictionary else "ENTER: MENU"
	if result is Dictionary:
		Api.leaderboard(bool(payload["is_daily"]), 10, _on_board.bind(bool(payload["is_daily"])))


func _on_board(entries: Variant, daily: bool) -> void:
	if not (entries is Array):
		_board.text = "ENTER: MENU"
		return
	var lines: Array[String] = ["TODAY'S TOP 10" if daily else "TOP 10"]
	for e: Dictionary in entries:
		var secs := int(e.get("time_ms", 0)) / 1000
		var result := "QUEEN" if bool(e.get("won", false)) else "%d/%d" % [int(e.get("battles_won", 0)), RunState.total_battles()]
		lines.append("%2d %-16s %-5s %d:%02d" % [int(e.get("rank", 0)), str(e.get("player_name", "")).to_upper(), result, secs / 60, secs % 60])
	lines.append("")
	lines.append("ENTER: MENU")
	_board.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_SPACE):
		Transition.go(RunState.MENU_SCENE)
