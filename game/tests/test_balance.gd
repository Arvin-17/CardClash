extends GutTest
## Balance report: hundreds of battles simulated in pure logic with the autoplay bot.
## Prints numbers to compare with the guide's targets (tune in JSON, not code):
##   rounds per soldier fight 3-5, rounds for the Queen 6-9, player busts 20-30% of rounds.
## Asserts only loose sanity bounds so balance tweaks don't break CI.

const STARTER := ["num_1", "num_1", "num_2", "num_2", "num_3", "num_3", "drink_me", "drink_me", "teacup", "eat_me"]
const ROUND_SECONDS := 8.0  # a typical round's real length, to decide how often intent bars fill


func _play_round(b: BattleState) -> void:
	b.start_round()
	var surprise_odds := ROUND_SECONDS / b.intent_seconds()
	var attack_left := true  # the attack bar resets every round and fires at most once
	var guard := 0
	while not b.round_over() and guard < 40:
		guard += 1
		var action := Autoplay.decide(b)
		if action == "hit":
			b.player_hit()
		elif action == "heal":
			b.heal_action()
		elif action == "stay":
			b.player_stay()
			b.finish_enemy_turn()  # Ready ends the round at once
			break
		elif action.begins_with("play:"):
			b.play_card(int(action.trim_prefix("play:")))
		var decision := EnemyAI.decide(b)
		if decision == EnemyAI.HIT:
			b.enemy_hit()
		elif decision == EnemyAI.STAY or decision == EnemyAI.NONE:
			b.enemy_stay()
		if attack_left and b.rng.randf() < surprise_odds / 6.0:
			attack_left = false
			b.fire_surprise()
	b.force_stay()
	b.resolve_round()


func _fight(enemy_id: String, seed_value: int, hp: int) -> Dictionary:
	var b := TestHelpers.battle(enemy_id, STARTER, [], seed_value)
	b.player.hp = hp
	var busts := 0
	while not b.is_over() and b.round_number < 60:
		_play_round(b)
		if b.player.total() > b.target:
			busts += 1
	return {"rounds": b.round_number, "won": b.player_won(), "busts": busts, "hp": b.player.hp}


func test_balance_report() -> void:
	var lines: Array[String] = ["", "=== BALANCE REPORT (autoplay bot, %d fights per enemy) ===" % 200]
	var all_rounds := 0
	var all_busts := 0
	for enemy_id: String in ["spade_soldier", "club_soldier", "diamond_soldier", "heart_soldier", "queen_of_hearts"]:
		var rounds := 0
		var wins := 0
		var busts := 0
		for s in 200:
			var r := _fight(enemy_id, 1000 + s, 30)
			rounds += int(r["rounds"])
			busts += int(r["busts"])
			wins += 1 if r["won"] else 0
		all_rounds += rounds
		all_busts += busts
		lines.append("%-16s avg rounds %.1f   win rate %3d%%   player bust rate %3d%%" % [enemy_id, rounds / 200.0, wins * 100 / 200, busts * 100 / maxi(rounds, 1)])
		assert_between(rounds / 200.0, 1.5, 20.0, "%s fights should end" % enemy_id)
	var run_wins := 0
	for s in 200:
		var hp := 30
		var won := true
		for enemy_id: String in RunState.act_order("act3_court", TestHelpers.rng(s)):
			var r := _fight(enemy_id, 5000 + s * 7, hp)
			if not r["won"]:
				won = false
				break
			hp = mini(30, int(r["hp"]) + 5)
		run_wins += 1 if won else 0
	lines.append("full runs won   %d%% (target: a first-time player wins about 1 in 3)" % (run_wins * 100 / 200))
	lines.append("overall player bust rate %d%% (target 20-30%%)" % (all_busts * 100 / maxi(all_rounds, 1)))
	print("\n".join(lines))
	gut.p("\n".join(lines))
	assert_true(true)
