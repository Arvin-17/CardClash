class_name CardView
extends Panel
## Placeholder card art: a cream card showing rank and suit (or a built-deck card's name),
## until the designer's sprites land.

const CARD_SIZE := Vector2(22, 30)

var card: Card
var _face: Label
var _suit: Label


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = Label.new()
	_face.position = Vector2(3, 2)
	add_child(_face)
	_suit = Label.new()
	_suit.position = Vector2(8, 16)
	add_child(_suit)


func show_card(c: Card, face_down: bool = false) -> void:
	card = c
	if face_down:
		add_theme_stylebox_override("panel", Palette.box(Palette.RED, Palette.BLACK))
		_face.text = ""
		_suit.text = "?"
		_suit.add_theme_color_override("font_color", Palette.CREAM)
		return
	var ink := Palette.suit_color(c.suit) if c.is_blind() else Palette.BLACK
	var border := Palette.RED if c.modifier != 0 or not c.is_blind() else Palette.BLACK
	add_theme_stylebox_override("panel", Palette.box(Palette.CREAM, border))
	_face.text = c.face()
	_face.add_theme_color_override("font_color", ink)
	_suit.text = Palette.SUIT_GLYPH.get(c.suit, "*")
	_suit.add_theme_color_override("font_color", ink)
