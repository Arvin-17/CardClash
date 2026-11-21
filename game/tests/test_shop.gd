extends GutTest
## The shop after each win: prices, buying, removing, and the screen itself.

const SHOP_SCENE := preload("res://scenes/reward.tscn")

var shop_rules: Dictionary = GameData.read_json("rules.json")["shop"]


func before_each() -> void:
	RunState.new_run(77)


func test_prices_follow_rarity() -> void:
	assert_eq(Shop.card_price({"rarity": "common"}, shop_rules), 10)
	assert_eq(Shop.card_price({"rarity": "uncommon"}, shop_rules), 15)
	assert_eq(Shop.card_price({"rarity": "rare"}, shop_rules), 25)
	assert_eq(Shop.remove_price(shop_rules), 5)
	assert_eq(Shop.min_deck(shop_rules), 6)


func test_a_soldier_win_pays_enough_for_several_changes() -> void:
	var gold := int(GameData.rule("run.gold_per_soldier", 0))
	assert_eq(gold, 20)
	assert_gt(gold, Shop.card_price({"rarity": "common"}, shop_rules) + Shop.remove_price(shop_rules), "a card and a removal")


func test_buying_spends_gold_and_adds_the_card() -> void:
	RunState.gold = 30
	var size := RunState.deck.size()
	assert_true(RunState.buy_card("num_4", 10))
	assert_true(RunState.buy_card("pocket_watch", 10))
	assert_eq(RunState.gold, 10)
	assert_eq(RunState.deck.size(), size + 2)
	assert_eq(RunState.deck.back(), "pocket_watch")


func test_cant_buy_what_you_cant_afford() -> void:
	RunState.gold = 9
	var size := RunState.deck.size()
	assert_false(RunState.buy_card("num_4", 10))
	assert_eq(RunState.gold, 9)
	assert_eq(RunState.deck.size(), size)


func test_removing_costs_gold_and_stops_at_the_minimum_deck() -> void:
	RunState.gold = 100
	var removed := 0
	while RunState.remove_card_for(0, 5, 6):
		removed += 1
	assert_eq(RunState.deck.size(), 6, "never below the minimum")
	assert_eq(RunState.gold, 100 - removed * 5)


func test_cant_remove_without_the_gold() -> void:
	RunState.gold = 4
	var size := RunState.deck.size()
	assert_false(RunState.remove_card_for(0, 5, 6))
	assert_eq(RunState.deck.size(), size)


func test_deck_groups_copies_and_removes_the_last_one() -> void:
	var g := Shop.grouped(["num_1", "drink_me", "num_1", "teacup"])
	assert_eq(g.size(), 3)
	assert_eq(g[0], {"id": "num_1", "count": 2, "index": 2})
	assert_eq(g[1], {"id": "drink_me", "count": 1, "index": 1})


func _open() -> Control:
	var shop: Control = SHOP_SCENE.instantiate()
	add_child_autofree(shop)
	await wait_frames(1)
	return shop


func test_shop_screen_buys_several_cards_in_one_visit() -> void:
	RunState.gold = 200
	var shop = await _open()
	var size := RunState.deck.size()
	for i in shop._offer.size():
		shop._buy(i)
	assert_eq(RunState.deck.size(), size + shop._offer.size(), "every offer bought, not just one")
	shop._buy(0)
	assert_eq(RunState.deck.size(), size + shop._offer.size(), "each offer sells once")
	assert_string_contains(shop._message.text, "ALREADY BOUGHT")


func test_shop_screen_shows_the_whole_deck_and_removes_on_the_second_click() -> void:
	RunState.gold = 50
	var shop = await _open()
	await wait_frames(1)
	var shown := 0
	for chip: Node in shop._deck_row.get_children():
		if not chip.is_queued_for_deletion():
			shown += 1
	assert_eq(shown, Shop.grouped(RunState.deck).size(), "one chip per distinct card")
	var size := RunState.deck.size()
	shop._deck_click("teacup")
	assert_eq(RunState.deck.size(), size, "the first click only asks")
	shop._deck_click("teacup")
	assert_eq(RunState.deck.size(), size - 1)
	assert_eq(RunState.gold, 45)
	assert_false(RunState.deck.has("teacup"))


func test_shop_screen_says_when_you_cant_afford_it() -> void:
	RunState.gold = 0
	var shop = await _open()
	var size := RunState.deck.size()
	shop._buy(0)
	assert_eq(RunState.deck.size(), size)
	assert_string_contains(shop._message.text, "NOT ENOUGH GOLD")
