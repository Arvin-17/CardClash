extends CardEffect
## Spade Soldier, Dig: buries the top card of your built deck (it goes to the bottom).


func apply(battle: BattleState, _params: Dictionary) -> void:
	if battle.player_deck == null:
		return
	var buried := battle.player_deck.bury_top()
	if buried != null:
		battle.message.emit("Your %s was buried in your deck!" % buried.display_name())
