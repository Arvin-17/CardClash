extends CardEffect
## Caterpillar Smoke: the enemy can't see your total this round (its AI plays blind).


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return not battle.hide_total


func apply(battle: BattleState, _params: Dictionary) -> void:
	battle.hide_total = true
	battle.message.emit("Smoke rings hide your hand.")
