class_name Barcode
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var pattern := [1, 2, 1, 3, 1, 1, 2, 1, 4, 1, 2, 2, 1, 1, 3, 1, 2, 1, 1, 4, 2, 1, 1, 2, 1, 3]
	var x := 0.0
	var i := 0
	while x < size.x:
		var w: float = pattern[i % pattern.size()]
		if i % 2 == 0:
			draw_rect(Rect2(x, 0, w, size.y), Color(52 / 255.0, 65 / 255.0, 74 / 255.0, 0.62))
		x += w + 1.0
		i += 1
