extends GutTest
## Totals and the ace rule (cases from the guide).


func _cards(ranks: Array) -> Array:
	var out: Array = []
	for r: String in ranks:
		out.append(Card.blind(r, "spades"))
	return out


func test_ace_king_is_21() -> void:
	assert_eq(Rules.total(_cards(["A", "K"])), 21)


func test_two_aces_and_a_nine_is_21() -> void:
	assert_eq(Rules.total(_cards(["A", "A", "9"])), 21)


func test_ace_nine_five_is_15() -> void:
	assert_eq(Rules.total(_cards(["A", "9", "5"])), 15)


func test_ten_nine_five_is_24_and_busts() -> void:
	var t := Rules.total(_cards(["10", "9", "5"]))
	assert_eq(t, 24)
	assert_true(Rules.is_bust(t))


func test_faces_count_ten() -> void:
	assert_eq(Rules.total(_cards(["J", "Q"])), 20)
	assert_eq(Rules.total(_cards(["K", "7"])), 17)


func test_modifier_changes_a_card() -> void:
	var cards := _cards(["10", "8"])
	var last: Card = cards[1]
	last.modifier = -3
	assert_eq(last.value(), 5)
	assert_eq(Rules.total(cards), 15)


func test_card_value_never_goes_negative() -> void:
	var c := Card.blind("2", "hearts")
	c.modifier = -5
	assert_eq(c.value(), 0)


func test_totals_are_recomputed_not_stored() -> void:
	var cards := _cards(["A", "6"])
	assert_eq(Rules.total(cards), 17)
	cards.append(Card.blind("9", "clubs"))
	assert_eq(Rules.total(cards), 16)


func test_built_deck_number_card_uses_its_value() -> void:
	var c := Card.from_def({"id": "num_3", "type": "number", "value": 3})
	assert_eq(c.value(), 3)
	assert_true(c.is_number())
