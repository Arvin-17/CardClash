extends GutTest
## Every row of the damage table, including ties, both busting and exactly 21.
## Player base attack 3, enemy base attack 4 throughout.

const RULES := {"blackjack": 21, "damage": {"messy_round": 2, "critical_multiplier": 2, "tie_favors_player": false}}


func _resolve(pt: int, et: int, crit_boost: bool = false, bonus: int = 0) -> Dictionary:
	return Rules.resolve(pt, et, 3, 4, RULES, crit_boost, bonus)


func test_both_bust_is_a_messy_round() -> void:
	var r := _resolve(23, 25)
	assert_eq(r["kind"], "both_bust")
	assert_eq(r["winner"], "none")
	assert_eq(r["damage"], 0)
	assert_eq(r["messy_damage"], 2)


func test_you_bust_take_overflow_plus_enemy_attack() -> void:
	var r := _resolve(24, 18)
	assert_eq(r["kind"], "player_bust")
	assert_eq(r["loser"], "player")
	assert_eq(r["damage"], 3 + 4)


func test_enemy_busts_takes_overflow_plus_your_attack() -> void:
	var r := _resolve(18, 23)
	assert_eq(r["kind"], "enemy_bust")
	assert_eq(r["loser"], "enemy")
	assert_eq(r["damage"], 2 + 3)


func test_closer_to_21_wins_difference_plus_attack() -> void:
	var r := _resolve(20, 17)
	assert_eq(r["winner"], "player")
	assert_eq(r["damage"], 3 + 3)
	var r2 := _resolve(17, 20)
	assert_eq(r2["winner"], "enemy")
	assert_eq(r2["damage"], 3 + 4)


func test_exactly_21_is_critical() -> void:
	var r := _resolve(21, 18)
	assert_true(r["critical"])
	assert_eq(r["damage"], (3 + 3) * 2)
	var r2 := _resolve(19, 21)
	assert_true(r2["critical"])
	assert_eq(r2["damage"], (2 + 4) * 2)


func test_21_against_a_bust_is_critical_too() -> void:
	var r := _resolve(21, 24)
	assert_eq(r["kind"], "enemy_bust")
	assert_true(r["critical"])
	assert_eq(r["damage"], (3 + 3) * 2)


func test_tie_deals_no_damage() -> void:
	var r := _resolve(19, 19)
	assert_eq(r["kind"], "tie")
	assert_eq(r["damage"], 0)
	assert_eq(_resolve(21, 21)["damage"], 0)


func test_tie_can_favor_the_player_if_the_data_says_so() -> void:
	var rules := RULES.duplicate(true)
	rules["damage"]["tie_favors_player"] = true
	var r := Rules.resolve(18, 18, 3, 4, rules)
	assert_eq(r["winner"], "player")
	assert_eq(r["damage"], 3)


func test_vorpal_blade_makes_any_win_critical() -> void:
	var r := _resolve(20, 18, true)
	assert_true(r["critical"])
	assert_eq(r["damage"], (2 + 3) * 2)
	assert_false(_resolve(17, 20, true)["critical"])


func test_win_bonus_only_applies_to_player_wins() -> void:
	assert_eq(_resolve(20, 17, false, 2)["damage"], 3 + 3 + 2)
	assert_eq(_resolve(17, 20, false, 2)["damage"], 3 + 4)
