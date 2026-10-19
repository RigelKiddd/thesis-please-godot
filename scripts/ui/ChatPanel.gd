extends "res://scripts/PixelPanel.gd"

signal reply_selected(index: int)
var chat_avatar: Label
var chat_title: Label
var chat_status: Label
var chat_scroll: ScrollContainer
var chat_box: VBoxContainer
var chat_reply_btns: Array = []
var chat_auto_note: Label

func _ready() -> void:
	super._ready()
	self.z_index = 5
	var chat_head: PixelPanel = $Header
	var avatar := _box(chat_head, 8, 5, 22, 22, Color("#4e6d4f"), null, 1, Color("#1a1f18"))
	chat_avatar = Ui.pixel(avatar, "生", 0, 0, 22, 22, 8, Color("#f0e6ce"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	chat_title = Ui.pixel(chat_head, "学生消息", 38, 4, 180, 13, 11, Color("#e7dcc1"))
	chat_status = Ui.pixel(chat_head, "正在输入“", 38, 17, 220, 10, 8, Color("#9fb39d"))
	Ui.pixel(chat_head, "微信", 350, 9, 80, 12, 10, Color("#aebfa9"), HORIZONTAL_ALIGNMENT_RIGHT)
	chat_scroll = $Scroll
	chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var cm := Ui.margin(chat_scroll, 7, 6, 5, 8)
	cm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_box = VBoxContainer.new()
	chat_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_box.add_theme_constant_override("separation", 4)
	cm.add_child(chat_box)
	var reply_labels := ["按清单核对", "最担心哪项？", "先放桌上"]
	chat_reply_btns.clear()
	for i in range(4):
		var b := Ui.button(self, 8 + i * 140, 174, 132, 26, reply_labels[i] if i < 3 else "", 9, Color("#cbb887"), Color("#2c2116"), Color("#5d4b2e"), Ui.F_PIXEL, Vector2.ZERO)
		b.visible = false
		b.clip_text = true
		b.pressed.connect(func(): reply_selected.emit(i))
		if i == 1:
			b.tooltip_text = "仅一次：让学生说出最担心的一项"
		chat_reply_btns.append(b)
	chat_auto_note = Ui.pixel(self, "已自动回复", 10, 177, 421, 16, 8, Color("#6f654e"))
	chat_auto_note.visible = false


## Reused by the between-days visitor screen: repaint the header without the
## student-chat flow.
func set_header(title: String, status: String, seal: String) -> void:
	if chat_title != null:
		chat_title.text = title
	if chat_status != null:
		chat_status.text = status
	if chat_avatar != null:
		chat_avatar.text = seal


func clear_messages() -> void:
	for child in chat_box.get_children():
		child.queue_free()
	for b in chat_reply_btns:
		b.visible = false
	if chat_auto_note != null:
		chat_auto_note.visible = false


func add_system(text: String) -> void:
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
	sb.content_margin_top = 3
	sb.content_margin_right = 7
	sb.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", Ui.F_DOC)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color("#5b4d38"))
	l.custom_minimum_size.x = 250
	panel.add_child(l)
	row.add_child(panel)
	chat_box.add_child(row)
	chat_scroll.set_deferred("scroll_vertical", 100000)


func add_message(text: String, mine: bool = false) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var av := _box(row, 0, 0, 20, 20, Color("#8a5b22") if mine else Color("#4e6d4f"), null, 1, Color("#1a1f18"))
	av.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	Ui.pixel(av, "我" if mine else chat_avatar.text, 0, 0, 20, 20, 8, Color("#f0e6ce"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	var bubble := PanelContainer.new()
	bubble.custom_minimum_size.x = 280
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END if mine else Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#a9cf88") if mine else Color("#f5f1e3")
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#7e9b62") if mine else Color("#b9ae96")
	sb.content_margin_left = 7
	sb.content_margin_top = 5
	sb.content_margin_right = 7
	sb.content_margin_bottom = 5
	bubble.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", Ui.F_DOC)
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color("#3b3021") if !mine else Color("#26301f"))
	l.custom_minimum_size.x = 280
	l.add_theme_constant_override("line_spacing", 2)
	bubble.add_child(l)
	row.add_child(bubble)
	chat_box.add_child(row)
	chat_scroll.set_deferred("scroll_vertical", 100000)

func _box(parent: Node, x: float, y: float, w: float, h: float, bg: Color, tex: Texture2D = null, border: int = 0, edge: Color = Color.BLACK, shadow: Vector2 = Vector2.ZERO) -> PixelPanel:
	return Ui.panel(parent, x, y, w, h, bg, border, edge, shadow, Color(0, 0, 0, 0.38), tex)
