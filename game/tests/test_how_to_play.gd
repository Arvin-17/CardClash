extends GutTest
## The How to Play screen: every page builds, pages turn, the rules use the real numbers.

const HOWTO := preload("res://scenes/how_to_play.tscn")


func _open() -> Control:
	var screen: Control = HOWTO.instantiate()
	add_child_autofree(screen)
	await wait_frames(1)
	return screen


func test_every_page_builds_and_its_screenshot_exists() -> void:
	var screen = await _open()
	assert_gt(screen._pages.size(), 6)
	for i in screen._pages.size():
		var p: Dictionary = screen._pages[i]
		if p.has("photo"):
			assert_true(ResourceLoader.exists("res://art/howto/%s.png" % p["photo"]), "%s has its screenshot" % p["title"])
		screen._show(i)
		await wait_frames(1)
		assert_eq(screen._title.text, p["title"])
		assert_gt(screen._content.get_child_count(), 0, "%s shows something" % p["title"])


func test_pages_turn_and_stop_at_the_ends() -> void:
	var screen = await _open()
	assert_eq(screen._page, 0)
	assert_true(screen._back.disabled, "no page before the first")
	screen._turn(1)
	assert_eq(screen._page, 1)
	screen._turn(-1)
	screen._turn(-1)
	assert_eq(screen._page, 0)
	screen._show(screen._pages.size() - 1)
	assert_string_contains(screen._next.text, "PLAY")


func test_the_rules_pages_use_the_real_numbers() -> void:
	var screen = await _open()
	var all := ""
	for p: Dictionary in screen._pages:
		all += str(p["text"]) + "\n"
	assert_string_contains(all, "%d SECONDS" % int(GameData.rule("round.seconds", 0)))
	assert_string_contains(all, "HEAL [E]: +%d HP" % int(GameData.rule("player.heal_action", 0)))
	assert_string_contains(all, "REACH %d" % int(GameData.rule("damage.super_bust_at", 0)))


func test_opening_it_marks_it_seen() -> void:
	RunState.seen_how_to_play = false
	await _open()
	assert_true(RunState.seen_how_to_play)
