extends GutTest
## Demo mode: straight to the final boss, never saved over a real run.


func after_each() -> void:
	RunState.end_run()
	RunState.clear_save()


func test_demo_is_one_fight_with_the_queen_in_her_court() -> void:
	RunState.new_demo(9)
	assert_true(RunState.is_demo)
	assert_eq(RunState.battles, ["queen_of_hearts"] as Array[String])
	assert_eq(RunState.current_enemy_id(), "queen_of_hearts")
	assert_eq(RunState.act_id, "act3_court")
	assert_eq(RunState.hp, RunState.max_hp)
	assert_eq(RunState.battles_in_run(), 1)


func test_demo_deck_is_the_starter_plus_the_showcase_cards() -> void:
	RunState.new_demo(9)
	var extra: Array = GameData.rule("demo.extra_cards", [])
	assert_gt(extra.size(), 0)
	assert_eq(RunState.deck.size(), (GameData.rule("starter_deck", []) as Array).size() + extra.size())
	for id: Variant in extra:
		assert_true(RunState.deck.has(str(id)))


func test_beating_the_queen_in_the_demo_goes_to_the_win_ending() -> void:
	RunState.new_demo(9)
	RunState.record_win("queen_of_hearts")
	assert_true(RunState.outcome["won"])
	assert_eq(RunState.scene_after_battle(), RunState.ENDING_SCENE)


func test_a_demo_leaves_a_saved_run_alone() -> void:
	RunState.new_run(4242)
	RunState.record_win(RunState.current_enemy_id())
	RunState.save()
	RunState.new_demo(9)
	RunState.record_loss("queen_of_hearts")
	RunState.end_run()
	assert_true(RunState.has_save(), "the real run is still there")
	assert_true(RunState.load_saved())
	assert_eq(RunState.run_seed, 4242)
	assert_false(RunState.is_demo)
	assert_eq(RunState.battles_won, 1)


func test_a_new_run_is_not_a_demo() -> void:
	RunState.new_demo(9)
	RunState.new_run(10)
	assert_false(RunState.is_demo)
	assert_eq(RunState.battles_in_run(), RunState.total_battles())
