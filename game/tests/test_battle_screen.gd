extends GutTest
## The real battle scene (controller + screen together): these bugs lived between the two.

const BATTLE := preload("res://scenes/battle.tscn")

var _c: BattleController
var _ui  # battle_ui.gd; untyped so the tests can read its private widgets


func _start() -> void:
	RunState.new_run(4242)
	var scene := BATTLE.instantiate()
	add_child_autofree(scene)
	_c = scene.get_node("BattleController") as BattleController
	_ui = scene.get_node("UI")
	await wait_frames(2)  # start() is deferred one frame


func _pause() -> float:
	return float(GameData.rule("surprise.pause_seconds", 1.0)) + 0.3


func _hand_views() -> Array[Button]:
	var out: Array[Button] = []
	for v: Node in _ui._hand_row.get_children():
		if not v.is_queued_for_deletion():
			out.append(v as Button)
	return out


func test_round_ends_as_soon_as_both_have_stayed() -> void:
	await _start()
	assert_eq(_c.state, BattleController.State.ROUND_ACTIVE)
	_c.battle.enemy_stay()
	_c.stay()
	assert_eq(_c.state, BattleController.State.RESOLVE, "no waiting for the timer")
	assert_true(_c.round_timer.is_stopped())


func test_ready_and_hand_work_again_after_a_surprise_attack() -> void:
	await _start()
	_c.battle.shield = 1  # block it, so the attack itself can't bust Alice and disable READY
	_c._on_intent_full()
	assert_eq(_c.state, BattleController.State.SURPRISE)
	Events.hand_changed.emit()  # an attack that touches the hand redraws the screen mid-pause
	await wait_seconds(_pause())
	assert_eq(_c.state, BattleController.State.ROUND_ACTIVE)
	assert_false(_ui._stay.disabled, "READY is clickable again")
	assert_false(_ui._hit.disabled, "HIT is clickable again")
	assert_gt(_hand_views().size(), 0)
	for v: Button in _hand_views():
		assert_false(v.disabled, "hand cards are never greyed out")


func test_ready_pressed_during_an_attack_pause_counts() -> void:
	await _start()
	_c.battle.shield = 1
	_c.battle.enemy_stay()
	_c._on_intent_full()
	_c.stay()
	assert_true(_c.battle.player.stayed, "the press wasn't dropped")
	await wait_seconds(_pause())
	assert_eq(_c.state, BattleController.State.RESOLVE, "both stayed: the round ends right after the pause")


func test_hand_cards_stay_clickable_at_the_play_limit() -> void:
	await _start()
	var b := _c.battle
	b.cards_played = b.plays_per_round
	Events.hand_changed.emit()
	await wait_frames(1)
	assert_gt(_hand_views().size(), 0)
	for v: Button in _hand_views():
		assert_false(v.disabled, "not greyed out, even with no plays left")
	var hand_before := b.hand.size()
	_ui._request_play(0)
	assert_string_contains(_ui._message.text, "%d CARDS PER ROUND" % b.plays_per_round)
	assert_eq(b.hand.size(), hand_before, "the third card isn't played")
	assert_eq(b.cards_played, b.plays_per_round)


func test_hand_cards_can_be_played_after_ready() -> void:
	await _start()
	var b := _c.battle
	b.player_stay()
	var index := -1
	for i in b.hand.size():
		if b.can_play(i) and b.hand[i].is_number():
			index = i
			break
	if index < 0:
		pass_test("no number card in this opening hand")
		return
	assert_true(_c.play(index), "ready only stops drawing")
	assert_eq(b.cards_played, 1)


func test_attack_bar_starts_empty_every_round() -> void:
	await _start()
	await wait_seconds(0.6)
	assert_lt(_c.intent_timer.time_left, _c.intent_timer.wait_time - 0.4, "the bar has been filling")
	_c.battle.enemy_stay()
	_c.stay()
	await wait_seconds(float(GameData.rule("round.resolve_pause_seconds", 1.0)) + 0.2)
	assert_eq(_c.battle.round_number, 2)
	assert_eq(_c.state, BattleController.State.ROUND_ACTIVE)
	assert_almost_eq(_c.intent_timer.time_left, _c.intent_timer.wait_time, 0.3, "empty again at the new round")


func test_only_one_attack_per_round() -> void:
	await _start()
	_c.battle.shield = 1
	_c._on_intent_full()
	await wait_seconds(_pause())
	assert_eq(_c.state, BattleController.State.ROUND_ACTIVE)
	assert_true(_c.intent_timer.is_stopped(), "no second attack this round")
