extends GutTest
## The reward pool's effects (before and after state for one battle) and the trinkets.


func test_looking_glass_copies_the_enemys_last_card() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["looking_glass"])
	TestHelpers.set_table(b.player, ["10", "2"])
	TestHelpers.set_table(b.enemy, ["9", "7"])
	assert_true(b.play_card(0))
	assert_eq(b.player.total(), 19)
	assert_eq(b.enemy.total(), 16, "the enemy keeps its card")


func test_looking_glass_needs_an_enemy_card() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["looking_glass"])
	assert_false(b.can_play(0))


func test_painted_rose_adds_the_chosen_value() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["painted_rose"])
	TestHelpers.set_table(b.player, ["10", "5"])
	b.play_card(0, {"value": 4})
	assert_eq(b.player.total(), 19)


func test_painted_rose_defaults_to_the_best_fit_within_1_to_5() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["painted_rose", "painted_rose"])
	TestHelpers.set_table(b.player, ["10", "8"])
	b.play_card(0)
	assert_eq(b.player.total(), 21, "needs 3")
	TestHelpers.set_table(b.player, ["5", "4"])
	b.play_card(0)
	assert_eq(b.player.total(), 14, "capped at 5")


func test_croquet_swing_removes_your_last_card() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["croquet_swing"])
	TestHelpers.set_table(b.player, ["10", "9", "8"])
	b.play_card(0)
	assert_eq(b.player.total(), 19)
	assert_eq(b.hit_deck.discard_pile.size(), 1)


func test_croquet_swing_lowers_your_total() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["croquet_swing"])
	TestHelpers.set_table(b.player, ["10", "5"])
	assert_true(b.play_card(0))
	assert_eq(b.player.total(), 10)


func test_hedgehog_shield_adds_a_block() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["hedgehog_shield"])
	b.play_card(0)
	assert_eq(b.shield, 1)


func test_caterpillar_smoke_hides_your_total_for_the_round() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["caterpillar_smoke"])
	b.play_card(0)
	assert_true(b.hide_total)
	b.start_round()
	assert_false(b.hide_total, "only this round")


func test_vorpal_blade_makes_a_win_critical() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["vorpal_blade"])
	b.play_card(0)
	TestHelpers.set_table(b.player, ["10", "9"])
	TestHelpers.set_table(b.enemy, ["10", "7"])
	var r := b.resolve_round()
	assert_true(r["critical"])
	assert_eq(r["damage"], (2 + 3) * 2)


func test_tweedle_twins_copy_your_last_card() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["tweedle_twins"])
	TestHelpers.set_table(b.player, ["5", "4"])
	b.play_card(0)
	assert_eq(b.player.total(), 13)
	assert_eq(b.player.table.size(), 3)


func test_unbirthday_gift_heals_6() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["unbirthday_gift"])
	b.player.hp = 20
	b.play_card(0)
	assert_eq(b.player.hp, 26)


func test_unbirthday_gift_is_greyed_out_at_full_hp() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["unbirthday_gift"])
	assert_false(b.can_play(0))


func test_rabbits_watch_caps_your_first_hit_at_5() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.setup_trinkets([GameData.trinkets["rabbits_watch"]])
	b.start_round()
	var first := b.player_hit()
	assert_true(first.value() <= 5, "first hit capped at 5, got %d" % first.value())
	var second := b.player_hit()
	if second != null:
		assert_eq(second.modifier, 0, "only the first hit")


func test_hatters_hat_adds_2_damage_to_wins() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.setup_trinkets([GameData.trinkets["hatters_hat"]])
	TestHelpers.set_table(b.player, ["10", "10"])
	TestHelpers.set_table(b.enemy, ["10", "7"])
	assert_eq(b.resolve_round()["damage"], 3 + 3 + 2)


func test_cheshire_grin_sometimes_ignores_attacks() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.setup_trinkets([GameData.trinkets["cheshire_grin"]])
	watch_signals(b)
	for i in 40:
		b.fire_surprise()
	var blocked: int = get_signal_emit_count(b, "surprise_blocked")
	assert_between(blocked, 2, 25, "roughly a quarter of 40")


func test_trinket_is_awarded_after_the_second_soldier() -> void:
	RunState.new_run(5)
	RunState.record_win(RunState.current_enemy_id())
	assert_eq(RunState.trinkets.size(), 0)
	RunState.record_win(RunState.current_enemy_id())
	assert_eq(RunState.trinkets.size(), 1)
	assert_eq(RunState.last_trinket, RunState.trinkets[0])
	assert_true(GameData.trinkets.has(RunState.last_trinket))
	RunState.end_run()
