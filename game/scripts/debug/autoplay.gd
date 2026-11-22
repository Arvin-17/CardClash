class_name Autoplay
extends RefCounted
## A simple player bot for headless smoke runs: `godot --headless -- --autoplay`.
## Plays like a cautious beginner so CI exercises every system end to end.


static func enabled() -> bool:
	return OS.get_cmdline_user_args().has("--autoplay")


## `-- --autoplay --demo`: the bot plays demo mode (straight to the Queen) instead of a run.
static func demo() -> bool:
	return OS.get_cmdline_user_args().has("--demo")


## Returns "play:<index>", "hit", "stay" or "" (wait).
static func decide(battle: BattleState) -> String:
	if battle.player.stayed:
		return ""
	var total := battle.player.total(battle.target)
	for i in battle.hand.size():
		var card: Card = battle.hand[i]
		if not battle.can_play(i):
			continue
		if card.is_number() and total + card.value() <= battle.target and total + card.value() >= 17:
			return "play:%d" % i
		if card.effect_name() == "modify_value" and int(battle.params_for(card).get("amount", 0)) < 0 and total > battle.target - 2:
			return "play:%d" % i
		if card.effect_name() == "peek" and battle.peeked_card == null:
			return "play:%d" % i
	if battle.can_heal() and battle.player.hp * 2 <= battle.player.max_hp:
		return "heal"
	if total < 17:
		return "hit"
	return "stay"


static func log_line(text: String) -> void:
	print("SMOKE ", text)


## Run `action` after `seconds`, owned by `node` (so it dies with the scene).
static func after(node: Node, seconds: float, action: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = seconds
	t.timeout.connect(action)
	t.timeout.connect(t.queue_free)
	node.add_child(t)
	t.start()
