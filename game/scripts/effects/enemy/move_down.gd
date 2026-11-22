extends CardEffect
## Mad Hatter, "Move down!": everyone changes seats, so your table cards and his swap places.
## Whoever was ahead is now behind. The Hatter keeps playing with his new cards.


func apply(battle: BattleState, _params: Dictionary) -> void:
	var mine := battle.player.table.duplicate()
	battle.player.table = battle.enemy.table.duplicate()
	battle.enemy.table = mine
	battle.enemy.stayed = battle.enemy.is_bust(battle.target)
	battle.emit_total_changed(battle.player)
	battle.emit_total_changed(battle.enemy)
	battle.message.emit("Your cards and the enemy's cards were swapped!")
