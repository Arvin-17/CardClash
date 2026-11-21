extends CardEffect
## Painted Rose: choose 1 to 5 when played (choice key "value").
## With no choice, it picks the value that gets closest to 21 without busting.


func apply(battle: BattleState, params: Dictionary) -> void:
	var lo := int(params.get("min", 1))
	var hi := int(params.get("max", 5))
	var value := int(params.get("value", 0))
	if value == 0:
		value = battle.target - battle.player.total(battle.target)
	battle.add_table_card(battle.player, Card.pseudo("painted_rose", clampi(value, lo, hi)))
