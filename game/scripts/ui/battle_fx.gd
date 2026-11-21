class_name BattleFx
extends Control
## One-shot visual effects drawn over the battle table: damage numbers, banners, the Vorpal
## slash, sparkles, card bursts, embers and the special-card cutscene. Purely cosmetic:
## nothing here touches game state, and every effect cleans itself up.

const BIG_FONT := "res://art/fonts/pixel_big.fnt"

var _embers: CPUParticles2D
var _sepia: ColorRect
var _flash: ColorRect
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	_sepia = ColorRect.new()
	_sepia.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sepia.color = Color(Palette.SEPIA, 0.0)
	_sepia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sepia)
	_embers = CPUParticles2D.new()
	_embers.emitting = false
	_embers.amount = 40
	_embers.lifetime = 3.0
	_embers.position = Vector2(240, 276)
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(240, 4)
	_embers.direction = Vector2(0, -1)
	_embers.spread = 20.0
	_embers.gravity = Vector2.ZERO
	_embers.initial_velocity_min = 20.0
	_embers.initial_velocity_max = 45.0
	_embers.scale_amount_min = 1.0
	_embers.scale_amount_max = 2.0
	_embers.color_ramp = _ramp([Palette.GOLD_HI, Palette.RED_HI, Color(Palette.RED_DARK, 0.0)])
	add_child(_embers)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(Color.WHITE, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


static func _ramp(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray(colors)
	return g


## A number or word that floats up and fades: damage, "+2", "BLOCKED!".
func pop(text: String, pos: Vector2, color: Color, big: bool = false) -> void:
	var l := Palette.shadow_label(text, color, big)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", pos.y - 24.0, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	t.chain().tween_callback(l.queue_free)


## A big centred word that punches in and fades: "BUST!", "21!", "ROUND WON".
func banner(text: String, color: Color, y: float = 96.0, zoom: float = 2.0, hold: float = 0.9) -> void:
	var l := Palette.shadow_label(text, color, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(480, 18)
	l.position = Vector2(0, y)
	l.pivot_offset = Vector2(240, 9)
	l.scale = Vector2.ONE * zoom * 1.6
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var t := create_tween()
	t.tween_property(l, "scale", Vector2.ONE * zoom, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold)
	t.tween_property(l, "modulate:a", 0.0, 0.3)
	t.tween_callback(l.queue_free)


## The Vorpal slash: a white-hot line drawn corner to corner, then a flash.
func slash(from: Vector2 = Vector2(120, 170), to: Vector2 = Vector2(360, 20)) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Palette.GOLD_HI
	line.points = PackedVector2Array([from, from])
	add_child(line)
	var core := Line2D.new()
	core.width = 2.0
	core.default_color = Color.WHITE
	core.points = line.points
	add_child(core)
	var t := create_tween()
	t.tween_method(_slash_step.bind(line, core, from, to), 0.0, 1.0, 0.14)
	t.tween_callback(screen_flash.bind(Color.WHITE, 0.6, 0.18))
	t.tween_property(line, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(core, "modulate:a", 0.0, 0.25)
	t.tween_callback(line.queue_free)
	t.tween_callback(core.queue_free)


func screen_flash(color: Color, alpha: float = 0.5, seconds: float = 0.25) -> void:
	_flash.color = Color(color, alpha)
	create_tween().tween_property(_flash, "color:a", 0.0, seconds)


## Little pixels flying out of a point.
func sparkles(center: Vector2, colors: Array = [Palette.GOLD_HI, Color.WHITE], count: int = 12, radius: float = 22.0) -> void:
	for i in count:
		var p := ColorRect.new()
		p.size = Vector2(2, 2) if i % 3 == 0 else Vector2(1, 1)
		p.color = colors[i % colors.size()]
		p.position = center
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		var a := TAU * float(i) / float(count) + _rng.randf_range(-0.2, 0.2)
		var dest := center + Vector2(cos(a), sin(a) * 0.7) * _rng.randf_range(radius * 0.6, radius)
		var t := create_tween().set_parallel()
		t.tween_property(p, "position", dest, 0.45).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate:a", 0.0, 0.3).set_delay(0.25)
		t.chain().tween_callback(p.queue_free)


## A card soldier folding: a fan of card backs bursting out and falling.
func card_burst(center: Vector2) -> void:
	var back := AnimLib.card_texture("", "", true)
	for i in 10:
		var c := TextureRect.new()
		c.texture = back
		c.position = center
		c.pivot_offset = Vector2(13, 18)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		var a := -PI * (0.1 + 0.8 * float(i) / 9.0)
		var mid := center + Vector2(cos(a), sin(a)) * 70.0
		var t := create_tween().set_parallel()
		t.tween_property(c, "position", mid, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(c, "rotation", _rng.randf_range(-3.0, 3.0), 1.0)
		t.chain().tween_property(c, "position:y", 300.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.chain().tween_callback(c.queue_free)


## The Pocket Watch: the room turns sepia while time stands still.
func sepia(seconds: float) -> void:
	_sepia.color.a = 0.0
	var t := create_tween()
	t.tween_property(_sepia, "color:a", 0.3, 0.2)
	t.tween_interval(maxf(0.0, seconds - 0.4))
	t.tween_property(_sepia, "color:a", 0.0, 0.2)


func embers(on: bool) -> void:
	_embers.emitting = on


## Every special card's cutscene: it rises from the hand, zooms to the centre, flips from its
## back to its face with a flash, then flies to where its effect lands and fades.
func card_cutscene(card_id: String, from: Vector2, target: Vector2) -> void:
	var face := AnimLib.card_face(card_id)
	if face == null:
		sparkles(target)
		return
	var back := AnimLib.card_texture("", "", true)
	var c := TextureRect.new()
	c.texture = back
	c.stretch_mode = TextureRect.STRETCH_SCALE
	c.size = Vector2(56, 78)
	c.pivot_offset = c.size / 2.0
	c.position = from - c.pivot_offset
	c.scale = Vector2(0.45, 0.45)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	var center := Vector2(240, 112) - c.pivot_offset
	var t := create_tween()
	t.tween_property(c, "position", center, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(c, "scale", Vector2.ONE, 0.18)
	t.tween_property(c, "scale:x", 0.0, 0.08)
	t.tween_callback(_reveal.bind(c, face))
	t.tween_property(c, "scale:x", 1.0, 0.08)
	t.tween_interval(0.35)
	t.tween_property(c, "position", target - c.pivot_offset, 0.16).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(c, "scale", Vector2(0.2, 0.2), 0.16)
	t.tween_callback(sparkles.bind(target))
	t.tween_callback(c.queue_free)


func _slash_step(k: float, line: Line2D, core: Line2D, from: Vector2, to: Vector2) -> void:
	var p := from.lerp(to, k)
	line.set_point_position(1, p)
	core.set_point_position(1, p)


func _reveal(c: TextureRect, face: Texture2D) -> void:
	c.texture = face
	screen_flash(Color.WHITE, 0.35, 0.15)
	sparkles(Vector2(240, 112), [Palette.GOLD_HI, Color.WHITE], 14, 44.0)
