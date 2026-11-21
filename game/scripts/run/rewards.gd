class_name Rewards
extends RefCounted
## The reward screen's offer: 1 of 3 random cards from the reward pool,
## weighted by rarity (common 60%, uncommon 30%, rare 10% from rules.json).


## Up to `count` distinct reward-pool card ids.
static func roll(card_defs: Dictionary, weights: Dictionary, count: int, rng: RandomNumberGenerator) -> Array[String]:
	var by_rarity := {}
	for id: String in card_defs:
		var d: Dictionary = card_defs[id]
		if bool(d.get("pool", false)):
			var rarity := str(d.get("rarity", "common"))
			if not by_rarity.has(rarity):
				by_rarity[rarity] = []
			(by_rarity[rarity] as Array).append(id)
	for rarity: String in by_rarity:
		(by_rarity[rarity] as Array).sort()  # stable order so the seed decides
	var offer: Array[String] = []
	var guard := 0
	while offer.size() < count and guard < 200:
		guard += 1
		var rarity := _pick_rarity(weights, by_rarity, rng)
		if rarity.is_empty():
			break
		var options: Array = (by_rarity[rarity] as Array).filter(func(id: String) -> bool: return not offer.has(id))
		if options.is_empty():
			continue
		offer.append(str(options[rng.randi_range(0, options.size() - 1)]))
	return offer


static func _pick_rarity(weights: Dictionary, by_rarity: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for rarity: String in weights:
		if by_rarity.has(rarity):
			total += float(weights[rarity])
	if total <= 0.0:
		return ""
	var roll := rng.randf() * total
	var keys := weights.keys()
	keys.sort()
	for rarity: Variant in keys:
		if not by_rarity.has(rarity):
			continue
		roll -= float(weights[rarity])
		if roll < 0.0:
			return str(rarity)
	return str(keys.back())
