extends CardEffect
## Unbirthday Gift: heal 6 HP.


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return battle.player.hp < battle.player.max_hp


func apply(battle: BattleState, params: Dictionary) -> void:
	battle.player.heal(int(params.get("amount", 6)))
	battle.hp_changed.emit("player", battle.player.hp, battle.player.max_hp)
