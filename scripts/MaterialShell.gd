class_name MaterialShell
extends Control

## The collapsed desk file is a silhouette, not a miniature form.  Each prop
## gets a different physical shape (ticket, ledger book, cardstock schedule,
## envelope) while staying in the same ink/paper/red-seal palette.  No text:
## the pictogram and short label sit above this drawing.

var kind := "schedule"
var paper := Color("#d9b98a")
var accent := Color("#8b382b")
var ink := Color("#1b1710")


func setup(kind_name: String, tr: Dictionary) -> void:
	kind = kind_name
	paper = tr.get("paper_color", Color("#d9b98a"))
	accent = tr.get("accent_color", Color("#8b382b"))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8 or h < 8:
		return
	match kind:
		"ledger", "favor":
			_book(w, h)
		"pass":
			_ticket(w, h)
		"letter":
			_envelope(w, h)
		_:
			_schedule(w, h)


func _schedule(w: float, h: float) -> void:
	var p := PackedVector2Array([
		Vector2(2, 2), Vector2(w - 13, 2), Vector2(w - 2, 13),
		Vector2(w - 2, h - 2), Vector2(2, h - 2),
	])
	_shadow(p, 3, 4)
	draw_colored_polygon(p, paper)
	_border(p, ink, 2)
	draw_line(Vector2(4, 4), Vector2(w - 14, 4), accent, 4)
	# Binder holes on the left edge.
	for y in [12.0, 23.0]:
		draw_circle(Vector2(8, y), 3.0, Color("#6d5a3c"))
		draw_circle(Vector2(8, y), 1.4, paper)
	# A faint date grid in the lower-right corner.
	var gx := w - 36.0
	var gy := h - 25.0
	draw_rect(Rect2(gx, gy, 24, 16), Color(ink.r, ink.g, ink.b, 0.18), false, 1)
	for i in range(1, 3):
		draw_line(Vector2(gx + i * 8, gy), Vector2(gx + i * 8, gy + 16), Color(ink.r, ink.g, ink.b, 0.16), 1)
	draw_line(Vector2(gx, gy + 8), Vector2(gx + 24, gy + 8), Color(ink.r, ink.g, ink.b, 0.16), 1)
	draw_rect(Rect2(w - 25, h - 14, 9, 8), Color(accent.r, accent.g, accent.b, 0.18), true)


func _book(w: float, h: float) -> void:
	var p := PackedVector2Array([
		Vector2(2, 2), Vector2(w - 9, 2), Vector2(w - 2, 9),
		Vector2(w - 2, h - 2), Vector2(2, h - 2),
	])
	_shadow(p, 3, 4)
	draw_colored_polygon(p, paper)
	_border(p, ink, 2)
	# Spine and its bands.
	draw_rect(Rect2(2, 2, 12, h - 4), Color(accent.r, accent.g, accent.b, 0.72))
	draw_line(Vector2(14, 2), Vector2(14, h - 2), ink, 1)
	for y in [10.0, h - 10.0]:
		draw_line(Vector2(4, y), Vector2(12, y), Color("#d9c48a"), 1)
	# Paper label plate on the cover.
	draw_rect(Rect2(20, 12, w - 34, h - 24), Color(1, 1, 1, 0.18), true)
	draw_rect(Rect2(20, 12, w - 34, h - 24), Color(ink.r, ink.g, ink.b, 0.34), false, 1)
	draw_line(Vector2(23, 18), Vector2(w - 17, 18), Color(ink.r, ink.g, ink.b, 0.18), 1)
	# Elastic band and clasp at the fore-edge.
	draw_line(Vector2(w - 14, 4), Vector2(w - 14, h - 4), Color(ink.r, ink.g, ink.b, 0.55), 2)
	draw_rect(Rect2(w - 17, h * 0.45, 6, 12), Color(accent.r, accent.g, accent.b, 0.55), true)
	# Tiny red ownership seal.
	draw_rect(Rect2(w - 25, h - 18, 9, 9), Color(accent.r, accent.g, accent.b, 0.18), true)
	draw_rect(Rect2(w - 25, h - 18, 9, 9), Color(accent.r, accent.g, accent.b, 0.78), false, 1)


func _ticket(w: float, h: float) -> void:
	var p := PackedVector2Array([
		Vector2(8, 2), Vector2(w - 8, 2), Vector2(w - 2, 8),
		Vector2(w - 2, h - 8), Vector2(w - 8, h - 2),
		Vector2(8, h - 2), Vector2(2, h - 8), Vector2(2, 8),
	])
	_shadow(p, 3, 4)
	draw_colored_polygon(p, paper)
	_border(p, ink, 2)
	# Perforation and tear-off stub.
	var px := w - 27.0
	for y in range(7, int(h - 5), 6):
		draw_line(Vector2(px, y), Vector2(px, y + 3), Color(ink.r, ink.g, ink.b, 0.42), 1)
	draw_rect(Rect2(px + 2, 2, w - px - 4, h - 4), Color(accent.r, accent.g, accent.b, 0.10), true)
	draw_line(Vector2(2, 2), Vector2(w - 2, 2), accent, 3)
	# Stylised edge notches.
	draw_circle(Vector2(2, h * 0.5), 4.5, ink)
	draw_circle(Vector2(2, h * 0.5), 2.4, paper)
	draw_circle(Vector2(w - 2, h * 0.5), 4.5, ink)
	draw_circle(Vector2(w - 2, h * 0.5), 2.4, paper)
	# A small stamp on the stub.
	draw_rect(Rect2(w - 19, 10, 9, 9), Color(accent.r, accent.g, accent.b, 0.16), true)
	draw_rect(Rect2(w - 19, 10, 9, 9), Color(accent.r, accent.g, accent.b, 0.8), false, 1)


func _envelope(w: float, h: float) -> void:
	var p := PackedVector2Array([
		Vector2(3, 3), Vector2(w - 10, 3), Vector2(w - 3, 10),
		Vector2(w - 3, h - 3), Vector2(3, h - 3),
	])
	_shadow(p, 3, 4)
	draw_colored_polygon(p, paper)
	_border(p, ink, 2)
	# Flap and fold lines.
	draw_line(Vector2(4, 4), Vector2(w * 0.5, 30), Color(ink.r, ink.g, ink.b, 0.44), 1)
	draw_line(Vector2(w - 4, 4), Vector2(w * 0.5, 30), Color(ink.r, ink.g, ink.b, 0.44), 1)
	draw_line(Vector2(4, 4), Vector2(w - 4, 4), Color(ink.r, ink.g, ink.b, 0.22), 1)
	# Wax seal.
	draw_circle(Vector2(w * 0.5, 30), 7.5, Color(accent.r, accent.g, accent.b, 0.18))
	draw_circle(Vector2(w * 0.5, 30), 7.5, accent, false, 1)
	draw_circle(Vector2(w * 0.5, 30), 3.4, Color(accent.r, accent.g, accent.b, 0.85))
	# Postage stamp.
	draw_rect(Rect2(w - 25, 10, 14, 16), Color(accent.r, accent.g, accent.b, 0.14), true)
	draw_rect(Rect2(w - 25, 10, 14, 16), Color(accent.r, accent.g, accent.b, 0.72), false, 1)
	for i in range(3):
		draw_line(Vector2(w - 23, 14 + i * 4), Vector2(w - 13, 14 + i * 4), Color(accent.r, accent.g, accent.b, 0.4), 1)


func _shadow(p: PackedVector2Array, dx: float, dy: float) -> void:
	var q := PackedVector2Array()
	for v in p:
		q.append(v + Vector2(dx, dy))
	draw_colored_polygon(q, Color(0, 0, 0, 0.38))


func _border(p: PackedVector2Array, color: Color, width: float) -> void:
	var q := p.duplicate()
	q.append(p[0])
	draw_polyline(q, color, width)
