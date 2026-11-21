class_name Combatant
extends RefCounted
## One side of the table (Alice or the enemy): HP plus this round's table cards.

var side: String = ""
var display_name: String = ""
var hp: int = 0
var max_hp: int = 0
var base_attack: int = 0
var table: Array[Card] = []
var stayed: bool = false


func _init(p_side: String, p_name: String, p_hp: int, p_max_hp: int, p_attack: int) -> void:
	side = p_side
	display_name = p_name
	hp = p_hp
	max_hp = p_max_hp
	base_attack = p_attack


func total(target: int = Rules.DEFAULT_TARGET) -> int:
	return Rules.total(table, target)


func is_bust(target: int = Rules.DEFAULT_TARGET) -> bool:
	return total(target) > target


func last_table_card() -> Card:
	return null if table.is_empty() else table.back()


func highest_table_card() -> Card:
	var best: Card = null
	for c: Card in table:
		if best == null or c.value() > best.value():
			best = c
	return best


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - maxi(0, amount))


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + maxi(0, amount))


func is_dead() -> bool:
	return hp <= 0


## Clears the table for the next round and returns what was on it.
func clear_table() -> Array[Card]:
	var cleared: Array[Card] = table.duplicate()
	table.clear()
	stayed = false
	return cleared
