class_name HandCardView
extends Button
## A built-deck card in Alice's hand: a small card with its art, its key number and a short
## effect line. Never greyed out: it is always clickable, and the battle decides whether the
## play goes through (and says why when it doesn't). The full name and text are the tooltip.

const CARD_SIZE := Vector2(40, 34)
const RARITY_COLOR := {"uncommon": Palette.TEAL, "rare": Palette.GOLD}

var card: Card
var index: int = -1
var _key: Label
var _detail: Label
var _icon: TextureRect


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	focus_mode = Control.FOCUS_NONE
	_icon = TextureRect.new()
	_icon.position = Vector2(4, 2)
	_icon.size = Vector2(32, 22)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_icon.clip_contents = true
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_key = Palette.label("", Palette.INK)
	_key.position = Vector2(3, 1)
	_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_key)
	_detail = Palette.label("", Palette.RED)
	_detail.position = Vector2(0, CARD_SIZE.y - 10)
	_detail.size = Vector2(CARD_SIZE.x, 8)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_detail)


func show_card(c: Card, i: int) -> void:
	card = c
	index = i
	disabled = false
	var frame: Color = RARITY_COLOR.get(str(c.def.get("rarity", "")), Palette.INK)
	add_theme_stylebox_override("normal", Palette.box(Palette.CREAM, frame, 2 if frame != Palette.INK else 1))
	add_theme_stylebox_override("hover", Palette.box(Palette.GOLD_HI, Palette.RED, 2))
	add_theme_stylebox_override("pressed", Palette.box(Palette.RED, Palette.INK))
	_key.text = str(i + 1)
	if c.is_number():
		_icon.texture = null
		_detail.text = "+%d" % c.value()
		_detail.add_theme_color_override("font_color", Palette.RED_DARK)
	else:
		var art := "res://art/" + str(c.def.get("art", ""))
		_icon.texture = load(art) if ResourceLoader.exists(art) else null
		_detail.text = _short(c)
		_detail.add_theme_color_override("font_color", Palette.RED)
	tooltip_text = "%s: %s" % [c.display_name().to_upper(), str(c.def.get("text", ""))]


static func _short(c: Card) -> String:
	var params: Dictionary = c.def.get("params", {})
	match c.effect_name():
		"modify_value":
			var amount := int(params.get("amount", 0))
			if bool(params.get("either_sign", false)):
				return "+/-%d" % amount
			return "%+d" % amount
		"peek":
			return "PEEK"
		"freeze_timer":
			return "STOP"
		"redraw":
			return "REDRAW"
		"copy_enemy":
			return "COPY"
		"wild":
			return "1-5"
		"discard_card":
			return "DROP"
		"shield":
			return "BLOCK"
		"hide_total":
			return "HIDE"
		"crit_boost":
			return "CRIT"
		"duplicate":
			return "TWIN"
		"heal":
			return "+%dHP" % int(params.get("amount", 6))
	return c.effect_name().to_upper().replace("_", " ")
