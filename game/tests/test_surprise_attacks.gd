extends GutTest
## Every suit soldier's surprise attack.

const DECK := ["num_1", "num_2", "num_3", "drink_me", "teacup", "eat_me"]


## Dig and Pilfer are the Queen's tricks now; test them on a stand-in soldier.
func _soldier_with(kind: String, deck: Array = [], hand: Array = []) -> BattleState:
	var b := TestHelpers.battle("spade_soldier", deck, hand)
	b.enemy_def = b.enemy_def.duplicate(true)
	b.enemy_def["surprise"] = kind
	b.enemy_def["surprise_params"] = {}
	return b


func test_spade_attack_adds_1_to_your_total() -> void:
	var b := TestHelpers.battle("spade_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "6"])
	b.fire_surprise()
	assert_eq(b.player.total(), 17)


func test_diamond_attack_takes_5_off_your_total() -> void:
	var b := TestHelpers.battle("diamond_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "6"])
	var said: Array[String] = []
	b.message.connect(func(text: String) -> void: said.append(text))
	b.fire_surprise()
	assert_eq(b.player.total(), 11, "the -5 isn't clamped to 0")
	assert_eq(said, ["5 off your total!"] as Array[String])


func test_diamond_attack_can_pull_you_back_from_a_bust() -> void:
	var b := TestHelpers.battle("diamond_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "9", "5"])
	b.fire_surprise()
	assert_eq(b.player.total(), 19)


func test_real_cards_still_never_go_below_zero() -> void:
	var c := Card.blind("2", "spades")
	c.modifier = -3
	assert_eq(c.value(), 0)


func test_dig_buries_the_top_of_your_deck() -> void:
	var b := _soldier_with("dig", DECK)
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


func test_pilfer_steals_a_hand_card() -> void:
	var b := _soldier_with("pilfer", [], ["num_1", "teacup", "eat_me"])
	assert_eq(b.fire_surprise(), "pilfer")
	assert_eq(b.hand.size(), 2)
	assert_eq(b.stolen.size(), 1)


func test_pilfer_with_an_empty_hand_does_nothing() -> void:
	var b := _soldier_with("pilfer")
	b.fire_surprise()
	assert_eq(b.stolen.size(), 0)


func test_heart_off_with_it_removes_your_last_card() -> void:
	var b := TestHelpers.battle("heart_soldier", DECK)
	TestHelpers.set_table(b.player, ["10", "5", "4"])
	assert_eq(b.fire_surprise(), "off_with_it")
	assert_eq(b.player.table.size(), 2)
	assert_eq(b.player.total(), 15)
	assert_eq(b.hit_deck.discard_pile.size(), 1)


func test_heart_soldier_heals_1_when_it_wins_a_round() -> void:
	var b := TestHelpers.battle("heart_soldier", DECK)
	b.enemy.hp = 10
	TestHelpers.set_table(b.player, ["10", "7"])
	TestHelpers.set_table(b.enemy, ["10", "9"])
	b.resolve_round()
	assert_eq(b.enemy.hp, 11)


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


func test_attack_messages_never_name_the_attack() -> void:
	var names := ["dig", "bonk", "pilfer", "off with it", "off with its head", "off_with"]
	for id: String in ["spade_soldier", "club_soldier", "diamond_soldier", "heart_soldier", "queen_of_hearts"]:
		var b := TestHelpers.battle(id, DECK, ["num_1", "teacup"])
		TestHelpers.set_table(b.player, ["10", "5"])
		var said: Array[String] = []
		b.message.connect(func(text: String) -> void: said.append(text.to_lower()))
		for _i in 4:
			b.fire_surprise()
		assert_gt(said.size(), 0, "%s's attacks still say what happened" % id)
		for text: String in said:
			for attack_name: String in names:
				assert_false(text.contains(attack_name), "%s said '%s'" % [id, text])


func test_every_surprise_in_enemies_json_has_a_script() -> void:
	for e: Dictionary in GameData.read_json("enemies.json")["enemies"]:
		var kinds: Array = [e["surprise"]]
		if e["surprise"] == "queen_rotation":
			kinds = e["surprise_params"]["pattern"]
		for kind: String in kinds:
			assert_not_null(EffectRegistry.enemy_effect(kind), "missing script for %s" % kind)
