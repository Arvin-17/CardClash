extends GutTest
## Round rules: playing on past a bust, the super bust at 30, Stand ending the round, Heal.

var rules: Dictionary = GameData.read_json("rules.json")


func test_a_card_can_bring_you_back_from_a_bust() -> void:
	var b := TestHelpers.battle("club_soldier", [], ["drink_me"])
	TestHelpers.set_table(b.player, ["10", "9", "5"])
	assert_true(b.player.is_bust())
	assert_true(b.play_card(0), "power cards still work over 21")
	assert_eq(b.player.total(), 21)
	assert_false(b.player.is_bust())


func test_29_is_a_normal_bust_and_30_is_a_super_bust() -> void:
	var b := TestHelpers.battle("club_soldier")
	TestHelpers.set_table(b.player, ["10", "10", "9"])
	assert_false(b.round_over(), "29: keep playing")
	TestHelpers.set_table(b.player, ["10", "10", "10"])
	assert_true(b.player_super_bust())
	assert_true(b.round_over(), "30 ends the round on the spot")
	assert_false(b.both_done())


func test_super_bust_doubles_the_damage() -> void:
	var normal := Rules.resolve(29, 18, 3, 4, rules)
	assert_eq(normal["kind"], "player_bust")
	assert_eq(normal["damage"], (29 - 21) + 4)
	var super_bust := Rules.resolve(30, 18, 3, 4, rules)
	assert_eq(super_bust["kind"], "super_bust")
	assert_eq(super_bust["loser"], "player")
	assert_eq(super_bust["damage"], ((30 - 21) + 4) * 2)


func test_super_bust_beats_a_messy_round() -> void:
	var r := Rules.resolve(31, 25, 3, 4, rules)
	assert_eq(r["kind"], "super_bust", "even if the enemy busted too")
	assert_eq(r["damage"], ((31 - 21) + 4) * 2)


func test_super_bust_lands_through_resolve_round() -> void:
	var b := TestHelpers.battle("club_soldier")
	TestHelpers.set_table(b.player, ["10", "10", "10"])
	TestHelpers.set_table(b.enemy, ["10", "7"])
	var r := b.resolve_round()
	assert_eq(r["kind"], "super_bust")
	assert_eq(b.player.hp, 30 - ((30 - 21) + 4) * 2)


func test_standing_freezes_the_enemy_and_compares_totals_now() -> void:
	var b := TestHelpers.battle("club_soldier", [], [], 9)
	b.start_round()
	TestHelpers.set_table(b.enemy, ["5", "4"])
	TestHelpers.set_table(b.player, ["10", "8"])
	b.player_stand()
	assert_true(b.round_over())
	assert_null(b.enemy_hit(), "the enemy can't add a card after you stand")
	assert_eq(b.enemy.total(), 9, "its cards are frozen")
	var r := b.resolve_round()
	assert_eq(r["winner"], "player", "18 beats the 9 it was caught on")
	assert_eq(r["damage"], (18 - 9) + 3)


func test_heal_action_restores_3_and_uses_a_card_play() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.plays_per_round = 2
	b.player.hp = 20
	assert_eq(b.heal_action(), 3)
	assert_eq(b.player.hp, 23)
	assert_eq(b.cards_played, 1)


func test_heal_never_overheals() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.player.hp = 29
	assert_eq(b.heal_action(), 1)
	assert_eq(b.player.hp, 30)
	assert_false(b.can_heal(), "full HP")
	assert_eq(b.heal_action(), 0)


func test_heal_respects_the_play_limit() -> void:
	var b := TestHelpers.battle("club_soldier")
	b.plays_per_round = 2
	b.cards_played = 2
	b.player.hp = 10
	assert_false(b.can_heal())
	assert_eq(b.heal_action(), 0)
	assert_eq(b.player.hp, 10)
