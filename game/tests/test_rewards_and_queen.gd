extends GutTest
## Reward offers and the Queen of Hearts.

const WEIGHTS := {"common": 60, "uncommon": 30, "rare": 10}


func test_reward_offer_is_three_distinct_pool_cards() -> void:
	var defs := TestHelpers.card_defs()
	var offer := Rewards.roll(defs, WEIGHTS, 3, TestHelpers.rng(3))
	assert_eq(offer.size(), 3)
	var seen := {}
	for id: String in offer:
		assert_true(bool(defs[id]["pool"]), "%s is in the reward pool" % id)
		seen[id] = true
	assert_eq(seen.size(), 3, "no duplicates in one offer")


func test_rarity_weights_are_respected() -> void:
	var defs := TestHelpers.card_defs()
	var rng := TestHelpers.rng(11)
	var counts := {"common": 0, "uncommon": 0, "rare": 0}
	for i in 400:
		var id: String = Rewards.roll(defs, WEIGHTS, 1, rng)[0]
		counts[defs[id]["rarity"]] += 1
	assert_gt(counts["common"], counts["uncommon"])
	assert_gt(counts["uncommon"], counts["rare"])
	assert_gt(counts["rare"], 0)


func test_same_seed_same_offer() -> void:
	var defs := TestHelpers.card_defs()
	assert_eq(Rewards.roll(defs, WEIGHTS, 3, TestHelpers.rng(9)), Rewards.roll(defs, WEIGHTS, 3, TestHelpers.rng(9)))


func test_queen_cycles_a_learnable_pattern() -> void:
	var b := TestHelpers.battle("queen_of_hearts", ["num_1", "num_2", "num_3"], ["teacup"])
	TestHelpers.set_table(b.player, ["10", "5"])
	var kinds: Array = []
	for i in 5:
		kinds.append(b.fire_surprise())
	assert_eq(kinds, ["bonk", "pilfer", "off_with_its_head", "dig", "bonk"])


func test_off_with_its_head_takes_your_highest_card() -> void:
	var b := TestHelpers.battle("queen_of_hearts")
	b.surprise_count = 2
	TestHelpers.set_table(b.player, ["4", "K", "6"])
	assert_eq(b.fire_surprise(), "off_with_its_head")
	assert_eq(b.player.total(), 10)


func test_queen_enrages_below_half_hp() -> void:
	var b := TestHelpers.battle("queen_of_hearts")
	assert_eq(b.intent_seconds(), 6.0)
	assert_eq(b.enemy_stay_at, 18)
	watch_signals(b)
	b.enemy.hp = 31
	TestHelpers.set_table(b.player, ["10", "10"])
	TestHelpers.set_table(b.enemy, ["10", "8"])
	b.resolve_round()
	assert_eq(b.enemy.hp, 31 - 5, "26/50: still at or above half")
	assert_eq(b.phase, 1)
	b.resolve_round()
	assert_eq(b.phase, 2)
	assert_eq(b.enemy_stay_at, 19)
	assert_eq(b.intent_seconds(), 4.0)
	assert_signal_emitted_with_parameters(b, "boss_phase_changed", [2])


func test_soldiers_never_enrage() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.enemy.hp = 1
	TestHelpers.set_table(b.player, ["10", "9"])
	TestHelpers.set_table(b.enemy, ["10", "8"])
	b.resolve_round()
	assert_eq(b.phase, 1)
