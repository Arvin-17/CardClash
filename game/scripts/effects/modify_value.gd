extends CardEffect
## Drink Me (-3) and Eat Me (+3): change your last table card.
## Mushroom (target "choose", either_sign): any table card +2 or -2, your choice.
## Choice keys: owner ("player" | "enemy"), index, dir (+1 | -1).


func can_play(battle: BattleState, params: Dictionary) -> bool:
	if str(params.get("target", "own_last")) == "choose":
		return not (battle.player.table.is_empty() and battle.enemy.table.is_empty())
	return battle.player.last_table_card() != null


func apply(battle: BattleState, params: Dictionary) -> void:
	var amount := int(params.get("amount", 0))
	var who: Combatant = battle.player
	var card: Card = null
	if str(params.get("target", "own_last")) == "choose":
		who = battle.enemy if str(params.get("owner", "player")) == "enemy" else battle.player
		if who.table.is_empty():
			who = battle.enemy if who == battle.player else battle.player
		var index := int(params.get("index", who.table.size() - 1))
		card = who.table[clampi(index, 0, who.table.size() - 1)]
		if bool(params.get("either_sign", false)):
			var dir := int(params.get("dir", 0))
			if dir == 0:
				dir = _default_dir(battle, who, amount)
			amount = absi(amount) * (1 if dir > 0 else -1)
	else:
		card = who.last_table_card()
	if card == null:
		return
	card.modifier += amount
	battle.emit_total_changed(who)


## With no explicit choice: get Alice closer to 21 without busting, or push the enemy toward a bust.
func _default_dir(battle: BattleState, who: Combatant, amount: int) -> int:
	if who == battle.player:
		return 1 if who.total(battle.target) + absi(amount) <= battle.target else -1
	return 1
