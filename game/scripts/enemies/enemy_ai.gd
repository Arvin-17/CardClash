class_name EnemyAI
extends RefCounted
## The one AI every enemy shares; numbers come from enemies.json.
## Called on each 0.5 s tick during the round (after the enemy's reaction delay).
##
## 1. Already stayed or bust: do nothing.
## 2. Total < stay_at: hit.
## 3. Total >= stay_at: hit anyway with probability `risk` (only when total <= 18), else stay.
## Extra (rules.ai.reads_player_total): Alice's total is in plain sight, and standing ends the
## round on the spot, so while she's ahead (and not bust) the enemy keeps hitting to beat her.
## Caterpillar Smoke hides her total, so it plays blind on its stay-at number. Her being bust
## doesn't make it stop early: a bust can be undone with a card.

const HIT := "hit"
const STAY := "stay"
const NONE := "none"


static func decide(battle: BattleState) -> String:
	var enemy := battle.enemy
	var target := battle.target
	if enemy.stayed or enemy.is_bust(target):
		return NONE
	var total := enemy.total(target)
	var ai: Dictionary = battle.rules.get("ai", {})
	if bool(ai.get("reads_player_total", true)) and not battle.hide_total:
		var player_total := battle.player.total(target)
		if player_total <= target and total < player_total:
			return HIT
	if total < battle.enemy_stay_at:
		return HIT
	if total <= int(ai.get("risk_max_total", 18)) and battle.rng.randf() < battle.enemy_risk:
		return HIT
	return STAY


## What the AI is about to do, without rolling any dice (for the F1 debug overlay).
static func preview(battle: BattleState) -> String:
	var enemy := battle.enemy
	if enemy.stayed:
		return "STAYED"
	var total := enemy.total(battle.target)
	if total > battle.target:
		return "BUST"
	if bool(battle.rules.get("ai", {}).get("reads_player_total", true)) and not battle.hide_total \
			and total < battle.player.total(battle.target) and battle.player.total(battle.target) <= battle.target:
		return "HIT (behind your total)"
	if total < battle.enemy_stay_at:
		return "HIT (below %d)" % battle.enemy_stay_at
	if total <= 18:
		return "STAY, %d%% RISKY HIT" % int(battle.enemy_risk * 100)
	return "STAY"
