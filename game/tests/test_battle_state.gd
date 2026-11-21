extends GutTest
## Deal, hit, stay, resolve and damage on the plain BattleState.

var rules: Dictionary


func before_all() -> void:
	rules = GameData.read_json("rules.json")


func _battle(seed_value: int = 5, player_hp: int = 30) -> BattleState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return BattleState.new(rules, GameData.read_json("enemies.json")["enemies"][1], rng, player_hp, 30)


func _set_table(c: Combatant, ranks: Array) -> void:
	c.table.clear()
	for r: String in ranks:
		c.table.append(Card.blind(r, "hearts"))


func test_rules_file_has_the_starting_values() -> void:
	assert_eq(int(rules["player"]["max_hp"]), 30)
	assert_eq(int(rules["player"]["base_attack"]), 3)
	assert_eq(int(rules["round"]["seconds"]), 10, "short rounds")
	assert_eq(int(rules["round"]["plays_per_round"]), 0, "play cards at will")


func test_deal_gives_two_blind_cards_each() -> void:
	var b := _battle()
	watch_signals(b)
	b.start_round()
	assert_eq(b.player.table.size(), 2)
	assert_eq(b.enemy.table.size(), 2)
	assert_eq(b.hit_deck.remaining(), 48)
	assert_signal_emit_count(b, "card_dealt", 4)


func test_new_round_clears_the_table_into_the_discard_pile() -> void:
	var b := _battle()
	b.start_round()
	b.player_hit()
	b.start_round()
	assert_eq(b.player.table.size(), 2)
	assert_eq(b.hit_deck.discard_pile.size(), 5)
	assert_false(b.player.stayed)


func test_hit_adds_a_card_and_busting_ends_your_turn() -> void:
	var b := _battle()
	b.start_round()
	_set_table(b.player, ["10", "9"])
	while not b.player.is_bust():
		b.player_hit()
	assert_true(b.player.stayed, "a bust auto-stays")
	assert_null(b.player_hit(), "no more hits after busting")


func test_resolve_applies_the_damage_table() -> void:
	var b := _battle()
	b.start_round()
	_set_table(b.player, ["10", "10"])
	_set_table(b.enemy, ["10", "7"])
	var r := b.resolve_round()
	assert_eq(r["winner"], "player")
	assert_eq(b.enemy.hp, b.enemy.max_hp - (3 + 3))
	assert_eq(b.player.hp, 30)


func test_both_bust_hurts_both() -> void:
	var b := _battle()
	b.start_round()
	_set_table(b.player, ["10", "10", "5"])
	_set_table(b.enemy, ["10", "10", "3"])
	b.resolve_round()
	assert_eq(b.player.hp, 28)
	assert_eq(b.enemy.hp, b.enemy.max_hp - 2)


func test_battle_over_when_someone_hits_zero() -> void:
	var b := _battle(5, 3)
	b.start_round()
	_set_table(b.player, ["10", "10", "5"])
	_set_table(b.enemy, ["10", "9"])
	b.resolve_round()
	assert_true(b.is_over())
	assert_false(b.player_won())


func test_same_seed_same_deal() -> void:
	var a := _battle(42)
	var b := _battle(42)
	a.start_round()
	b.start_round()
	assert_eq(a.player.total(), b.player.total())
	assert_eq(a.enemy.total(), b.enemy.total())
