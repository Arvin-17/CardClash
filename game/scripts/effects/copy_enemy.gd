extends CardEffect
## Looking Glass: add a copy of the enemy's last table card to your total.


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return battle.enemy.last_table_card() != null


func apply(battle: BattleState, _params: Dictionary) -> void:
	var original := battle.enemy.last_table_card()
	if original == null:
		return
	var copy := original.clone()
	copy.id = "looking_glass"
	copy.def = {}
	battle.add_table_card(battle.player, copy)
