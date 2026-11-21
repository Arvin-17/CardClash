extends CardEffect
## Teacup: peek at the next blind card.


func apply(battle: BattleState, _params: Dictionary) -> void:
	battle.peek_next()
