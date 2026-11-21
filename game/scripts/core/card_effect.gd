class_name CardEffect
extends RefCounted
## Base class for every card effect (scripts/effects/) and enemy surprise attack
## (scripts/effects/enemy/). Each one is a small script; `params` come from JSON,
## merged with the player's choice (e.g. which card, which sign).


## False greys the card out in the hand.
func can_play(_battle: BattleState, _params: Dictionary) -> bool:
	return true


func apply(_battle: BattleState, _params: Dictionary) -> void:
	pass
