extends GutTest
## The shared blind deck: 52 cards, seeded shuffles, card counting.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _order(deck: HitDeck) -> Array:
	var out: Array = []
	for c: Card in deck.draw_pile:
		out.append(c.rank + c.suit)
	return out


func test_standard_52() -> void:
	var deck := HitDeck.new(_rng(1))
	assert_eq(deck.remaining(), 52)
	var counts := deck.remaining_by_value()
	assert_eq(counts[10], 16, "10, J, Q, K")
	assert_eq(counts[11], 4, "aces")
	assert_eq(counts[2], 4)


func test_same_seed_gives_the_same_shuffle_twice() -> void:
	assert_eq(_order(HitDeck.new(_rng(1234))), _order(HitDeck.new(_rng(1234))))


func test_different_seeds_shuffle_differently() -> void:
	assert_ne(_order(HitDeck.new(_rng(1))), _order(HitDeck.new(_rng(2))))


func test_draw_and_count() -> void:
	var deck := HitDeck.new(_rng(7))
	var top := deck.peek()
	var drawn := deck.draw()
	assert_eq(drawn, top, "peek shows the next card")
	assert_eq(deck.remaining(), 51)
	var counts := deck.remaining_by_value()
	var total := 0
	for v: int in counts:
		total += int(counts[v])
	assert_eq(total, 51)


func test_discard_pile_recycles_when_empty() -> void:
	var deck := HitDeck.new(_rng(3))
	var drawn: Array = []
	for _i in 52:
		drawn.append(deck.draw())
	assert_eq(deck.remaining(), 0)
	deck.discard(drawn)
	assert_eq(deck.discard_pile.size(), 52)
	assert_not_null(deck.draw())
	assert_eq(deck.remaining(), 51)
