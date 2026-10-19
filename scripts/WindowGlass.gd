class_name WindowGlass
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var w := size.x
	var h := size.y
	# diagonal reflection band (CSS 116deg)
	var pts := PackedVector2Array([
		Vector2(w * 0.02, h * 0.24), Vector2(w * 0.52, -h * 0.02),
		Vector2(w * 0.68, -h * 0.02), Vector2(w * 0.12, h * 0.32)
	])
	draw_colored_polygon(pts, Color(1, 1, 1, 0.07))
	var pts2 := PackedVector2Array([
		Vector2(w * 0.42, h * 1.02), Vector2(w * 0.9, h * 0.3),
		Vector2(w * 0.96, h * 0.34), Vector2(w * 0.5, h * 1.02)
	])
	draw_colored_polygon(pts2, Color(1, 1, 1, 0.035))
	# edge darkening
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.10), false, 8)
	draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.06), false, 1)
