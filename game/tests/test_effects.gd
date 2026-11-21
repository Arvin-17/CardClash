extends GutTest
## Each starter effect: before and after state for one battle.


func test_drink_me_shrinks_your_last_card_by_3() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["drink_me"])
	TestHelpers.set_table(b.player, ["10", "9"])
	assert_eq(b.player.total(), 19)
	assert_true(b.play_card(0))
	assert_eq(b.player.total(), 16)
	assert_eq(b.player.last_table_card().modifier, -3)


func test_eat_me_grows_your_last_card_by_3() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["eat_me"])
	TestHelpers.set_table(b.player, ["10", "5"])
	assert_true(b.play_card(0))
	assert_eq(b.player.total(), 18)


func test_eat_me_can_bust_you() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["eat_me"])
	TestHelpers.set_table(b.player, ["10", "9"])
	b.play_card(0)
	assert_eq(b.player.total(), 22)
	assert_true(b.player.stayed, "busting ends your turn")


func test_modify_value_needs_a_table_card() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["drink_me"])
	assert_false(b.can_play(0), "greyed out with an empty table")


func test_mushroom_defaults_to_helping_you() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["mushroom", "mushroom"])
	TestHelpers.set_table(b.player, ["10", "7"])
	b.play_card(0)
	assert_eq(b.player.total(), 19, "+2 when it doesn't bust you")
	TestHelpers.set_table(b.player, ["10", "10"])
	b.play_card(0)
	assert_eq(b.player.total(), 18, "-2 when +2 would bust you")


func test_mushroom_can_target_the_enemy() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["mushroom"])
	TestHelpers.set_table(b.player, ["10", "7"])
	TestHelpers.set_table(b.enemy, ["10", "10"])
	b.play_card(0, {"owner": "enemy", "index": 1, "dir": 1})
	assert_eq(b.enemy.total(), 22)


func test_teacup_peeks_the_next_blind_card() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["teacup"])
	b.play_card(0)
	assert_not_null(b.peeked_card)
	var next := b.peeked_card
	b.player_hit()
	assert_eq(b.player.last_table_card(), next, "the peeked card is the one you draw")


func test_pocket_watch_asks_for_a_timer_freeze() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["pocket_watch"])
	watch_signals(b)
	b.play_card(0)
	assert_signal_emitted_with_parameters(b, "timer_freeze_requested", [5.0])


func test_white_rabbit_discards_the_hand_and_draws_three() -> void:
	var deck := ["num_1", "num_2", "num_3", "num_1", "num_2", "num_3"]
	var b := TestHelpers.battle("club_soldier", deck, ["white_rabbit", "teacup", "eat_me"])
	var old_cards := b.hand.slice(1)
	b.play_card(0)
	assert_eq(b.hand.size(), 3)
	for c: Card in old_cards:
		assert_false(b.hand.has(c), "old hand was discarded")
	assert_true(b.player_deck.discard_pile.size() >= 3, "white rabbit + the two old cards")


func test_every_card_in_cards_json_has_an_effect_script() -> void:
	for id: String in TestHelpers.card_defs():
		var def: Dictionary = TestHelpers.card_defs()[id]
		var effect_name := str(def["effect"])
		assert_not_null(EffectRegistry.card_effect(effect_name), "missing script for %s" % effect_name)
