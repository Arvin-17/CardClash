class_name Shuffle
extends RefCounted
## Seeded Fisher-Yates. Array.shuffle() uses the global RNG and would break replays.


static func shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp
