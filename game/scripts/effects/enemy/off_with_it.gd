extends CardEffect
## Heart Soldier, Mini "Off with it!": removes your last table card.


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return battle.player.last_table_card() != null


func apply(battle: BattleState, _params: Dictionary) -> void:
	var card := battle.player.last_table_card()
	if card != null:
		battle.remove_table_card(battle.player, card)
		battle.message.emit("OFF WITH IT! Your %s is gone." % card.face())
