class_name Palette
extends RefCounted
## The 4-colour palette: red, cream, green, black.

const BLACK := Color("1b1a26")
const RED := Color("c8323c")
const CREAM := Color("f2e6c9")
const GREEN := Color("3f7d3a")

const SUIT_GLYPH := {"hearts": "♥", "diamonds": "♦", "clubs": "♣", "spades": "♠"}


static func suit_color(suit: String) -> Color:
	return RED if suit == "hearts" or suit == "diamonds" else BLACK


static func box(bg: Color, border: Color = BLACK, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.anti_aliasing = false
	return s


static func label(text: String, color: Color = CREAM, big: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	if big:
		l.add_theme_font_override("font", load("res://art/fonts/pixel_big.fnt"))
		l.add_theme_font_size_override("font_size", 16)
	return l
