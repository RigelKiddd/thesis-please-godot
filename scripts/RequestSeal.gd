class_name RequestSeal
extends Control

## A red round school seal for request documents. Everything is drawn so the
## seal stays crisp at any UI scale and needs no extra texture.

var top_text := "明州大学"
var office_text := "教务处"
var date_text := ""
var ink := Color(149 / 255.0, 48 / 255.0, 38 / 255.0, 0.76)
var broken := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(104, 104)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(top: String, office: String, date: String, color: Color = Color(0, 0, 0, 0), cracked: bool = false) -> void:
	top_text = top
	office_text = office
	date_text = date
	broken = cracked
	if color.a > 0.0:
		ink = color
	queue_redraw()

func _draw() -> void:
	var s: float = min(size.x, size.y)
	if s <= 8.0:
		return
	var c := Vector2(size.x * 0.5, size.y * 0.5)
	var r := s * 0.46
	var faint := Color(ink.r, ink.g, ink.b, ink.a * 0.55)
	var bold := Color(ink.r, ink.g, ink.b, ink.a)
	draw_arc(c, r, 0.0, TAU, 72, bold, maxf(2.0, s * 0.027), true)
	draw_arc(c, r - maxf(3.0, s * 0.045), 0.0, TAU, 72, faint, 1.0, true)
	# five-point star in the middle
	var star := PackedVector2Array()
	var outer := s * 0.105
	var inner := s * 0.043
	for i in range(10):
		var ang := -PI * 0.5 + float(i) * PI / 5.0
		var rad := outer if i % 2 == 0 else inner
		star.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(star, Color(ink.r, ink.g, ink.b, ink.a * 0.8))
	# top text follows the upper arc
	var font: Font = Ui.F_DOC_BOLD
	if font == null:
		return
	var chars := top_text
	var fs := maxi(7, int(round(s * 0.115)))
	var n := chars.length()
	if n > 0:
		var start := -PI * 0.86
		var span := PI * 0.72
		for i in range(n):
			var ang := start + (span * float(i) / float(maxi(1, n - 1)))
			var p := c + Vector2(cos(ang), sin(ang)) * (r - s * 0.095)
			var ch := chars.substr(i, 1)
			var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var asc := font.get_ascent(fs)
			draw_set_transform(p, ang + PI * 0.5, Vector2.ONE)
			draw_string(font, Vector2(-cw * 0.5, asc * 0.5), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, bold)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# bottom office name + date, horizontal, like a real department seal
	var ofs := maxi(7, int(round(s * 0.105)))
	var ow := font.get_string_size(office_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ofs).x
	draw_string(font, c + Vector2(-ow * 0.5, r * 0.46), office_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, ofs, bold)
	if date_text != "":
		var dfs := maxi(6, int(round(s * 0.075)))
		var dw := font.get_string_size(date_text, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs).x
		draw_string(font, c + Vector2(-dw * 0.5, r * 0.78), date_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, dfs, faint)
	if broken:
		# a broken seal reads as "not valid", useful for a missing signature
		draw_line(c + Vector2(-r * 0.5, -r * 0.2), c + Vector2(r * 0.12, r * 0.52), Color("#f7f0dd"), maxf(2.0, s * 0.025))
		draw_line(c + Vector2(-r * 0.1, r * 0.6), c + Vector2(r * 0.62, r * 0.1), Color("#f7f0dd"), maxf(2.0, s * 0.02))
