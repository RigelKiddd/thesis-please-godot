class_name DeskItem
extends PixelPanel

## A draggable prop document on the between-days desk.
##
## Collapsed: a 140×78 paper card.  Click it to expand into a 460×212 sheet;
## drag the card or the sheet to move it; the sheet's "收起" button folds it
## back.  The body is supplied by AllocationView so this control stays generic.

signal drag_moved(item_id: String, global_pos: Vector2)
signal drag_finished(item_id: String, global_pos: Vector2)
signal item_changed(item_id: String)
signal archive_requested(item_id: String)

const CARD_SIZE := Vector2(136, 70)
const DOC_SIZE := Vector2(460, 274)
const HEADER_H := 24.0
const MATERIAL_ICON := preload("res://scripts/MaterialIcon.gd")
const MATERIAL_SHELL := preload("res://scripts/MaterialShell.gd")
const PROP := preload("res://scripts/PropMaterial.gd")

var item: Dictionary = {}
var state
var body_builder: Callable
var desk_size := Vector2(1000, 212)
var expanded := false
var _dragging := false
var _drag_moved := false
var _press_pos := Vector2.ZERO
var _press_origin := Vector2.ZERO
var _base_shadow := Vector2.ZERO
var _drag_lift := false

func setup(data: Dictionary, run_state, builder: Callable, area: Vector2) -> void:
	item = data
	state = run_state
	body_builder = builder
	desk_size = area
	expanded = false
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_rebuild()

func _ready() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	z_as_relative = true
	_rebuild()

func refresh() -> void:
	_rebuild()

func expand() -> void:
	expanded = true
	size = DOC_SIZE
	_rebuild()
	_clamp()
	bring_to_front()

func collapse() -> void:
	expanded = false
	size = CARD_SIZE
	_rebuild()
	_clamp()

func bring_to_front() -> void:
	if get_parent() != null:
		get_parent().move_child(self, get_parent().get_child_count() - 1)


func restore_origin() -> void:
	position = _press_origin
	_clamp()

func _clamp() -> void:
	var max_pos := desk_size - size - Vector2(4, 4)
	position.x = clampf(position.x, 4.0, maxf(4.0, max_pos.x))
	position.y = clampf(position.y, 4.0, maxf(4.0, max_pos.y))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_dragging = true
			_drag_moved = false
			_press_pos = mb.global_position
			_press_origin = position
			_base_shadow = shadow_offset
			pivot_offset = size * 0.5
			scale = Vector2(1.012, 1.012)
			shadow_offset = _base_shadow + Vector2(3, 4)
			queue_redraw()
			bring_to_front()
			accept_event()
		elif _dragging:
			_dragging = false
			var moved := _drag_moved
			var tw := create_tween().set_parallel(true)
			tw.tween_property(self, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			shadow_offset = _base_shadow
			queue_redraw()
			if moved:
				drag_finished.emit(str(item.get("id", "")), mb.global_position)
			elif !expanded:
				expand()
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var delta := (event as InputEventMouseMotion).global_position - _press_pos
		if delta.length() > 4.0:
			_drag_moved = true
		if _drag_moved:
			position = _press_origin + delta
			_clamp()
			drag_moved.emit(str(item.get("id", "")), (event as InputEventMouseMotion).global_position)
		accept_event()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if expanded:
		_build_doc()
	else:
		_build_card()
	queue_redraw()

func _build_card() -> void:
	size = CARD_SIZE
	var tr: Dictionary = PROP.traits(str(item.get("kind", "")), item)
	var accent: Color = tr.accent_color
	var shape := str(tr.get("shape", "schedule"))
	bg_texture = null
	bg_color = Color(0, 0, 0, 0)
	border_width = 0
	shadow_offset = Vector2.ZERO
	inner_highlight = Color(0, 0, 0, 0)
	var shell := MATERIAL_SHELL.new()
	add_child(shell)
	Ui.place(shell, 0, 0, CARD_SIZE.x, CARD_SIZE.y)
	shell.setup(shape, tr)
	var icon := MATERIAL_ICON.new()
	add_child(icon)
	var icon_pos := Vector2(14, 20)
	var icon_size := Vector2(28, 28)
	var label_pos := Vector2(48, 24)
	var label_color := Color("#2b2418")
	match shape:
		"book":
			icon_pos = Vector2(24, 21)
			icon_size = Vector2(25, 25)
			label_pos = Vector2(53, 24)
			label_color = Color("#2b2418")
		"ticket":
			icon_pos = Vector2(12, 20)
			icon_size = Vector2(28, 28)
			label_pos = Vector2(47, 24)
			label_color = Color("#2b2418")
		"envelope":
			icon_pos = Vector2(13, 34)
			icon_size = Vector2(26, 26)
			label_pos = Vector2(47, 39)
			label_color = Color("#2b2418")
		_:
			icon_pos = Vector2(14, 20)
			icon_size = Vector2(28, 28)
			label_pos = Vector2(48, 24)
	Ui.place(icon, icon_pos.x, icon_pos.y, icon_size.x, icon_size.y)
	icon.configure(str(tr.get("icon", "form")), accent if shape != "book" else Color("#3a2b1d"))
	var short := Ui.label(self, str(tr.get("short", "文件")), 0, 0, 0, 18, 13, label_color,
		Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	short.position = label_pos
	short.size = Vector2(68, 18)
	short.clip_text = true
	short.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if shape == "schedule":
		var rule := ColorRect.new()
		rule.color = Color(accent.r, accent.g, accent.b, 0.55)
		rule.position = Vector2(label_pos.x, label_pos.y + 17)
		rule.size = Vector2(42, 2)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rule)

func _build_doc() -> void:
	size = DOC_SIZE
	var tr: Dictionary = PROP.traits(str(item.get("kind", "")), item)
	var accent: Color = tr.accent_color
	bg_texture = Ui.TEX_PAPER
	bg_color = tr.paper_color
	border_width = 3
	border_color = Color("#1b1710")
	shadow_offset = Vector2(5, 6)
	shadow_color = Color(0, 0, 0, 0.45)
	inner_highlight = Color(1, 1, 1, 0.20)
	var stripe := ColorRect.new()
	stripe.color = accent
	stripe.position = Vector2.ZERO
	stripe.size = Vector2(3, DOC_SIZE.y)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stripe)
	var band := ColorRect.new()
	band.color = accent
	band.position = Vector2(3, 0)
	band.size = Vector2(DOC_SIZE.x - 3, HEADER_H)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var icon_box := Ui.panel(self, 8, 2, 20, 20, Color(1, 1, 1, 0.12), 1, Color("#f7e9c8"), Vector2.ZERO)
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := MATERIAL_ICON.new()
	icon_box.add_child(icon)
	Ui.place(icon, 1, 1, 18, 18)
	icon.configure(str(tr.get("icon", "form")), Color("#f7e9c8"))
	var title := Ui.label(self, str(item.get("title", "文件")), 0, 0, 0, 17, 11.5, Color("#f7e9c8"),
		Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	title.position = Vector2(33, 3)
	title.size = Vector2(216, 17)
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stock := Ui.label(self, PROP.stock_line(tr), 0, 0, 0, 10, 7.2, Color(1, 1, 1, 0.76),
		Ui.F_MONO, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_TOP, false)
	stock.position = Vector2(252, 6)
	stock.size = Vector2(78, 10)
	stock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sub := Ui.label(self, str(item.get("sub", "ITEM")), 0, 0, 0, 11, 7.2, Color(1, 1, 1, 0.70),
		Ui.F_MONO, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_TOP, false)
	sub.position = Vector2(330, 5)
	sub.size = Vector2(74, 12)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var close := Ui.button(self, 414, 2, 38, 20, "收起", 7.5, Color("#f4e5c4"), Color("#3a2b1d"),
		Color("#17130d"), Ui.F_UI_BOLD, Vector2(1, 1))
	close.pressed.connect(collapse)
	var body := Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position = Vector2(10, HEADER_H + 6)
	body.size = Vector2(DOC_SIZE.x - 20, DOC_SIZE.y - HEADER_H - 42)
	add_child(body)
	if body_builder.is_valid():
		body_builder.call(item, body)
	_add_item_tools()

func _add_item_tools() -> void:
	var y := DOC_SIZE.y - 30.0
	var note := LineEdit.new()
	note.position = Vector2(10, y)
	note.size = Vector2(196, 22)
	note.text = str(item.get("note", ""))
	note.placeholder_text = "手写批注…"
	note.max_length = 40
	note.mouse_filter = Control.MOUSE_FILTER_STOP
	note.add_theme_font_override("font", Ui.F_DOC)
	note.add_theme_font_size_override("font_size", Ui.scaled_font(8))
	note.add_theme_color_override("font_color", Color("#3b3021"))
	note.add_theme_color_override("font_placeholder_color", Color(90 / 255.0, 74 / 255.0, 46 / 255.0, 0.55))
	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(255, 255, 255, 0.18)
	ns.border_width_left = 1
	ns.border_width_top = 1
	ns.border_width_right = 1
	ns.border_width_bottom = 1
	ns.border_color = Color(93 / 255.0, 75 / 255.0, 46 / 255.0, 0.45)
	ns.content_margin_left = 5
	ns.content_margin_right = 4
	ns.content_margin_top = 3
	ns.content_margin_bottom = 3
	note.add_theme_stylebox_override("normal", ns)
	var focus := ns.duplicate()
	focus.border_color = Color("#8b382b")
	note.add_theme_stylebox_override("focus", focus)
	note.text_changed.connect(func(text: String):
		item["note"] = text
		item_changed.emit(str(item.get("id", "")))
	)
	add_child(note)
	var stamps := [["已阅", "#3f6b45"], ["缓办", "#8a5b22"], ["驳回", "#8b382b"]]
	var x := 214.0
	for pair in stamps:
		var b := Ui.button(self, x, y, 42, 22, str(pair[0]), 7.5, Color("#f5e7c5"),
			Color(str(pair[1])), Color("#17130d"), Ui.F_UI_BOLD, Vector2(1, 1))
		b.pressed.connect(_set_stamp.bind(str(pair[0])))
		x += 46.0
	var archive := Ui.button(self, 360, y, 88, 22,
		"取回" if bool(item.get("archived", false)) else "归档", 7.5,
		Color("#3f321d"), Color("#d9c8a0"), Color("#6e6046"), Ui.F_UI_BOLD, Vector2(1, 1))
	archive.pressed.connect(func(): archive_requested.emit(str(item.get("id", ""))))

func _set_stamp(stamp: String) -> void:
	item["stamp"] = stamp
	item_changed.emit(str(item.get("id", "")))
	if !expanded:
		return
	var seal := PixelPanel.new()
	seal.bg_color = Color(0, 0, 0, 0)
	seal.border_width = 2
	seal.border_color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.86)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.rotation = deg_to_rad(-7)
	seal.z_index = 40
	Ui.place(seal, 300, 56, 76, 42)
	seal.pivot_offset = Vector2(38, 21)
	seal.modulate.a = 0.0
	seal.scale = Vector2(1.25, 1.25)
	add_child(seal)
	Ui.pixel(seal, stamp, 0, 3, 76, 16, 12, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.9),
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	Ui.pixel(seal, "03", 0, 22, 76, 10, 7, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.78),
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(seal, "modulate:a", 1.0, 0.10)
	tw.tween_property(seal, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.7)
	tw.chain().tween_property(seal, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(seal.queue_free)

func _badge() -> String:
	match str(item.get("kind", "")):
		"favor":
			return "F"
		"college":
			return "C"
		"schedule":
			return "R"
		"letter":
			return "信"
		"pass":
			return "通"
	return "·"

func _accent() -> Color:
	match str(item.get("kind", "")):
		"favor":
			return Color("#3f6b45")
		"college":
			return Color("#3f6b45")
		"schedule":
			return Color("#6d4a2c")
		"letter":
			return Color("#8b382b")
		"pass":
			return Color("#2d4d78")
	return Color("#7a6847")

func _summary() -> String:
	match str(item.get("kind", "")):
		"favor":
			var total := 0
			if state != null:
				for v in state.favor.values():
					total += int(v)
			return "总 %d" % total
		"college":
			return "6 学部"
		"schedule":
			return "8 项"
		"letter":
			return "第 %d 天" % (int(item.get("day", 0)) + 1)
		"pass":
			return "一次性"
	return ""
