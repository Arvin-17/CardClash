extends GutTest
## Alice's built deck and hand: draw 3, 2 plays per round, carry-over up to 5.

const STARTER := ["num_1", "num_1", "num_2", "num_2", "num_3", "num_3", "drink_me", "drink_me", "teacup", "eat_me"]


func test_starter_deck_has_ten_cards() -> void:
	var deck := PlayerDeck.new(STARTER, TestHelpers.card_defs(), TestHelpers.rng())
	assert_eq(deck.count(), 10)


func test_unknown_ids_are_skipped() -> void:
	var deck := PlayerDeck.new(["num_1", "not_a_card"], TestHelpers.card_defs(), TestHelpers.rng())
	assert_eq(deck.count(), 1)


func test_discard_recycles_into_the_draw_pile() -> void:
	var deck := PlayerDeck.new(["num_1", "num_2"], TestHelpers.card_defs(), TestHelpers.rng())
	deck.discard(deck.draw())
	deck.discard(deck.draw())
	assert_eq(deck.draw_pile.size(), 0)
	assert_not_null(deck.draw(), "empty draw pile reshuffles the discard")


func test_bury_top_moves_the_top_card_to_the_bottom() -> void:
	var deck := PlayerDeck.new(STARTER, TestHelpers.card_defs(), TestHelpers.rng())
	var top := deck.top()
	deck.bury_top()
	assert_eq(deck.draw_pile[0], top)
	assert_ne(deck.top(), top)


func test_round_draws_the_hand_up_to_three() -> void:
	var b := TestHelpers.battle("club_soldier", STARTER)
	b.start_round()
	assert_eq(b.hand.size(), 3)
	assert_eq(b.plays_per_round, 2, "rules.json: 2 hand cards per round")
	assert_eq(b.cards_played, 0)


func test_a_limit_of_zero_means_no_limit() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["num_1", "num_1", "num_1", "num_2"])
	b.plays_per_round = 0
	TestHelpers.set_table(b.player, ["5", "4"])
	for _i in 4:
		assert_true(b.play_card(0))
	assert_eq(b.hand.size(), 0)
	assert_eq(b.player.total(), 14)


func test_unplayed_cards_carry_over_and_the_hand_caps_at_five() -> void:
	var b := TestHelpers.battle("club_soldier", STARTER)
	b.start_round()
	b.start_round()
	assert_eq(b.hand.size(), 3, "3 carried over, nothing new to draw")
	b.draw_cards(5)
	assert_eq(b.hand.size(), 5, "never more than 5")


func test_two_hand_cards_per_round_and_the_next_round_resets_the_count() -> void:
	var b := TestHelpers.battle("club_soldier", ["num_1", "num_1", "num_1", "num_1", "num_1", "num_1"])
	b.start_round()
	TestHelpers.set_table(b.player, ["5", "4"])
	assert_true(b.play_card(0))
	assert_true(b.play_card(0))
	assert_eq(b.cards_played, 2)
	assert_true(b.at_play_limit())
	assert_false(b.can_play(0), "a third card in one round is refused")
	assert_false(b.play_card(0))
	assert_eq(b.hand.size(), 1, "the refused card stays in your hand")
	b.start_round()
	assert_eq(b.cards_played, 0, "a new round resets the counter")
	assert_false(b.at_play_limit())
	assert_true(b.can_play(0))


func test_hand_cards_still_play_after_ready() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["num_2"])
	TestHelpers.set_table(b.player, ["5", "4"])
	b.player_stay()
	assert_true(b.can_play(0), "ready only stops drawing")
	assert_true(b.play_card(0))
	assert_eq(b.player.total(), 11)


func test_number_card_adds_to_your_total_and_stays_on_the_table() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["num_3"])
	TestHelpers.set_table(b.player, ["10", "5"])
	watch_signals(b)
	assert_true(b.play_card(0))
	assert_eq(b.player.total(), 18)
	assert_eq(b.player.table.size(), 3)
	assert_signal_emitted(b, "card_played")
	assert_eq(b.player_deck.discard_pile.size(), 0, "numbers are discarded when the round ends")


func test_played_effect_cards_go_to_the_discard_pile() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["teacup"])
	b.start_round()
	b.play_card(TestHelpers.hand_index(b, "teacup"))
	assert_eq(b.player_deck.discard_pile.size(), 1)
