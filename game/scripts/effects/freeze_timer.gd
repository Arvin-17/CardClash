extends CardEffect
## Pocket Watch: pause the round timer (the controller owns the Timer node).


func apply(battle: BattleState, params: Dictionary) -> void:
	battle.request_timer_freeze(float(params.get("seconds", 5)))
