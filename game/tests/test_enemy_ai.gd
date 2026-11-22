extends GutTest
## The shared base AI.


func _battle(stay_at: int = 17, risk: float = 0.0) -> BattleState:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var enemy := {"id": "test", "name": "Test", "hp": 20, "base_attack": 3, "stay_at": stay_at, "risk": risk}
	return BattleState.new(GameData.read_json("rules.json"), enemy, rng, 30, 30)


func _set_table(c: Combatant, ranks: Array) -> void:
	c.table.clear()
	for r: String in ranks:
		c.table.append(Card.blind(r, "clubs"))


func test_hits_below_stay_at() -> void:
	var b := _battle()
	_set_table(b.enemy, ["10", "2"])
	assert_eq(EnemyAI.decide(b), EnemyAI.HIT)


func test_stays_at_stay_at_with_no_risk() -> void:
	var b := _battle(17, 0.0)
	_set_table(b.enemy, ["10", "7"])
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY)


func test_risky_hit_only_up_to_18() -> void:
	var b := _battle(17, 1.0)
	_set_table(b.enemy, ["10", "8"])
	assert_eq(EnemyAI.decide(b), EnemyAI.HIT, "18 with risk 1.0 hits")
	_set_table(b.enemy, ["10", "9"])
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY, "19 never gambles")


func test_does_nothing_once_stayed_or_bust() -> void:
	var b := _battle()
	_set_table(b.enemy, ["10", "2"])
	b.enemy.stayed = true
	assert_eq(EnemyAI.decide(b), EnemyAI.NONE)
	b.enemy.stayed = false
	_set_table(b.enemy, ["10", "9", "5"])
	assert_eq(EnemyAI.decide(b), EnemyAI.NONE)


func test_chases_a_visible_player_total_during_the_round() -> void:
	var b := _battle(17, 0.0)
	_set_table(b.enemy, ["10", "8"])
	_set_table(b.player, ["10", "9"])
	assert_false(b.player.stayed, "she hasn't stood: standing would end the round")
	assert_eq(EnemyAI.decide(b), EnemyAI.HIT, "18 loses to her 19, so it races to beat it")


func test_stops_chasing_once_it_is_ahead() -> void:
	var b := _battle(17, 0.0)
	_set_table(b.enemy, ["10", "9"])
	_set_table(b.player, ["10", "8"])
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY)


func test_caterpillar_smoke_makes_it_play_blind() -> void:
	var b := _battle(17, 0.0)
	_set_table(b.enemy, ["10", "8"])
	_set_table(b.player, ["10", "9"])
	b.hide_total = true
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY, "it can't see her 19, so it stays on 18 like normal")


func test_playing_caterpillar_smoke_changes_what_it_does() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["caterpillar_smoke"])
	b.enemy_risk = 0.0
	_set_table(b.enemy, ["10", "8"])
	_set_table(b.player, ["10", "9"])
	assert_eq(EnemyAI.decide(b), EnemyAI.HIT)
	assert_true(b.play_card(0))
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY, "the card works during the round, before you stand")


func test_a_player_bust_does_not_make_it_stop_early() -> void:
	var b := _battle()
	_set_table(b.enemy, ["10", "2"])
	_set_table(b.player, ["10", "9", "5"])
	assert_eq(EnemyAI.decide(b), EnemyAI.HIT, "a bust can be undone with a card, so it plays on to its stay-at number")
