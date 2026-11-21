extends Node
## One seeded RandomNumberGenerator for the whole game.
## Every shuffle and AI roll goes through it (never randf()), so any run can be
## replayed from its seed: needed for the daily run and for bug reports.

var rng := RandomNumberGenerator.new()
var current_seed: int = 0


func set_seed(value: int) -> void:
	current_seed = value
	rng.seed = value


## A fresh seed for a normal run. Kept under 2^31 so it matches the backend's daily seeds.
func new_seed() -> int:
	var picker := RandomNumberGenerator.new()
	picker.randomize()
	return picker.randi_range(0, 2147483646)
