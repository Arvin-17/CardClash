extends CardEffect
## Club Soldier, Bonk: +2 to your total (a bonk card lands on your side of the table).


func apply(battle: BattleState, params: Dictionary) -> void:
	var amount := int(params.get("amount", 2))
	battle.add_table_card(battle.player, Card.pseudo("bonk", amount))
	battle.message.emit("BONK! +%d to your total." % amount)
