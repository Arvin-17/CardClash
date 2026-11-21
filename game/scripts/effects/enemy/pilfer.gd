extends CardEffect
## Diamond Soldier, Pilfer: steals a random card from your hand for the rest of the battle.


func can_play(battle: BattleState, _params: Dictionary) -> bool:
	return not battle.hand.is_empty()


func apply(battle: BattleState, _params: Dictionary) -> void:
	if battle.hand.is_empty():
		return
	var index := battle.rng.randi_range(0, battle.hand.size() - 1)
	var stolen: Card = battle.hand[index]
	battle.hand.remove_at(index)
	battle.stolen.append(stolen)
	battle.hand_changed.emit()
	battle.message.emit("Your %s was stolen!" % stolen.display_name())
