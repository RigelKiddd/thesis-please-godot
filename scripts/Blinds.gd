class_name Blinds
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var y := 0.0
	var dark := Color(18 / 255.0, 24 / 255.0, 18 / 255.0, 0.32 * 0.55)
	var light := Color(226 / 255.0, 211 / 255.0, 168 / 255.0, 0.25 * 0.55)
	while y < size.y:
		draw_rect(Rect2(0, y, size.x, 3), dark)
		draw_rect(Rect2(0, y + 3, size.x, 3), light)
		y += 10.0
