extends GutTest
## RunState: soldier shuffle, gold, healing, stats from signals, and the POST /run payload.


func after_each() -> void:
	RunState.end_run()


func test_acts_run_tea_party_then_tulgey_wood_then_the_queens_court() -> void:
	assert_eq(RunState.act_ids(), ["act1_tea", "act2_wood", "act3_court"] as Array[String])
	assert_eq(RunState.total_battles(), 8)


func test_each_act_ends_with_its_boss() -> void:
	var rng := TestHelpers.rng(1)
	var act1: Array[String] = RunState.act_order("act1_tea", rng)
	assert_eq(act1.size(), 3)
	assert_eq(act1.back(), "mad_hatter")
	assert_true(act1.has("spade_soldier") and act1.has("club_soldier"))
	var act2: Array[String] = RunState.act_order("act2_wood", rng)
	assert_eq(act2.back(), "cheshire_cat")
	assert_true(act2.has("diamond_soldier") and act2.has("heart_soldier"))
	assert_eq(RunState.act_order("act3_court", rng), ["knave_of_hearts", "queen_of_hearts"] as Array[String])


func test_same_seed_same_soldier_order() -> void:
	assert_eq(RunState.act_order("act1_tea", TestHelpers.rng(77)), RunState.act_order("act1_tea", TestHelpers.rng(77)))


func test_soldier_order_differs_between_seeds() -> void:
	var orders := {}
	for s in 12:
		orders[str(RunState.act_order("act1_tea", TestHelpers.rng(s)))] = true
	assert_gt(orders.size(), 1, "seeds shuffle the soldiers")


func test_a_new_run_starts_in_act_1() -> void:
	RunState.new_run(5)
	assert_eq(RunState.act_id, "act1_tea")
	assert_eq(RunState.act_index, 0)
	assert_eq(RunState.battles.back(), "mad_hatter")


func test_beating_an_act_boss_moves_on_to_the_next_act() -> void:
	RunState.new_run(5)
	for i in 3:
		RunState.record_win(RunState.current_enemy_id())
	assert_true(RunState.act_complete())
	assert_false(RunState.is_complete(), "two acts to go")
	assert_true(RunState.outcome.is_empty())
	assert_eq(RunState.scene_after_battle(), RunState.REWARD_SCENE, "the shop before the next act")
	RunState.advance_act()
	assert_eq(RunState.act_id, "act2_wood")
	assert_eq(RunState.battle_index, 0)
	assert_eq(RunState.battles_won, 3)


func test_act_bosses_pay_gold_for_the_shop_between_acts() -> void:
	RunState.new_run(5)
	assert_eq(RunState.record_win("mad_hatter")["gold"], int(GameData.enemy("mad_hatter")["bonus_gold"]))
	assert_gt(int(GameData.enemy("cheshire_cat")["bonus_gold"]), 0)


func test_a_save_right_after_an_act_boss_continues_in_the_next_act() -> void:
	RunState.new_run(5)
	for i in 3:
		RunState.record_win(RunState.current_enemy_id())
	RunState.save()
	RunState.new_run(1)
	assert_true(RunState.load_saved())
	assert_eq(RunState.act_id, "act2_wood")
	assert_eq(RunState.battle_index, 0)
	assert_eq(RunState.battles_won, 3)


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
	_win_whole_run()
	assert_eq(RunState.outcome["enemy"], "queen_of_hearts")
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
	assert_eq(p["act"], "act1_tea")
	assert_false(p["won"])
	assert_eq(p["battles_won"], 0)
	assert_eq(typeof(p["time_ms"]), TYPE_INT)
	assert_eq((p["stats"] as Dictionary).keys().size(), 4)
	assert_eq(typeof(p["stats"]["rounds"]), TYPE_INT)
	assert_eq(p["game_version"], GameData.game_version())


## Win every fight, act by act, the way the shop moves the run along.
func _win_whole_run() -> void:
	while true:
		RunState.record_win(RunState.current_enemy_id())
		if not RunState.outcome.is_empty():
			return
		if RunState.act_complete():
			RunState.advance_act()


func test_won_only_when_all_eight_battles_are_won() -> void:
	RunState.new_run(1)
	_win_whole_run()
	var p: Dictionary = RunState.run_payload()
	assert_true(p["won"])
	assert_eq(p["battles_won"], 8)
	assert_eq(p["act"], "act3_court")


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
