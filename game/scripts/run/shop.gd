class_name Shop
extends RefCounted
## The shop after each win: buy offered cards and remove deck cards with gold.
## Prices, removal cost and the minimum deck size come from rules.json "shop".


static func card_price(card_def: Dictionary, shop_rules: Dictionary) -> int:
	var prices: Dictionary = shop_rules.get("prices", {})
	return int(prices.get(str(card_def.get("rarity", "common")), 10))


static func remove_price(shop_rules: Dictionary) -> int:
	return int(shop_rules.get("remove_price", 5))


static func min_deck(shop_rules: Dictionary) -> int:
	return int(shop_rules.get("min_deck", 6))


## The deck grouped for display: [{"id", "count", "index"}] in first-seen order,
## where "index" is the deck position a removal takes (the last copy).
static func grouped(deck: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var at := {}
	for i in deck.size():
		var id := str(deck[i])
		if at.has(id):
			var g: Dictionary = out[at[id]]
			g["count"] = int(g["count"]) + 1
			g["index"] = i
		else:
			at[id] = out.size()
			out.append({"id": id, "count": 1, "index": i})
	return out
