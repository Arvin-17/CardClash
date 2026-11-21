class_name Rules
extends RefCounted
## The rules contract: totals and the round damage table.
## Plain static functions with no scene code, so they can be unit-tested.

const DEFAULT_TARGET := 21


## Sum the cards; while over the target and an ace still counts 11, drop one ace to 1.
static func total(cards: Array, target: int = DEFAULT_TARGET) -> int:
	var sum := 0
	var soft_aces := 0
	for c: Card in cards:
		sum += c.value()
		if c.is_ace and c.value() > 10:
			soft_aces += 1
	while sum > target and soft_aces > 0:
		sum -= 10
		soft_aces -= 1
	return sum


static func is_bust(total_value: int, target: int = DEFAULT_TARGET) -> bool:
	return total_value > target


## Resolve a round once both sides have stayed (or the timer ran out).
## Returns {kind, winner, loser, damage, messy_damage, critical, player_total, enemy_total}
## where kind is one of: both_bust, player_bust, enemy_bust, closer, tie.
##
## | both bust      | no winner; both lose `messy_round` HP                |
## | you bust       | you take (your_total - 21) + enemy base attack       |
## | enemy busts    | enemy takes (enemy_total - 21) + your base attack    |
## | closer to 21   | loser takes difference + winner's base attack        |
## | exactly 21     | critical: damage x critical_multiplier               |
## | tie            | no damage (unless damage.tie_favors_player)          |
static func resolve(
	player_total: int,
	enemy_total: int,
	player_attack: int,
	enemy_attack: int,
	rules: Dictionary,
	crit_boost: bool = false,
	win_bonus: int = 0
) -> Dictionary:
	var target := int(rules.get("blackjack", DEFAULT_TARGET))
	var dmg: Dictionary = rules.get("damage", {})
	var result := {
		"kind": "tie",
		"winner": "none",
		"loser": "none",
		"damage": 0,
		"messy_damage": 0,
		"critical": false,
		"player_total": player_total,
		"enemy_total": enemy_total,
	}
	# Super bust: Alice reached super_bust_at (30). The round ended on the spot and
	# she takes her bust damage doubled, whatever the enemy holds.
	var super_at := int(dmg.get("super_bust_at", 0))
	if super_at > 0 and player_total >= super_at:
		result["kind"] = "super_bust"
		result["winner"] = "enemy"
		result["loser"] = "player"
		result["damage"] = ((player_total - target) + enemy_attack) * int(dmg.get("super_bust_multiplier", 2))
		return result

	var player_bust := player_total > target
	var enemy_bust := enemy_total > target
	if player_bust and enemy_bust:
		result["kind"] = "both_bust"
		result["messy_damage"] = int(dmg.get("messy_round", 2))
		return result

	var winner := "none"
	var damage := 0
	if player_bust:
		result["kind"] = "player_bust"
		winner = "enemy"
		damage = (player_total - target) + enemy_attack
	elif enemy_bust:
		result["kind"] = "enemy_bust"
		winner = "player"
		damage = (enemy_total - target) + player_attack
	elif player_total == enemy_total:
		if not bool(dmg.get("tie_favors_player", false)):
			return result
		winner = "player"
		damage = player_attack
	else:
		result["kind"] = "closer"
		winner = "player" if player_total > enemy_total else "enemy"
		damage = absi(player_total - enemy_total) + (player_attack if winner == "player" else enemy_attack)

	var winner_total := player_total if winner == "player" else enemy_total
	var critical := winner_total == target or (winner == "player" and crit_boost)
	if winner == "player":
		damage += win_bonus
	if critical:
		damage *= int(dmg.get("critical_multiplier", 2))
	result["winner"] = winner
	result["loser"] = "enemy" if winner == "player" else "player"
	result["damage"] = damage
	result["critical"] = critical
	return result
