extends GutTest
## The word that pops when an attack lands: what it did, with the real amount, never its name.

const BATTLE_UI := preload("res://scripts/ui/battle_ui.gd")


func test_attack_words_say_what_happened_with_the_real_amount() -> void:
	assert_eq(BATTLE_UI.attack_word("bonk", {"amount": 1}), "+1!")
	assert_eq(BATTLE_UI.attack_word("bonk", {"amount": -5}), "-5!")
	assert_eq(BATTLE_UI.attack_word("off_with_it", {}), "CARD LOST!")


func test_attack_words_never_name_the_attack() -> void:
	for kind: String in ["bonk", "dig", "pilfer", "off_with_it", "off_with_its_head", "move_down", "grin"]:
		var word := BATTLE_UI.attack_word(kind, {"amount": 2}).to_lower()
		for attack_name: String in ["bonk", "dig", "pilfer", "off with", "move down", "grin"]:
			assert_false(word.contains(attack_name), "%s pops '%s'" % [kind, word])
