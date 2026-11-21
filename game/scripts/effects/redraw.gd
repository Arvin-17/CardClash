extends CardEffect
## White Rabbit: discard your hand, draw 3.


func apply(battle: BattleState, params: Dictionary) -> void:
	for card: Card in battle.hand:
		battle.player_deck.discard(card)
	battle.hand.clear()
	battle.draw_cards(int(params.get("count", 3)))
