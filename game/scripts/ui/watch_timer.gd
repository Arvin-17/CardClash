class_name WatchTimer
extends Control
## The round timer drawn as a pocket watch: a pink wedge shows the time left,
## and the last few seconds blink red.

const RADIUS := 21.0

var fraction: float = 1.0
var seconds: int = 0
var frozen: bool = false
var _t: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2 + 4, RADIUS * 2 + 10)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_time(seconds_left: float, total: float) -> void:
	fraction = clampf(seconds_left / maxf(total, 0.01), 0.0, 1.0)
	seconds = ceili(seconds_left)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if seconds <= 3 or frozen:
		queue_redraw()


func _draw() -> void:
	var c := Vector2(RADIUS + 2, RADIUS + 8)
	draw_rect(Rect2(c.x - 3, 0, 7, 5), Palette.GOLD_DARK)
	draw_circle(c, RADIUS + 2, Palette.GOLD_DARK)
	draw_circle(c, RADIUS, Palette.CREAM)
	var low := seconds <= 3 and int(_t * 6.0) % 2 == 0
	var wedge := Palette.SEPIA if frozen else (Palette.RED if low else Palette.PINK_PALE)
	if fraction > 0.0:
		var pts := PackedVector2Array([c])
		var steps := maxi(2, int(48 * fraction))
		for i in steps + 1:
			var a := -PI / 2 + TAU * fraction * float(i) / float(steps)
			pts.append(c + Vector2(cos(a), sin(a)) * (RADIUS - 2))
		draw_colored_polygon(pts, wedge)
	for i in 12:
		var a := TAU * i / 12.0
		draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * (RADIUS - 1) - Vector2(0.5, 0.5), Vector2(1, 1)), Palette.INK)
	var font := get_theme_default_font()
	var text := str(seconds)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(font, c + Vector2(-w / 2.0, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Palette.INK)
