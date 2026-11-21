extends CardEffect
## Number cards (1-4): play onto your table, adding their value to your total.


func apply(battle: BattleState, params: Dictionary) -> void:
	var card: Card = params.get("_card")
	if card != null:
		battle.add_table_card(battle.player, card)
