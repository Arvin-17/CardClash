extends CardEffect
## Hedgehog Shield: block the next surprise attack.


func apply(battle: BattleState, params: Dictionary) -> void:
	battle.shield += int(params.get("charges", 1))
	battle.message.emit("A hedgehog curls up in front of you.")
