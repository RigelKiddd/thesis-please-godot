extends "res://scripts/PixelPanel.gd"

const MaterialIconCtl := preload("res://scripts/MaterialIcon.gd")

func configure_stock(m: Dictionary, open: bool, hint: String) -> void:
	var id := str(m.get("id", ""))
	var card := self
	bg_color = Color("#f1e3bc") if open else Color("#d8c8a2")
	Ui.place(self, 0, 0, 198, 43)
	card.custom_minimum_size = Vector2(198, 43)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_hover_fill(card, Color("#f1e3bc") if open else Color("#d8c8a2"), Color("#f1e3bc") if open else Color("#e9dbb6"))
	if open:
		Ui.hline(card, 0, 0, 3, Ui.RED, 43)
	var icon := _box(card, 5, 7, 27, 29, Color("#9c392d") if open else Color("#c1ab7c"), null, 1, Color("#5c1e17") if open else Color("#6a5739"))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material_icon(icon, 1, 1, 25, 27, m, Color("#f3e2bd") if open else Color("#5d472a"))
	Ui.pixel(card, str(m.get("label", "")), 38, 9, 130, 15, 11, Color("#322a1c"))
	Ui.pixel(card, hint, 38, 23, 140, 12, 8, Color("#776545"))
	Ui.pixel(card, "●" if open else "›", 172, 13, 14, 16, 12, Color("#8a3b2f"), HORIZONTAL_ALIGNMENT_CENTER)
	card.set_meta("material_id", id)

func configure_request(task: Dictionary, doc: Dictionary, index: int, open: bool) -> void:
	var task_id := str(task.get("id", ""))
	var doc_id := str(doc.get("id", ""))
	var cid := "req:%s:%s" % [task_id, doc_id]
	var style := str(doc.get("style", "certificate"))
	var bg := Color("#f1e3bc")
	var accent := Color("#b08a3e")
	match style:
		"sealed":
			bg = Color("#f6efdc")
			accent = Color("#a83a2f")
		"mimeo":
			bg = Color("#dcd8ca")
			accent = Color("#2e312c")
		"carbonless":
			bg = Color("#dce8ee")
			accent = Color("#2d4d78")
		"cardstock":
			bg = Color("#d9b98a")
			accent = Color("#8b382b")
	var card := self
	bg_color = bg if !open else bg.lightened(0.06)
	Ui.place(self, 0, 0, 198, 46)
	card.custom_minimum_size = Vector2(198, 46)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.set_meta("material_id", cid)
	card.set_meta("request_doc", doc_id)
	card.set_meta("task_id", task_id)
	_hover_fill(card, bg if !open else bg.lightened(0.06), bg.lightened(0.09))
	Ui.hline(card, 0, 0, 4, accent, 46)
	var icon := _box(card, 7, 8, 27, 30, Color(accent.r, accent.g, accent.b, 0.16), null, 1, accent)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material_icon(icon, 1, 1, 25, 28, doc, accent)
	var card_title := str(doc.get("tab", "材料"))
	if index == 0:
		card_title = "待办 · %s" % str(task.get("variant", ""))
	Ui.pixel(card, card_title, 40, 7, 118, 16, 10, Color("#322a1c"))
	var card_sub := "%s%s" % [str(doc.get("tab", "材料")), " · 已展开" if open else ""]
	Ui.pixel(card, card_sub, 40, 24, 136, 12, 7, Color("#776545"))
	if index == 0:
		var tag := _box(card, 160, 5, 28, 14, Color("#a83a2f"), null, 1, Color("#481611"))
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Ui.pixel(tag, "待办", 0, 1, 28, 12, 7, Color("#f4e3c3"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	else:
		Ui.pixel(card, "›", 178, 13, 12, 18, 13, Color("#8a3b2f"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

func _hover_fill(p: PixelPanel, base: Color, hover: Color) -> void:
	p.bg_color = base
	p.mouse_entered.connect(_set_background.bind(hover))
	p.mouse_exited.connect(_set_background.bind(base))

func _set_background(color: Color) -> void:
	bg_color = color
	queue_redraw()

func _material_icon(parent: Control, x: float, y: float, w: float, h: float, doc: Dictionary, color: Color) -> Control:
	var icon := MaterialIconCtl.new()
	parent.add_child(icon)
	Ui.place(icon, x, y, w, h)
	icon.configure(MaterialIconCtl.key_for_doc(doc), color)
	return icon

func _box(parent: Node, x: float, y: float, w: float, h: float, bg: Color, tex: Texture2D = null, border: int = 0, edge: Color = Color.BLACK, shadow: Vector2 = Vector2.ZERO) -> PixelPanel:
	return Ui.panel(parent, x, y, w, h, bg, border, edge, shadow, Color(0, 0, 0, 0.38), tex)
