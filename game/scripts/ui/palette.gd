class_name Palette
extends RefCounted
## Colours. The original four (red, cream, green, black) plus the art palette used by the
## sprites in game/art/anim (exported by tools/sprites).

const BLACK := Color("1b1a26")
const RED := Color("c8323c")
const CREAM := Color("f2e6c9")
const GREEN := Color("3f7d3a")

const INK := Color("120a16")
const RED_HI := Color("ff5a6a")
const RED_DARK := Color("7a1428")
const GOLD := Color("e8b04a")
const GOLD_HI := Color("ffe08a")
const GOLD_DARK := Color("a8702a")
const PINK_PALE := Color("f0c8cc")
const LAVENDER := Color("b8a3e0")
const TEAL := Color("3fc1c9")
const HP_GREEN := Color("58c06a")
const SEPIA := Color("b08850")
const PLUM := Color("3d2a4e")

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


## A label with a dark 1-pixel shadow so it reads over the animated rooms.
static func shadow_label(text: String, color: Color = CREAM, big: bool = false) -> Label:
	var l := label(text, color, big)
	l.add_theme_color_override("font_shadow_color", INK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l
