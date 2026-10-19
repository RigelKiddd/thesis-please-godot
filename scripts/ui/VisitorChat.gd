class_name VisitorChat
extends "res://scripts/PixelPanel.gd"

## The whole visitor conversation lives here: statement, ask, options,
## attachment drop target and receipt.  No modal: the desk stays visible, and
## the player can drag a prop document from the folder into the composer.

signal option_chosen(index: int)
signal item_attached(id: String)
signal item_cleared
signal next_requested

const MATERIAL_ICON := preload("res://scripts/MaterialIcon.gd")
const PROP := preload("res://scripts/PropMaterial.gd")
const W := 741.0
const H := 274.0
const HEAD_H := 40.0
const BODY_Y := 46.0
const BODY_H := 86.0
const OPT_Y := 136.0
const COMPOSER_Y := 228.0

var _v: Dictionary = {}
var _role: Dictionary = {}
var _name := ""
var _index := 1
var _total := 1
var _state: Dictionary = {}
var _items: Array = []
var _attached := ""
var _resolved := false
var _head_title: Label
var _head_status: Label
var _head_budget: Label
var _head_stamp: Label
var _drag := false
var _drag_offset := Vector2.ZERO
var _scroll: ScrollContainer
var _messages: VBoxContainer
var _options_box: VBoxContainer
var _composer: PixelPanel
var _drop_label: Label
var _next_btn: Button
var _tip: PixelPanel


func _ready() -> void:
	super._ready()
	z_index = 20
	bg_color = Color("#efe2c4")
	border_width = 3
	border_color = Color("#1b1710")
	shadow_offset = Vector2(5, 6)
	shadow_color = Color(0, 0, 0, 0.45)
	inner_highlight = Color(1, 1, 1, 0.34)
	size = Vector2(W, H)
	_build()


func _build() -> void:
	var head := _box(self, 0, 0, W, HEAD_H, Color("#e5d5b2"), 0, Color("#5d4b2e"))
	head.mouse_filter = Control.MOUSE_FILTER_STOP
	head.mouse_default_cursor_shape = Control.CURSOR_DRAG
	head.gui_input.connect(_on_head_input)
	var accent := ColorRect.new()
	accent.color = Color("#a83a2f")
	accent.position = Vector2(0, 0)
	accent.size = Vector2(4, HEAD_H)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(accent)
	var grip := _box(head, 7, 4, 17, 32, Color(0, 0, 0, 0), 1, Color("#a08a5e"))
	grip.mouse_filter = Control.MOUSE_FILTER_STOP
	grip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	grip.gui_input.connect(_on_head_input)
	Ui.pixel(grip, "⋮", 0, 7, 17, 18, 11, Color("#6d5a3c"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	Ui.pixel(head, "来访登记 / VISITOR", 30, 4, 200, 10, 7.5, Color("#7a6847"))
	_head_title = Ui.pixel(head, "来访登记", 30, 14, 140, 18, 13, Color("#2b2418"))
	_head_status = Ui.pixel(head, "等待来访", 178, 18, 242, 11, 8.5, Color("#5a4a33"))
	_head_budget = Ui.pixel(head, "", 436, 7, 210, 11, 8, Color("#5a4a33"), HORIZONTAL_ALIGNMENT_RIGHT)
	var stamp := _box(head, 656, 5, 68, 30, Color(0, 0, 0, 0), 2, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.82))
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.rotation = deg_to_rad(-3)
	Ui.pixel(stamp, "来 访", 0, 2, 68, 10, 7.5, Color("#a83a2f"), HORIZONTAL_ALIGNMENT_CENTER)
	_head_stamp = Ui.pixel(stamp, "待 批", 0, 13, 68, 12, 9, Color("#a83a2f"), HORIZONTAL_ALIGNMENT_CENTER)
	Ui.hline(self, 0, HEAD_H - 1, W, Color(93 / 255.0, 75 / 255.0, 46 / 255.0, 0.35), 1)
	for l in [_head_title, _head_status, _head_budget, _head_stamp]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_scroll = ScrollContainer.new()
	add_child(_scroll)
	Ui.place(_scroll, 12, BODY_Y, W - 24, BODY_H)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var margin := Ui.margin(_scroll, 2, 2, 4, 2)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_messages = VBoxContainer.new()
	_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_messages.add_theme_constant_override("separation", 4)
	margin.add_child(_messages)

	_options_box = VBoxContainer.new()
	add_child(_options_box)
	Ui.place(_options_box, 12, OPT_Y, W - 24, 86)
	_options_box.add_theme_constant_override("separation", 3)

	_composer = _box(self, 12, COMPOSER_Y, W - 24, 36, Color("#e7d8b7"), 1, Color("#7a6847"))
	_composer.inner_highlight = Color(1, 1, 1, 0.28)
	_drop_label = Ui.pixel(_composer, "＋ 把材料拖到这里", 12, 9, 360, 16, 8.5, Color("#6d5a3c"))
	_next_btn = Ui.button(self, 12, COMPOSER_Y, W - 24, 36, "下一位", 11, Color("#f5e7c5"), Color("#91362d"), Color("#38100d"), Ui.F_UI_BOLD, Vector2(3, 3))
	_next_btn.visible = false
	_next_btn.pressed.connect(func(): next_requested.emit())

	_tip = PixelPanel.new()
	add_child(_tip)
	_tip.bg_color = Color("#171d15")
	_tip.border_width = 2
	_tip.border_color = Color("#b79a63")
	_tip.shadow_offset = Vector2(4, 5)
	_tip.shadow_color = Color(0, 0, 0, 0.55)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = 300
	_tip.visible = false


func _on_head_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag = true
				_drag_offset = get_global_position() - mb.global_position
				accept_event()
			else:
				_drag = false
	elif event is InputEventMouseMotion and _drag:
		var mm := event as InputEventMouseMotion
		var target := mm.global_position + _drag_offset
		var parent_size: Vector2 = get_parent().size if get_parent() != null else Vector2(1380, 860)
		position = Vector2(
			clampf(target.x, 0, maxf(0, parent_size.x - size.x)),
			clampf(target.y, 70, maxf(70, parent_size.y - size.y))
		)
		accept_event()


func show_visitor(v: Dictionary, role: Dictionary, display_name: String, index: int, total: int,
		state: Dictionary, items: Array, attached: String = "") -> void:
	_v = v
	_role = role
	_name = display_name
	_index = index
	_total = total
	_state = state
	_items = items
	_attached = attached
	_resolved = false
	visible = true
	pivot_offset = size * 0.5
	modulate.a = 0.0
	scale = Vector2(0.985, 0.985)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_head_title.text = "来访登记"
	_head_status.text = "%s · %s · 第 %d/%d 位" % [display_name, str(role.get("role", "来访")), index, total]
	_head_stamp.text = "待 批"
	_head_budget.text = "精力 %d · 金钱 %d" % [int(state.get("energy", 0)), int(state.get("money", 0))]
	_clear_messages()
	_add_system("来访人 %s · %s · 03 窗口" % [display_name, str(role.get("role", "来访"))])
	var attached_item := _item_of(_attached)
	if !attached_item.is_empty():
		if str(attached_item.get("stamp", "")) != "":
			_add_system("随附材料批注：%s" % str(attached_item.get("stamp", "")))
		if str(attached_item.get("note", "")) != "":
			_add_system("上次手写：%s" % str(attached_item.get("note", "")))
	for para in v.get("story", []):
		_add_message(str(para))
	var ask := str(v.get("ask", ""))
	if ask != "":
		_add_message(ask)
	_clear_options()
	_build_options(v.get("options", []))
	_composer.visible = true
	_next_btn.visible = false
	_render_composer()
	_tip.visible = false


func show_result(opt: Dictionary, is_last: bool) -> void:
	_resolved = true
	_attached = ""
	var tag := str(opt.get("tag", "批"))
	_head_title.text = "来访回执"
	_head_status.text = "%s · 第 %d/%d 位" % [_name, _index, _total]
	_head_stamp.text = "已 %s" % tag
	_head_stamp.add_theme_color_override("font_color", Color("#3f6b45") if tag == "批" else (Color("#9b3127") if tag == "驳" else Color("#a56a22")))
	_clear_options()
	_composer.visible = false
	_next_btn.visible = true
	_next_btn.text = "去排班" if is_last else "下一位"
	_next_btn.disabled = false
	_clear_messages()
	_add_system("来访回执 · 第 %d/%d 位" % [_index, _total])
	var result := str(opt.get("result", ""))
	if result != "":
		_add_message(result)
	var summary := _effect_lines(opt, true)
	if summary != "":
		_add_system(summary)
	_tip.visible = false


func clear() -> void:
	visible = false
	_resolved = false
	_attached = ""
	_tip.visible = false


func is_resolved() -> bool:
	return _resolved


func set_budget(energy: int, money: int) -> void:
	if _head_budget != null:
		_head_budget.text = "精力 %d · 金钱 %d" % [energy, money]


func get_drop_rect() -> Rect2:
	if _composer == null or !visible or _resolved:
		return Rect2()
	return get_global_rect()


func set_drop_hover(on: bool) -> void:
	if _composer == null:
		return
	_composer.bg_color = Color("#f4e6c4") if on else Color("#e7d8b7")
	_composer.border_color = Color("#a83a2f") if on else Color("#7a6847")
	_composer.queue_redraw()
	if _drop_label != null:
		_drop_label.text = "松开提交这份材料" if on else "＋ 把材料拖到这里"
		_drop_label.add_theme_color_override("font_color", Color("#8b382b") if on else Color("#6d5a3c"))


func attach_item(id: String) -> void:
	if id == "" or _resolved:
		return
	var item := _item_of(id)
	if item.is_empty():
		return
	_attached = id
	_render_composer()
	item_attached.emit(id)


func clear_attachment() -> void:
	if _attached == "":
		return
	_attached = ""
	_render_composer()
	item_cleared.emit()


func _render_composer() -> void:
	for child in _composer.get_children():
		_composer.remove_child(child)
		child.queue_free()
	_drop_label = null
	if _attached == "":
		_drop_label = Ui.pixel(_composer, "＋ 拖材料到这里", 12, 9, 420, 16, 8.5, Color("#8f9d83"))
		return
	var item := _item_of(_attached)
	if item.is_empty():
		return
	var tr: Dictionary = PROP.traits(str(item.get("kind", "")), item)
	var accent: Color = tr.accent_color
	var chip := _box(_composer, 4, 4, 350, 28, tr.paper_color, 1, accent)
	chip.inner_highlight = Color(1, 1, 1, 0.24)
	var icon_box := _box(chip, 4, 4, 20, 20, Color(accent.r, accent.g, accent.b, 0.14), 1, accent)
	var icon := MATERIAL_ICON.new()
	icon_box.add_child(icon)
	Ui.place(icon, 1, 1, 18, 18)
	icon.configure(str(tr.get("icon", "form")), accent)
	Ui.pixel(chip, str(item.get("title", _attached)), 28, 4, 250, 11, 9, Color("#2b2418"))
	Ui.pixel(chip, "%s · 随决定提交" % PROP.stock_line(tr), 28, 15, 250, 9, 6.2, Color("#6d5a3c"))
	var x := Ui.button(chip, 322, 4, 20, 20, "×", 11, Color("#f4e5c4"), Color("#7a3028"), Color("#2c0f0c"), Ui.F_UI_BOLD, Vector2.ZERO)
	x.pressed.connect(clear_attachment)
	Ui.pixel(_composer, "已附一份，点 × 可取消", 370, 11, 300, 14, 7.5, Color("#6d5a3c"))


func _item_of(id: String) -> Dictionary:
	for raw in _items:
		if str(raw.get("id", "")) == id:
			return raw
	return {}


func _clear_messages() -> void:
	for child in _messages.get_children():
		_messages.remove_child(child)
		child.queue_free()


func _add_system(text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#d9ccb1")
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#b9ae96")
	sb.content_margin_left = 7
	sb.content_margin_top = 2
	sb.content_margin_right = 7
	sb.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sb)
	var l := Ui.label(panel, text, 0, 0, 0, 12, 7.5, Color("#5b4d38"), Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	l.custom_minimum_size.x = 520
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(panel)
	_messages.add_child(row)
	scroll_bottom()


func _add_message(text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 7)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ColorRect.new()
	bar.color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.55)
	bar.custom_minimum_size = Vector2(2, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	var l := Ui.label(row, text, 0, 0, 0, 0, 9.5, Color("#3b3021"), Ui.F_DOC,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	l.custom_minimum_size.x = 678
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", 2)
	_messages.add_child(row)
	scroll_bottom()


func scroll_bottom() -> void:
	if _scroll != null:
		_scroll.set_deferred("scroll_vertical", 100000)


func _clear_options() -> void:
	for child in _options_box.get_children():
		_options_box.remove_child(child)
		child.queue_free()


func _build_options(options: Array) -> void:
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var tag := str(opt.get("tag", "批"))
		var tag_color := Color("#8fc08a") if tag == "批" else (Color("#d98f7f") if tag == "驳" else Color("#d9b06f"))
		var affordable := int(_state.get("energy", 0)) + int(opt.get("energy", 0)) >= 0 \
			and int(_state.get("money", 0)) + int(opt.get("money", 0)) >= 0
		var row := _box(_options_box, 0, 0, W - 20, 26, Color("#e7d8b7"), 1, Color("#7a6847"))
		row.custom_minimum_size = Vector2(W - 20, 26)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if affordable else Control.CURSOR_ARROW
		row.inner_highlight = Color(1, 1, 1, 0.28)
		var stripe := ColorRect.new()
		stripe.color = tag_color
		stripe.position = Vector2.ZERO
		stripe.size = Vector2(3, 26)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(stripe)
		var stamp := _box(row, 5, 3, 20, 20, Color(tag_color.r, tag_color.g, tag_color.b, 0.13), 1, tag_color)
		Ui.pixel(stamp, tag, 0, 0, 20, 20, 10, tag_color, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		var label := Ui.pixel(row, str(opt.get("label", "")), 32, 4, 660, 16, 10.5, Color("#2b2418"))
		label.clip_text = true
		Ui.pixel(row, "▸", 706, 3, 12, 18, 10, Color("#8a3b2f"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		if !affordable:
			row.modulate = Color(1, 1, 1, 0.45)
		var oi := i
		row.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and affordable:
					option_chosen.emit(oi)
					row.accept_event()
		)
		row.mouse_entered.connect(func():
			if is_instance_valid(row):
				row.bg_color = Color("#f4e6c4") if affordable else Color("#e7d8b7")
				row.queue_redraw()
				_show_tip(opt, row, affordable)
		)
		row.mouse_exited.connect(func():
			if is_instance_valid(row):
				row.bg_color = Color("#e7d8b7")
				row.queue_redraw()
			_tip.visible = false
		)


func _show_tip(opt: Dictionary, row: Control, affordable: bool) -> void:
	for child in _tip.get_children():
		_tip.remove_child(child)
		child.queue_free()
	var tag := str(opt.get("tag", "批"))
	var tag_color := Color("#8fc08a") if tag == "批" else (Color("#d98f7f") if tag == "驳" else Color("#d9b06f"))
	var stamp := _box(_tip, 10, 9, 20, 20, Color(tag_color.r, tag_color.g, tag_color.b, 0.16), 1, tag_color)
	Ui.pixel(stamp, tag, 0, 0, 20, 20, 10, tag_color, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	var title := Ui.label(_tip, str(opt.get("label", "")), 0, 0, 0, 15, 9.5, Color("#f0e3c2"), Ui.F_UI_BOLD,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	title.position = Vector2(37, 10)
	title.size = Vector2(270, 15)
	title.clip_text = true
	var y := 35.0
	_rule(y)
	y += 6
	var fav: Dictionary = opt.get("favor", {})
	var has_fav := false
	for key in fav:
		if int(fav[key]) != 0:
			has_fav = true
			break
	if has_fav:
		_section("人情", y)
		y += 11
		for key in fav:
			var delta := int(fav[key])
			if delta == 0:
				continue
			var who := str(AllocationModel.role(str(key)).get("name", key))
			_pair(who, "%s%d" % ["+" if delta > 0 else "−", absi(delta)], y, Color("#b7e6a2") if delta > 0 else Color("#efa091"))
			y += 15
	var perf := int(opt.get("perf", 0))
	var energy := int(opt.get("energy", 0))
	var money := int(opt.get("money", 0))
	var rep := int(opt.get("rep", 0))
	if perf != 0 or energy != 0 or money != 0 or rep != 0:
		_section("收支", y)
		y += 11
		if perf != 0:
			_pair("绩效", "%s¥%s" % ["+" if perf > 0 else "−", Ui.fmt_money(absi(perf))], y, Color("#b7e6a2") if perf > 0 else Color("#efa091"))
			y += 15
		if energy != 0:
			_pair("精力", "%s%d" % ["+" if energy > 0 else "−", absi(energy)], y, Color("#b7e6a2") if energy > 0 else Color("#efa091"))
			y += 15
		if money != 0:
			_pair("金钱", "%s%d" % ["+" if money > 0 else "−", absi(money)], y, Color("#b7e6a2") if money > 0 else Color("#efa091"))
			y += 15
		if rep != 0:
			_pair("声誉", "%s%d" % ["+" if rep > 0 else "−", absi(rep)], y, Color("#b7e6a2") if rep > 0 else Color("#efa091"))
			y += 15
	if _attached != "":
		var item := _item_of(_attached)
		if !item.is_empty():
			_section("随附", y)
			y += 11
			_pair(str(item.get("title", "")), "", y, Color("#d9c48a"))
			y += 15
			_pair("对方人情 / 绩效", "+%d / +¥%s" % [int(item.get("submit_favor", 1)), Ui.fmt_money(int(item.get("submit_perf", 20)))], y, Color("#d9c48a"))
			y += 15
	if tag == "缓":
		_pair("附赠", "临时通行条", y, Color("#9fc0e8"))
		y += 15
	if !affordable:
		_pair("余额", "不足，无法选择", y, Color("#efa091"))
		y += 15
	_tip.size = Vector2(320, y + 8)
	var local := row.get_global_rect().position - global_position
	var tip_x := -_tip.size.x - 10.0
	if get_global_position().x + tip_x < 8:
		tip_x = size.x + 10.0
	var ty := local.y - 10.0
	_tip.position = Vector2(tip_x, clampf(ty, 4, H - _tip.size.y - 4))
	_tip.visible = true


func _rule(y: float) -> void:
	var line := ColorRect.new()
	line.color = Color(183 / 255.0, 154 / 255.0, 99 / 255.0, 0.28)
	line.position = Vector2(10, y)
	line.size = Vector2(300, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(line)


func _section(text: String, y: float) -> void:
	var l := Ui.label(_tip, text, 0, 0, 0, 10, 7, Color("#95a287"), Ui.F_UI_BOLD,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	l.position = Vector2(10, y)
	l.size = Vector2(300, 10)


func _pair(label: String, value: String, y: float, color: Color) -> void:
	var l := Ui.label(_tip, label, 0, 0, 0, 12, 8, Color("#d8cbaa"), Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	l.position = Vector2(10, y)
	l.size = Vector2(190, 12)
	l.clip_text = true
	if value != "":
		var v := Ui.label(_tip, value, 0, 0, 0, 12, 8.5, color, Ui.F_UI_BOLD,
			HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_TOP, false)
		v.position = Vector2(198, y)
		v.size = Vector2(112, 12)


func _effect_lines(opt: Dictionary, compact: bool = false) -> String:
	var parts: Array = []
	var fav: Dictionary = opt.get("favor", {})
	for key in fav:
		var delta := int(fav[key])
		if delta == 0:
			continue
		var who := str(AllocationModel.role(str(key)).get("name", key))
		parts.append("%s %s%d" % [who, "+" if delta > 0 else "−", absi(delta)])
	var perf := int(opt.get("perf", 0))
	if perf != 0:
		parts.append("绩效 %s¥%s" % ["+" if perf > 0 else "−", Ui.fmt_money(absi(perf))])
	var energy := int(opt.get("energy", 0))
	if energy != 0:
		parts.append("精力 %s%d" % ["+" if energy > 0 else "−", absi(energy)])
	var money := int(opt.get("money", 0))
	if money != 0:
		parts.append("金钱 %s%d" % ["+" if money > 0 else "−", absi(money)])
	var rep := int(opt.get("rep", 0))
	if rep != 0:
		parts.append("声誉 %s%d" % ["+" if rep > 0 else "−", absi(rep)])
	if parts.is_empty():
		return ""
	return " · ".join(PackedStringArray(parts))


func _box(parent: Node, x: float, y: float, w: float, h: float, bg: Color, border: int = 0, edge: Color = Color.BLACK) -> PixelPanel:
	return Ui.panel(parent, x, y, w, h, bg, border, edge, Vector2.ZERO, Color(0, 0, 0, 0.35))
