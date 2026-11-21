class_name BattleController
extends Node
## Owns one battle as a small state machine:
##   DEAL -> ROUND_ACTIVE -> RESOLVE -> (DEAL again | BATTLE_END)
## Logic changes state first, then emits on Events. The UI only calls hit()/stay()
## and listens; it never changes game state itself.

enum State { DEAL, ROUND_ACTIVE, SURPRISE, RESOLVE, BATTLE_END }

var state: State = State.DEAL
var battle: BattleState
var _ai_wait_ticks: int = 0

@onready var ai_timer: Timer = $AiTimer


func _ready() -> void:
	ai_timer.wait_time = float(GameData.rule("ai.tick_seconds", 0.5))
	ai_timer.timeout.connect(_on_ai_tick)
	# Deferred so the UI (a later sibling) is connected to Events before the first signals.
	start.call_deferred(RunState.current_enemy_id())


func start(enemy_id: String) -> void:
	battle = BattleState.new(GameData.rules, GameData.enemy(enemy_id), Rng.rng, RunState.hp, RunState.max_hp)
	battle.card_dealt.connect(Events.card_dealt.emit)
	battle.total_changed.connect(Events.total_changed.emit)
	battle.hp_changed.connect(Events.hp_changed.emit)
	battle.round_resolved.connect(Events.round_resolved.emit)
	battle.message.connect(Events.message.emit)
	Events.battle_started.emit(enemy_id)
	Events.hp_changed.emit("player", battle.player.hp, battle.player.max_hp)
	Events.hp_changed.emit("enemy", battle.enemy.hp, battle.enemy.max_hp)
	_deal()


# --- player input (requests; the controller decides) -------------------------

func hit() -> void:
	if state != State.ROUND_ACTIVE or battle.player.stayed:
		return
	battle.player_hit()
	if battle.player.is_bust(battle.target):
		Events.message.emit("Bust! %d" % battle.player.total(battle.target))
	_check_round_end()


func stay() -> void:
	if state != State.ROUND_ACTIVE or battle.player.stayed:
		return
	battle.player_stay()
	Events.message.emit("You stay on %d." % battle.player.total(battle.target))
	_check_round_end()


# --- states -------------------------------------------------------------------

func _deal() -> void:
	state = State.DEAL
	battle.start_round()
	Events.round_started.emit(battle.round_number)
	state = State.ROUND_ACTIVE
	_ai_wait_ticks = _reaction_ticks()
	ai_timer.start()


## Base AI, every 0.5 s tick, with a 1-2 s reaction delay so the enemy feels like it's thinking.
func _on_ai_tick() -> void:
	if state != State.ROUND_ACTIVE:
		return
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


func _check_round_end() -> void:
	if state == State.ROUND_ACTIVE and battle.both_done():
		_resolve()


func _resolve() -> void:
	state = State.RESOLVE
	ai_timer.stop()
	battle.resolve_round()
	await get_tree().create_timer(float(GameData.rule("round.resolve_pause_seconds", 1.5))).timeout
	if battle.is_over():
		_end()
	else:
		_deal()


func _end() -> void:
	state = State.BATTLE_END
	RunState.hp = battle.player.hp
	if battle.player_won():
		Events.battle_won.emit(battle.enemy_id())
	else:
		Events.battle_lost.emit(battle.enemy_id())
