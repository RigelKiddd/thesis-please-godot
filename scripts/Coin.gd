extends Control

## A small pixel coin.  Used both as a draggable-looking coin in the tray and as
## an empty slot inside a project box.  Rendering is procedural so the phase
## needs no extra texture assets.

signal pressed

var kind := "energy"
var empty := false
var hover := false
var diameter := 42.0
var _label: Label


func setup(coin_kind: String, is_empty: bool, size_px: float = 42.0) -> void:
	kind = coin_kind
	empty = is_empty
	diameter = size_px
	size = Vector2(size_px, size_px)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if !empty and _label == null:
		_label = Label.new()
		_label.text = "力" if kind == "energy" else "钱"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_font_override("font", Ui.F_PIXEL)
		_label.add_theme_font_size_override("font_size", Ui.scaled_font(int(diameter * 0.38)))
		_label.add_theme_color_override("font_color", Color("#f6e7c5") if kind == "energy" else Color("#432f0d"))
		add_child(_label)
		_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_entered.connect(func(): hover = true; queue_redraw())
	mouse_exited.connect(func(): hover = false; queue_redraw())
	queue_redraw()


func _coin_name() -> String:
	return "精力" if kind == "energy" else "金钱"


func _base_color() -> Color:
	return Color("#a8402f") if kind == "energy" else Color("#c9a24a")


func _rim_color() -> Color:
	return Color("#4f1a14") if kind == "energy" else Color("#5f4212")


func _draw() -> void:
	var d := minf(size.x, size.y)
	var c := size * 0.5
	var r := d * 0.5 - 1.0
	var base := _base_color()
	var rim := _rim_color()
	if empty:
		draw_circle(c, r, Color(base.r, base.g, base.b, 0.10), true, -1.0, false)
		draw_arc(c, r - 1.0, 0.0, TAU, 28, Color(rim.r, rim.g, rim.b, 0.55 if !hover else 0.95), 2.0, false)
		var plus := Color(rim.r, rim.g, rim.b, 0.62 if !hover else 1.0)
		draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), plus, 2.0)
		draw_line(c + Vector2(0, -5), c + Vector2(0, 5), plus, 2.0)
		return
	var lit := base.lightened(0.16) if !hover else base.lightened(0.28)
	draw_circle(c + Vector2(1, 2), r, Color(0, 0, 0, 0.28), true, -1.0, false)
	draw_circle(c, r, rim, true, -1.0, false)
	draw_circle(c, r - 2.0, base, true, -1.0, false)
	draw_circle(c + Vector2(0, -1), r - 4.0, lit, true, -1.0, false)
	draw_circle(c, r * 0.64, base.darkened(0.10), true, -1.0, false)
	draw_arc(c, r * 0.64, 0.0, TAU, 22, Color(rim.r, rim.g, rim.b, 0.45), 1.0, false)
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var p := c + Vector2(cos(a), sin(a)) * (r - 1.6)
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), rim)
	if _label != null and _label.get_theme_font_size("font_size") != Ui.scaled_font(int(diameter * 0.38)):
		_label.add_theme_font_size_override("font_size", Ui.scaled_font(int(diameter * 0.38)))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			pressed.emit()
			accept_event()
