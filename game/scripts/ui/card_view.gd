class_name CardView
extends Control
## A card on the table: the pixel-art face from art/cards/deck.png for blind-deck cards,
## a cream card with its value for built-deck and pseudo cards (Bonk, copies...).
## A card changed by Drink Me / Eat Me shows its new value in a gold tag.

const CARD_SIZE := Vector2(26, 36)

var card: Card
var _art: TextureRect
var _face: Label
var _tag: Label


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = TextureRect.new()
	_art.size = CARD_SIZE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_face = Label.new()
	_face.position = Vector2(3, 3)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_tag = Palette.label("", Palette.INK)
	_tag.position = Vector2(2, 26)
	_tag.size = Vector2(22, 8)
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tag_box := Palette.box(Palette.GOLD_HI, Palette.INK)
	_tag.add_theme_stylebox_override("normal", tag_box)
	_tag.visible = false
	add_child(_tag)


func show_card(c: Card, face_down: bool = false) -> void:
	card = c
	_face.text = ""
	_tag.visible = false
	if face_down:
		_art.texture = AnimLib.card_texture("", "", true)
		return
	if c.is_blind():
		_art.texture = AnimLib.card_texture(c.rank, c.suit)
	else:
		_art.texture = null
		_face.text = c.face()
		_face.add_theme_color_override("font_color", Palette.BLACK)
	if _art.texture == null:
		# No exported art: a plain cream card.
		var bg := Panel.new()
		bg.size = CARD_SIZE - Vector2(2, 2)
		bg.position = Vector2(1, 1)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_theme_stylebox_override("panel", Palette.box(Palette.CREAM, Palette.RED if not c.is_blind() else Palette.BLACK))
		add_child(bg)
		move_child(bg, 0)
		if c.is_blind():
			_face.text = c.face()
			_face.add_theme_color_override("font_color", Palette.suit_color(c.suit))
	if c.modifier != 0:
		_tag.text = "=%d" % c.value()
		_tag.visible = true
