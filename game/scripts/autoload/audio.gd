extends Node
## Sound effects, driven entirely by Events: logic never knows audio exists.
## M toggles mute. Sounds live in res://audio (placeholders from tools/export_art.py).

const SOUNDS := ["deal", "hit", "play", "bust", "win_round", "lose_round", "critical", "surprise", "blocked", "victory", "defeat", "click"]

var muted: bool = false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	for name: String in SOUNDS:
		var path := "res://audio/%s.wav" % name
		if ResourceLoader.exists(path):
			_streams[name] = load(path)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	Events.card_dealt.connect(func(_who: String, _card: Card) -> void: play("deal"))
	Events.card_played.connect(func(_card: Card) -> void: play("play"))
	Events.surprise_attack.connect(func(_id: String, _kind: String) -> void: play("surprise"))
	Events.surprise_blocked.connect(func(_id: String, _kind: String) -> void: play("blocked"))
	Events.boss_phase_changed.connect(func(_phase: int) -> void: play("surprise"))
	Events.round_resolved.connect(_on_round_resolved)
	Events.battle_won.connect(func(_id: String) -> void: play("victory"))
	Events.battle_lost.connect(func(_id: String) -> void: play("defeat"))


func play(name: String) -> void:
	if muted or not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.play()


func toggle_mute() -> void:
	muted = not muted


func _on_round_resolved(r: Dictionary) -> void:
	if bool(r.get("critical", false)):
		play("critical")
	elif bool(r.get("player_bust", false)):
		play("bust")
	elif r.get("winner") == "player":
		play("win_round")
	elif r.get("winner") == "enemy":
		play("lose_round")


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_M:
		toggle_mute()
