extends GutTest
## Every suit soldier's surprise attack.

const DECK := ["num_1", "num_2", "num_3", "drink_me", "teacup", "eat_me"]


func test_spade_dig_buries_the_top_of_your_deck() -> void:
	var b := TestHelpers.battle("spade_soldier", DECK)
	var top := b.player_deck.top()
	assert_eq(b.fire_surprise(), "dig")
	assert_eq(b.player_deck.draw_pile[0], top)


func test_club_bonk_adds_2_to_your_total() -> void:
	var b := TestHelpers.battle("club_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "6"])
	watch_signals(b)
	assert_eq(b.fire_surprise(), "bonk")
	assert_eq(b.player.total(), 18)
	assert_signal_emitted_with_parameters(b, "surprise_attack", ["club_soldier", "bonk"])


func test_bonk_can_bust_you_even_after_staying() -> void:
	var b := TestHelpers.battle("club_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "10"])
	b.player_stay()
	b.fire_surprise()
	assert_eq(b.player.total(), 22)


func test_diamond_pilfer_steals_a_hand_card() -> void:
	var b := TestHelpers.battle("diamond_soldier", [], ["num_1", "teacup", "eat_me"])
	assert_eq(b.fire_surprise(), "pilfer")
	assert_eq(b.hand.size(), 2)
	assert_eq(b.stolen.size(), 1)


func test_pilfer_with_an_empty_hand_does_nothing() -> void:
	var b := TestHelpers.battle("diamond_soldier")
	b.fire_surprise()
	assert_eq(b.stolen.size(), 0)


func test_heart_off_with_it_removes_your_last_card() -> void:
	var b := TestHelpers.battle("heart_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "5", "4"])
	assert_eq(b.fire_surprise(), "off_with_it")
	assert_eq(b.player.table.size(), 2)
	assert_eq(b.player.total(), 15)
	assert_eq(b.hit_deck.discard_pile.size(), 1)


func test_heart_soldier_heals_3_when_it_wins_a_round() -> void:
	var b := TestHelpers.battle("heart_soldier", DECK)
	b.enemy.hp = 10
	TestHelpers.set_table(b.player, ["10", "7"])
	TestHelpers.set_table(b.enemy, ["10", "9"])
	b.resolve_round()
	assert_eq(b.enemy.hp, 13)


func test_hedgehog_shield_blocks_the_next_attack() -> void:
	var b := TestHelpers.battle("club_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "6"])
	b.shield = 1
	watch_signals(b)
	b.fire_surprise()
	assert_eq(b.player.total(), 16)
	assert_eq(b.shield, 0)
	assert_signal_emitted(b, "surprise_blocked")
	b.fire_surprise()
	assert_eq(b.player.total(), 18, "only one block per charge")


func test_every_surprise_in_enemies_json_has_a_script() -> void:
	for e: Dictionary in GameData.read_json("enemies.json")["enemies"]:
		var kinds: Array = [e["surprise"]]
		if e["surprise"] == "queen_rotation":
			kinds = e["surprise_params"]["pattern"]
		for kind: String in kinds:
			assert_not_null(EffectRegistry.enemy_effect(kind), "missing script for %s" % kind)
