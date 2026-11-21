extends CardEffect
## Tweedle Twins: copy your last table card.


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return battle.player.last_table_card() != null


func apply(battle: BattleState, _params: Dictionary) -> void:
	var original := battle.player.last_table_card()
	if original == null:
		return
	var twin := original.clone()
	twin.id = "tweedle_twins"
	twin.def = {}
	battle.add_table_card(battle.player, twin)
