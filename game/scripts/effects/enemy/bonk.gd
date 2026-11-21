extends CardEffect
## Bonk: a card worth `amount` lands on your side of the table and changes your total.
## Spade Soldier +1, Club Soldier +2, Diamond Soldier -5 (enemies.json surprise_params).


func apply(battle: BattleState, params: Dictionary) -> void:
	var amount := int(params.get("amount", 2))
	battle.add_table_card(battle.player, Card.pseudo("bonk", amount))
	if amount >= 0:
		battle.message.emit("+%d to your total!" % amount)
	else:
		battle.message.emit("%d off your total!" % -amount)
