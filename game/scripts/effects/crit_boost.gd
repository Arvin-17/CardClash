extends CardEffect
## Vorpal Blade: win this round by any amount and it counts as a critical.


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return not battle.crit_boost


func apply(battle: BattleState, _params: Dictionary) -> void:
	battle.crit_boost = true
	battle.message.emit("Snicker-snack! Any win this round is a critical.")
