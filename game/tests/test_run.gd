extends GutTest
## RunState: soldier shuffle, gold, healing, stats from signals, and the POST /run payload.


func after_each() -> void:
	RunState.end_run()


func test_act_order_puts_the_queen_last() -> void:
	var order: Array[String] = RunState.act_order("act3_court", TestHelpers.rng(1))
	assert_eq(order.size(), 5)
	assert_eq(order.back(), "queen_of_hearts")
	for id: String in ["spade_soldier", "club_soldier", "diamond_soldier", "heart_soldier"]:
		assert_true(order.has(id))


func test_same_seed_same_soldier_order() -> void:
	assert_eq(RunState.act_order("act3_court", TestHelpers.rng(77)), RunState.act_order("act3_court", TestHelpers.rng(77)))


func test_soldier_order_differs_between_seeds() -> void:
	var orders := {}
	for s in 12:
		orders[str(RunState.act_order("act3_court", TestHelpers.rng(s)))] = true
	assert_gt(orders.size(), 1, "seeds shuffle the soldiers")


func test_new_run_starts_fresh() -> void:
	RunState.new_run(123)
	assert_eq(RunState.hp, 30)
	assert_eq(RunState.deck.size(), 10)
	assert_eq(RunState.battle_index, 0)
	assert_eq(RunState.gold, 0)
	assert_true(RunState.active)


func test_winning_a_battle_pays_gold_and_heals_5() -> void:
	RunState.new_run(1)
	RunState.hp = 20
	var per_win := int(GameData.rule("run.gold_per_soldier", 0))
	var r: Dictionary = RunState.record_win("club_soldier")
	assert_eq(r["gold"], per_win)
	assert_eq(RunState.gold, per_win)
	assert_eq(RunState.hp, 25)
	assert_eq(RunState.battle_index, 1)
	assert_eq(RunState.scene_after_battle(), RunState.REWARD_SCENE)


func test_diamond_soldier_drops_extra_gold() -> void:
	RunState.new_run(1)
	var per_win := int(GameData.rule("run.gold_per_soldier", 0))
	assert_eq(RunState.record_win("diamond_soldier")["gold"], per_win + int(GameData.enemy("diamond_soldier")["bonus_gold"]))


func test_no_full_heals() -> void:
	RunState.new_run(1)
	RunState.hp = 29
	RunState.record_win("spade_soldier")
	assert_eq(RunState.hp, 30, "capped at max HP")


func test_beating_the_queen_wins_the_run() -> void:
	RunState.new_run(1)
	for i in 5:
		RunState.record_win(RunState.current_enemy_id())
	assert_true(RunState.is_complete())
	assert_true(RunState.outcome["won"])
	assert_eq(RunState.scene_after_battle(), RunState.ENDING_SCENE)


func test_stats_come_from_battle_signals() -> void:
	RunState.new_run(1)
	Events.round_resolved.emit({"player_bust": true, "blackjack": false})
	Events.round_resolved.emit({"player_bust": false, "blackjack": true})
	Events.card_played.emit(Card.from_def(GameData.card("drink_me")))
	Events.card_played.emit(Card.from_def(GameData.card("drink_me")))
	assert_eq(RunState.stats["rounds"], 2)
	assert_eq(RunState.stats["busts"], 1)
	assert_eq(RunState.stats["blackjacks"], 1)
	assert_eq(RunState.stats["cards_played"]["drink_me"], 2)


func test_run_payload_matches_the_backend_contract() -> void:
	RunState.new_run(834201933)
	RunState.player_name = "alice"
	RunState.record_loss("spade_soldier")
	var p: Dictionary = RunState.run_payload()
	var keys := p.keys()
	keys.sort()
	assert_eq(keys, ["act", "battles_won", "game_version", "is_daily", "player_name", "seed", "stats", "time_ms", "won"])
	assert_eq(p["seed"], 834201933)
	assert_eq(p["act"], "act3_court")
	assert_false(p["won"])
	assert_eq(p["battles_won"], 0)
	assert_eq(typeof(p["time_ms"]), TYPE_INT)
	assert_eq((p["stats"] as Dictionary).keys().size(), 4)
	assert_eq(typeof(p["stats"]["rounds"]), TYPE_INT)
	assert_eq(p["game_version"], GameData.game_version())


func test_won_only_when_all_five_battles_are_won() -> void:
	RunState.new_run(1)
	for i in 5:
		RunState.record_win(RunState.current_enemy_id())
	var p: Dictionary = RunState.run_payload()
	assert_true(p["won"])
	assert_eq(p["battles_won"], 5)


func test_save_and_continue() -> void:
	RunState.new_run(4242)
	RunState.record_win(RunState.current_enemy_id())
	RunState.add_card("vorpal_blade")
	RunState.save()
	var order: Array[String] = RunState.battles.duplicate()
	RunState.new_run(1)
	assert_true(RunState.load_saved())
	assert_eq(RunState.run_seed, 4242)
	assert_eq(RunState.battle_index, 1)
	assert_eq(RunState.battles, order)
	assert_true(RunState.deck.has("vorpal_blade"))
