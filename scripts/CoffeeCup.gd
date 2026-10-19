class_name CoffeeCup
extends Control

var t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func _draw() -> void:
	# steam
	for i in range(3):
		var phase := t * (0.9 + i * 0.17) + i * 1.7
		var lift := 7.0 + 4.0 * (0.5 + 0.5 * sin(phase))
		var alpha := 0.30 + 0.16 * sin(phase * 1.3)
		var x := 12.0 + i * 9.0
		draw_rect(Rect2(x, 36.0 - lift, 2, 12), Color(0.914, 0.863, 0.761, max(0.0, alpha)))
	# mug
	draw_rect(Rect2(2, 14, 38, 34), Color(0.231, 0.392, 0.353))
	draw_rect(Rect2(2, 14, 38, 34), Color(0.106, 0.09, 0.063), false, 3)
	# handle
	draw_rect(Rect2(40, 21, 13, 15), Color(0.231, 0.392, 0.353))
	draw_rect(Rect2(40, 21, 13, 15), Color(0.106, 0.09, 0.063), false, 3)
	draw_rect(Rect2(40, 24, 4, 9), Color(0.231, 0.392, 0.353))
	# coffee
	draw_rect(Rect2(6, 18, 27, 5), Color(0.369, 0.231, 0.133))
	draw_rect(Rect2(6, 22, 27, 2), Color(0.165, 0.106, 0.067))
	# highlight
	draw_rect(Rect2(6, 17, 4, 28), Color(1, 1, 1, 0.10))
