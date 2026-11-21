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


func test_chases_a_visible_player_total() -> void:
	var b := _battle(17, 0.0)
	_set_table(b.enemy, ["10", "8"])
	_set_table(b.player, ["10", "9"])
	b.player.stayed = true
	assert_eq(EnemyAI.decide(b), EnemyAI.HIT, "18 loses to 19, so it hits")


func test_caterpillar_smoke_makes_it_play_blind() -> void:
	var b := _battle(17, 0.0)
	_set_table(b.enemy, ["10", "8"])
	_set_table(b.player, ["10", "9"])
	b.player.stayed = true
	b.hide_total = true
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY)


func test_stays_when_the_player_busted() -> void:
	var b := _battle()
	_set_table(b.enemy, ["10", "2"])
	_set_table(b.player, ["10", "9", "5"])
	b.player.stayed = true
	assert_eq(EnemyAI.decide(b), EnemyAI.STAY)
