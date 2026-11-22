extends CardEffect
## Cheshire Cat, the Grin: he fades away and takes your total with him. For the rest of the
## round your total shows as ??, so you have to count your own cards.


func apply(battle: BattleState, _params: Dictionary) -> void:
	battle.total_hidden_from_player = true
	battle.emit_total_changed(battle.player)
	battle.message.emit("Your total vanished! Count your cards yourself.")
