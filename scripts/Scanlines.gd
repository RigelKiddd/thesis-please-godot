class_name Scanlines
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var y := 0.0
	while y < size.y:
		draw_rect(Rect2(0, y, size.x, 1), Color(0.035, 0.039, 0.027, 0.052))
		y += 3.0
