class_name BattleController
extends Node
## Owns one battle as a small state machine:
##
##   DEAL -> ROUND_ACTIVE -> RESOLVE -> (DEAL | BATTLE_END)
##                ^    |
##                |    v   intent bar fills
##               SURPRISE
##
## Rounds are real-time inside a 15 s window but resolve in fixed steps, so they stay
## fair and testable. Logic changes state first, then emits on Events. The UI only
## calls hit()/stay()/play() and listens; it never changes game state itself.

enum State { DEAL, ROUND_ACTIVE, SURPRISE, RESOLVE, BATTLE_END }

var state: State = State.DEAL
var battle: BattleState
var _ai_wait_ticks: int = 0
var _freezes: int = 0
var _last_intent: float = -1.0
var _autoplay: bool = false
## Launched on its own (F6 / smoke run) rather than from the run map.
var _standalone: bool = false

@onready var round_timer: Timer = $RoundTimer
@onready var ai_timer: Timer = $AiTimer
@onready var intent_timer: Timer = $IntentTimer


func _ready() -> void:
	_autoplay = Autoplay.enabled()
	ai_timer.wait_time = float(GameData.rule("ai.tick_seconds", 0.5))
	ai_timer.timeout.connect(_on_ai_tick)
	round_timer.timeout.connect(_on_round_timeout)
	intent_timer.timeout.connect(_on_intent_full)
	# Deferred so the UI (a later sibling) is connected to Events before the first signals.
	start.call_deferred(RunState.current_enemy_id())


func start(enemy_id: String) -> void:
	if not RunState.active:
		# Scene launched on its own (F6 in the editor, or a headless smoke run).
		_standalone = true
		RunState.new_run(Rng.new_seed())
		enemy_id = RunState.current_enemy_id()
	battle = BattleState.new(GameData.rules, GameData.enemy(enemy_id), Rng.rng, RunState.hp, RunState.max_hp)
	battle.setup_deck(GameData.cards, RunState.deck)
	battle.setup_trinkets(RunState.trinket_defs())
	battle.card_dealt.connect(Events.card_dealt.emit)
	battle.card_removed.connect(Events.card_removed.emit)
	battle.card_played.connect(Events.card_played.emit)
	battle.total_changed.connect(Events.total_changed.emit)
	battle.hand_changed.connect(Events.hand_changed.emit)
	battle.hp_changed.connect(Events.hp_changed.emit)
	battle.peeked.connect(Events.peeked.emit)
	battle.surprise_attack.connect(Events.surprise_attack.emit)
	battle.surprise_blocked.connect(Events.surprise_blocked.emit)
	battle.round_resolved.connect(Events.round_resolved.emit)
	battle.message.connect(Events.message.emit)
	battle.timer_freeze_requested.connect(_freeze_round_timer)
	battle.boss_phase_changed.connect(_on_boss_phase)
	Events.battle_started.emit(enemy_id)
	Events.hp_changed.emit("player", battle.player.hp, battle.player.max_hp)
	Events.hp_changed.emit("enemy", battle.enemy.hp, battle.enemy.max_hp)
	intent_timer.wait_time = battle.intent_seconds()
	_deal()


func _process(_delta: float) -> void:
	if battle == null or state == State.BATTLE_END:
		return
	if state == State.ROUND_ACTIVE or state == State.SURPRISE:
		Events.timer_changed.emit(round_timer.time_left)
	var intent := 1.0 - intent_timer.time_left / maxf(intent_timer.wait_time, 0.01)
	if absf(intent - _last_intent) >= 0.01:
		_last_intent = intent
		Events.intent_changed.emit(battle.enemy_id(), clampf(intent, 0.0, 1.0))


# --- player input (requests; the controller decides) -------------------------

func hit() -> void:
	if not _can_act():
		return
	battle.player_hit()
	if battle.player.is_bust(battle.target):
		Events.message.emit("BUST! %d" % battle.player.total(battle.target))
	_check_round_end()


func stay() -> void:
	if not _can_act():
		return
	battle.player_stay()
	Events.message.emit("You stay on %d." % battle.player.total(battle.target))
	_check_round_end()


func play(index: int, choice: Dictionary = {}) -> bool:
	if not _can_act() or not battle.play_card(index, choice):
		return false
	_check_round_end()
	return true


## Debug (F2): win the current battle instantly, to skip to the Queen while testing endings.
func debug_win() -> void:
	if battle == null or state == State.BATTLE_END or state == State.RESOLVE:
		return
	battle.enemy.hp = 0
	_end()


func _can_act() -> bool:
	return battle != null and state == State.ROUND_ACTIVE and not battle.player.stayed


# --- states -------------------------------------------------------------------

func _deal() -> void:
	state = State.DEAL
	battle.start_round()
	Events.round_started.emit(battle.round_number)
	state = State.ROUND_ACTIVE
	_ai_wait_ticks = _reaction_ticks()
	_freezes = 0
	round_timer.paused = false
	round_timer.start(float(GameData.rule("round.seconds", 15)))
	ai_timer.start()
	if intent_timer.is_stopped():
		intent_timer.start()
	intent_timer.paused = false


## Base AI every 0.5 s tick, after a 1-2 s reaction delay so it feels like it's thinking.
## (Alice's autoplay bot rides the same tick in headless smoke runs.)
func _on_ai_tick() -> void:
	if state != State.ROUND_ACTIVE:
		return
	if _autoplay:
		_autoplay_step()
	if _ai_wait_ticks > 0:
		_ai_wait_ticks -= 1
		return
	var decision := EnemyAI.decide(battle)
	if decision == EnemyAI.HIT:
		battle.enemy_hit()
	elif decision == EnemyAI.STAY:
		battle.enemy_stay()
		Events.message.emit("%s stays." % battle.enemy.display_name)
	_ai_wait_ticks = _reaction_ticks()
	_check_round_end()


func _reaction_ticks() -> int:
	var tick := float(GameData.rule("ai.tick_seconds", 0.5))
	var lo := float(GameData.rule("ai.reaction_min_seconds", 1.0))
	var hi := float(GameData.rule("ai.reaction_max_seconds", 2.0))
	return maxi(0, int(round(Rng.rng.randf_range(lo, hi) / tick)) - 1)


## Timer ran out: auto-stay everyone.
func _on_round_timeout() -> void:
	if state != State.ROUND_ACTIVE:
		return
	if not battle.player.stayed:
		Events.message.emit("TIME! You stay on %d." % battle.player.total(battle.target))
	battle.force_stay()
	_check_round_end()


## SURPRISE: pause the round for a beat, apply the attack, then return to the round.
func _on_intent_full() -> void:
	if state != State.ROUND_ACTIVE:
		return
	state = State.SURPRISE
	round_timer.paused = true
	ai_timer.paused = true
	battle.fire_surprise()
	await _wait(float(GameData.rule("surprise.pause_seconds", 1.0)))
	if state != State.SURPRISE:
		return
	state = State.ROUND_ACTIVE
	round_timer.paused = _freezes > 0
	ai_timer.paused = false
	intent_timer.start()
	_check_round_end()


## The Queen's rage phase: faster intent bar, plus the designer's rage animation and music change.
func _on_boss_phase(phase: int) -> void:
	intent_timer.wait_time = battle.intent_seconds()
	Events.boss_phase_changed.emit(phase)
	Events.message.emit("THE QUEEN IS ENRAGED!")


## Pocket Watch: pause the round timer without eating the player's time.
func _freeze_round_timer(seconds: float) -> void:
	_freezes += 1
	round_timer.paused = true
	Events.message.emit("TIME STANDS STILL...")
	await _wait(seconds)
	_freezes = maxi(0, _freezes - 1)
	if _freezes == 0 and state == State.ROUND_ACTIVE:
		round_timer.paused = false


func _check_round_end() -> void:
	if state == State.ROUND_ACTIVE and battle.both_done():
		_resolve()


func _resolve() -> void:
	state = State.RESOLVE
	round_timer.stop()
	ai_timer.stop()
	intent_timer.paused = true
	var result := battle.resolve_round()
	if _autoplay:
		Autoplay.log_line("round %d: %s, %s takes %d (you %d vs %d) HP %d/%d" % [
			result["round"], result["kind"], result["loser"], result["damage"],
			result["player_total"], result["enemy_total"], battle.player.hp, battle.enemy.hp])
	await _wait(float(GameData.rule("round.resolve_pause_seconds", 1.5)))
	if battle.is_over():
		_end()
	else:
		_deal()


func _end() -> void:
	state = State.BATTLE_END
	round_timer.stop()
	ai_timer.stop()
	intent_timer.stop()
	RunState.hp = battle.player.hp
	if _autoplay:
		Autoplay.log_line("battle %s vs %s after %d rounds" % ["won" if battle.player_won() else "lost", battle.enemy_id(), battle.round_number])
	if battle.player_won():
		RunState.record_win(battle.enemy_id())
		Events.battle_won.emit(battle.enemy_id())
	else:
		RunState.record_loss(battle.enemy_id())
		Events.battle_lost.emit(battle.enemy_id())
	if _autoplay and _standalone:
		get_tree().quit()


## A pause owned by this node: if the scene changes mid-wait, the timer dies with it
## and the coroutine is dropped instead of resuming on a freed controller.
func _wait(seconds: float) -> void:
	var t := Timer.new()
	t.one_shot = true
	add_child(t)
	t.start(seconds)
	await t.timeout
	t.queue_free()


func _autoplay_step() -> void:
	var action := Autoplay.decide(battle)
	if action == "hit":
		hit()
	elif action == "stay":
		stay()
	elif action.begins_with("play:"):
		play(int(action.trim_prefix("play:")))
