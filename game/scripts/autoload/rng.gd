extends Node
## One seeded RandomNumberGenerator for the whole game.
## Every shuffle and AI roll goes through it (never randf()), so any run can be
## replayed from its seed: needed for bug reports and balance testing.

var rng := RandomNumberGenerator.new()
var current_seed: int = 0


func set_seed(value: int) -> void:
	current_seed = value
	rng.seed = value


## A fresh seed for a normal run, kept under 2^31.
func new_seed() -> int:
	var picker := RandomNumberGenerator.new()
	picker.randomize()
	return picker.randi_range(0, 2147483646)
