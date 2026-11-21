class_name HandCardView
extends Button
## A built-deck card in Alice's hand. Placeholder art: a cream card with the card's
## name, plus its value or a short effect line. Greyed out when it can't be played.

const CARD_SIZE := Vector2(52, 34)

var card: Card
var index: int = -1
var _name: Label
var _detail: Label
var _icon: TextureRect


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	focus_mode = Control.FOCUS_NONE
	_name = Label.new()
	_name.position = Vector2(3, 3)
	_name.size = Vector2(CARD_SIZE.x - 6, 16)
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_detail = Label.new()
	_detail.position = Vector2(3, CARD_SIZE.y - 10)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_detail)
	_icon = TextureRect.new()
	_icon.position = Vector2(CARD_SIZE.x - 17, CARD_SIZE.y - 17)
	_icon.size = Vector2(16, 16)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)


func show_card(c: Card, i: int, playable: bool) -> void:
	card = c
	index = i
	disabled = not playable
	var rare := str(c.def.get("rarity", "")) == "rare"
	add_theme_stylebox_override("normal", Palette.box(Palette.CREAM, Palette.RED if rare else Palette.BLACK))
	add_theme_stylebox_override("hover", Palette.box(Palette.CREAM, Palette.RED, 2))
	add_theme_stylebox_override("pressed", Palette.box(Palette.RED, Palette.BLACK))
	add_theme_stylebox_override("disabled", Palette.box(Palette.GREEN, Palette.BLACK))
	_name.text = "%d %s" % [i + 1, c.display_name().to_upper()]
	_name.add_theme_color_override("font_color", Palette.BLACK)
	if c.is_number():
		_detail.text = "+%d" % c.value()
	else:
		_detail.text = _short(c)
	_detail.add_theme_color_override("font_color", Palette.RED)
	var art := "res://art/" + str(c.def.get("art", ""))
	_icon.texture = load(art) if not c.is_number() and ResourceLoader.exists(art) else null
	tooltip_text = str(c.def.get("text", ""))


static func _short(c: Card) -> String:
	var params: Dictionary = c.def.get("params", {})
	match c.effect_name():
		"modify_value":
			var amount := int(params.get("amount", 0))
			if bool(params.get("either_sign", false)):
				return "+/-%d ANY" % amount
			return "%+d LAST" % amount
		"peek":
			return "PEEK"
		"freeze_timer":
			return "STOP %dS" % int(params.get("seconds", 5))
		"redraw":
			return "REDRAW"
		"copy_enemy":
			return "COPY FOE"
		"wild":
			return "1 TO 5"
		"discard_card":
			return "DROP LAST"
		"shield":
			return "BLOCK"
		"hide_total":
			return "HIDE"
		"crit_boost":
			return "CRIT"
		"duplicate":
			return "COPY LAST"
		"heal":
			return "+%d HP" % int(params.get("amount", 6))
	return c.effect_name().to_upper().replace("_", " ")
