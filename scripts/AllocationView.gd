extends Control

## The between-days allocation screen, rebuilt on the main desk layout (v1.18).
##
## The top-left rules book becomes the project book; the student dossier card
## becomes the roster/budget card.  The central folder and right rail hold the
## draggable prop documents.  The right-hand WeChat panel and portrait window
## are used by visitors, while the visitor registration slip opens as a compact
## left-side popup so the chat and portrait stay readable.

signal finish_requested
signal ledger_requested
signal college_requested
signal changed
signal visitor_option_chosen(index: int)
signal visitor_item_attached(id: String)
signal visitor_item_cleared
signal visitor_next_requested
signal duty_log_requested

const MODEL := preload("res://scripts/AllocationModel.gd")
const COLLEGE := preload("res://scripts/CollegeModel.gd")
const DESK_ITEM := preload("res://scripts/DeskItem.gd")
const PORTRAIT := preload("res://scripts/VisitorPortrait.gd")
const VISITOR_CHAT := preload("res://scripts/ui/VisitorChat.gd")
const PROP := preload("res://scripts/PropMaterial.gd")
const MATERIAL_ICON := preload("res://scripts/MaterialIcon.gd")
const W := 1380.0
const H := 860.0

const RULES_X := 17.0
const RULES_Y := 71.0
const RULES_W := 352.0
const RULES_H := 281.0
const DOSSIER_X := 389.0
const DOSSIER_Y := 96.0
const DOSSIER_W := 287.0
const DOSSIER_H := 254.0
const CHAT_X := 689.0
const CHAT_Y := 140.0
const CHAT_W := 441.0
const CHAT_H := 205.0
const PORTRAIT_X := 1143.0
const PORTRAIT_Y := 97.0
const PORTRAIT_W := 216.0
const PORTRAIT_H := 253.0
const FOLDER_X := 268.0
const FOLDER_Y := 375.0
const FOLDER_W := 760.0
const FOLDER_H := 396.0
const RAIL_X := 1038.0
const RAIL_Y := 375.0
const RAIL_W := 220.0
const RAIL_H := 396.0
const DESK_W := 760.0
const DESK_H := 396.0
const CARD_W := 136.0
const CARD_H := 70.0

var state
var play_cb: Callable
var toast_cb: Callable
var _day := 0
var _day_data: Dictionary = {}
var _built := false
var _project_grid: GridContainer
var _rules_day: Label
var _energy_value: Label
var _money_value: Label
var _alloc_line: Label
var _preview: Label
var _finish_btn: Button
var _chat
var _chat_title: Label
var _chat_status: Label
var _visitor_chat
var _portrait
var _dossier: PixelPanel
var _portrait_name: Label
var _portrait_role: Label
var _desk: Control
var _desk_items: Dictionary = {}
var _rail_list: VBoxContainer
var _archive_mode := false
var _archive_btn: Button
var _bottom_note: Label


func configure(run_state, play: Callable, toast: Callable) -> void:
	state = run_state
	play_cb = play
	toast_cb = toast
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W, H)


func open(day_index: int, day_data: Dictionary) -> void:
	_day = day_index
	_day_data = day_data
	if !_built:
		_build()
		_built = true
	visible = true
	_refresh()
	clear_visitor("等待来访")
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.16)


func close() -> void:
	visible = false
	modulate.a = 1.0


func refresh() -> void:
	if _built:
		_refresh()


func auto_place_all() -> void:
	for row in MODEL.projects():
		var pid := str(row.get("id", ""))
		var cap := int(row.get("cap", 0))
		while int(state.alloc_placed.get(pid, 0)) < cap:
			var coin := str(row.get("coin", "energy"))
			if _coin_left(coin) <= 0:
				break
			_place(pid, true)


func preview_effects() -> Dictionary:
	var effects := MODEL.project_effects(state.alloc_placed)
	var projected: Dictionary = state.favor.duplicate(true)
	for key in effects.get("favor", {}):
		projected[key] = clampi(int(projected.get(key, 0)) + int(effects["favor"][key]), 0, 10)
	effects["flat_perf"] = MODEL.flat_perf(projected)
	return effects


# ============================================================
# BUILD — positions match the main game desk
# ============================================================
func _build() -> void:
	_build_rules()
	_build_dossier()
	_build_chat()
	_build_visitor_chat()
	_build_portrait()
	_build_folder()
	_build_rail()
	_build_bottom()
	_build_sign()


func _build_rules() -> void:
	var book := _panel(self, RULES_X, RULES_Y, RULES_W, RULES_H, Ui.PAPER, 2, Color("#1a1710"), Vector2(4, 5))
	book.inner_highlight = Color(1, 1, 1, 0.38)
	book.bg_texture = Ui.TEX_PAPER
	var clip := _panel(self, 157, 66, 70, 18, Color("#8d8b7c"), 2, Color("#1b1a14"), Vector2.ZERO)
	clip.inner_highlight = Color("#c2beaa")
	var hole := _panel(self, 177, 70, 20, 8, Color("#2d2d26"), 2, Color("#605e51"), Vector2.ZERO)
	_pix(self, "教务处 / 灯灭之前", 32, 83, 250, 12, 8, Color("#6e6046"))
	_pix(self, "明日安排", 32, 98, 240, 22, 17, Color("#2a2419"))
	var ed := _panel(self, 307, 87, 46, 38, Color(0, 0, 0, 0), 2, Ui.RED, Vector2.ZERO)
	ed.rotation = deg_to_rad(3)
	_pix(ed, "第", 3, 6, 10, 12, 9.5, Ui.RED)
	_rules_day = _pix(ed, "1", 13, 1, 18, 18, 16, Ui.RED, HORIZONTAL_ALIGNMENT_CENTER)
	_pix(ed, "夜", 31, 6, 12, 12, 9.5, Ui.RED)
	_pix(ed, "排班", 0, 22, 46, 12, 9.5, Ui.RED, HORIZONTAL_ALIGNMENT_CENTER)

	var scroll := Ui.scroller(self, 33, 132, 321, 197)
	_project_grid = GridContainer.new()
	_project_grid.columns = 2
	_project_grid.add_theme_constant_override("h_separation", 5)
	_project_grid.add_theme_constant_override("v_separation", 4)
	_project_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_project_grid.custom_minimum_size.x = 311
	scroll.add_child(_project_grid)
	var recall := Ui.button(self, 236, 326, 86, 18, "全部收回", 7, Color("#e6d7b5"), Color("#2b3329"), Color("#11150f"), Ui.F_UI, Vector2(1, 1))
	recall.pressed.connect(_recall_all)
	var log_btn := Ui.button(self, 32, 326, 96, 18, "值班日志", 7, Color("#3f321d"), Color("#d9c8a0"), Color("#6e6046"), Ui.F_UI, Vector2(1, 1))
	log_btn.pressed.connect(func(): duty_log_requested.emit())
	_archive_btn = Ui.button(self, 130, 326, 100, 18, "卷宗", 7, Color("#3f321d"), Color("#d9c8a0"), Color("#6e6046"), Ui.F_UI, Vector2(1, 1))
	_archive_btn.pressed.connect(_toggle_archive)


func _build_dossier() -> void:
	_dossier = _panel(self, DOSSIER_X, DOSSIER_Y, DOSSIER_W, DOSSIER_H, Color("#dfd3b1"), 2, Color("#1a1711"), Vector2(4, 5))
	var card := _dossier
	card.inner_highlight = Color(1, 1, 1, 0.34)
	card.bg_texture = Ui.TEX_PAPER_CARD
	var tab := _panel(card, -8, 18, 22, 34, Color("#6a4a2d"), 2, Color("#20180f"), Vector2.ZERO)
	_pix(card, "排班档案 / ROSTER", 13, 8, 180, 10, 8, Color("#66573d"))
	_pix(card, "灯灭之前 · 03 窗口", 13, 21, 220, 16, 10.5, Color("#2a2318"))
	Ui.hline(card, 13, 42, 261, Color(65 / 255.0, 52 / 255.0, 31 / 255.0, 0.45), 1)
	var seal := _panel(card, 236, 8, 38, 38, Color(0, 0, 0, 0), 2, Color(148 / 255.0, 47 / 255.0, 37 / 255.0, 0.78), Vector2.ZERO)
	seal.rotation = deg_to_rad(-6)
	_pix(seal, "夜", 0, 7, 38, 10, 9, Color("#9b3127"), HORIZONTAL_ALIGNMENT_CENTER)
	_pix(seal, "排班", 0, 20, 38, 10, 7, Color("#9b3127"), HORIZONTAL_ALIGNMENT_CENTER)

	_pix(card, "精力", 13, 52, 110, 10, 8, Color("#7b6745"))
	_energy_value = _pix(card, "0", 13, 61, 110, 26, 21, Color("#2a2318"))
	_pix(card, "金钱", 148, 52, 110, 10, 8, Color("#7b6745"))
	_money_value = _pix(card, "0", 148, 61, 110, 26, 21, Color("#2a2318"))
	_alloc_line = _pix(card, "已分配 0 / 0", 13, 92, 261, 11, 8, Color("#5a4a33"))
	_preview = Ui.label(card, "", 0, 0, 0, 58, 8, Color("#5a4a33"), Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	_preview.position = Vector2(13, 106)
	_preview.size = Vector2(261, 58)
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_finish_btn = Ui.button(card, 13, 180, 261, 42, "安排好了", 11.5, Color("#f5e7c5"), Color("#91362d"), Color("#38100d"), Ui.F_UI_BOLD, Vector2(3, 3))
	_finish_btn.pressed.connect(func(): finish_requested.emit())


func _build_chat() -> void:
	_chat = _panel(self, CHAT_X, CHAT_Y, CHAT_W, CHAT_H, Color("#efe2c4"), 2, Color("#1b1710"), Vector2(4, 5))
	_chat.inner_highlight = Color(1, 1, 1, 0.34)
	var stripe := ColorRect.new()
	stripe.color = Color("#a83a2f")
	stripe.position = Vector2.ZERO
	stripe.size = Vector2(4, CHAT_H)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chat.add_child(stripe)
	_pix(_chat, "来访登记 / VISITOR", 16, 10, 260, 10, 7.5, Color("#7a6847"))
	_chat_title = _pix(_chat, "来访登记", 16, 24, 220, 22, 16, Color("#2b2418"))
	_chat_status = _pix(_chat, "暂无来访", 16, 52, 300, 14, 9, Color("#6d5a3c"))
	Ui.hline(_chat, 16, 76, 409, Color(93 / 255.0, 75 / 255.0, 46 / 255.0, 0.28), 1)
	_pix(_chat, "03 窗口 · 灯灭之前", 16, 176, 300, 12, 7.5, Color("#8a7752"))


func _build_visitor_chat() -> void:
	_visitor_chat = VISITOR_CHAT.new()
	add_child(_visitor_chat)
	Ui.place(_visitor_chat, 389, 96, 741, 274)
	_visitor_chat.visible = false
	_visitor_chat.option_chosen.connect(func(index: int): visitor_option_chosen.emit(index))
	_visitor_chat.item_attached.connect(func(id: String): visitor_item_attached.emit(id))
	_visitor_chat.item_cleared.connect(func(): visitor_item_cleared.emit())
	_visitor_chat.next_requested.connect(func(): visitor_next_requested.emit())


func _build_portrait() -> void:
	var frame := _panel(self, PORTRAIT_X, PORTRAIT_Y, PORTRAIT_W, PORTRAIT_H, Color("#1b231e"), 5, Color("#14130e"), Vector2(4, 5))
	frame.clip_contents = true
	var city := Ui.texture(frame, load("res://assets/city.png"), 5, 5, 206, 243, true)
	city.modulate = Color(1, 1, 1, 0.24)
	_portrait = PORTRAIT.new()
	frame.add_child(_portrait)
	Ui.place(_portrait, 7, 7, 202, 220)
	_portrait.setup({}, "")
	_portrait.modulate = Color(1, 1, 1, 0.55)
	var plate := _panel(frame, 5, 226, 206, 22, Color("#2b3227"), 0, Color("#10130e"), Vector2.ZERO)
	_portrait_name = _pix(plate, "暂无来访", 6, 4, 120, 14, 9, Color("#e8ddbd"))
	_portrait_role = _pix(plate, "WAITING", 126, 6, 74, 10, 7, Color("#8d9a82"), HORIZONTAL_ALIGNMENT_RIGHT)


func _build_folder() -> void:
	# The props live directly on the original desk surface.  No second folder,
	# no extra table: only a loose layer of draggable papers.
	_desk = Control.new()
	_desk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desk)
	Ui.place(_desk, FOLDER_X, FOLDER_Y, DESK_W, DESK_H)
	_sync_desk()


func _build_rail() -> void:
	var rail := _panel(self, RAIL_X, RAIL_Y, RAIL_W, RAIL_H, Color("#354034"), 3, Color("#141912"), Vector2(4, 5))
	rail.inner_highlight = Color("#5c6b56")
	_pix(rail, "其他材料", 22, 12, 150, 18, 16, Color("#f0e4c5"))
	var scroll := Ui.scroller(rail, 4, 48, 210, 326)
	_rail_list = VBoxContainer.new()
	_rail_list.add_theme_constant_override("separation", 5)
	_rail_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rail_list.custom_minimum_size.x = 198
	scroll.add_child(_rail_list)


func _build_bottom() -> void:
	var dock := _panel(self, 268, 780, 990, 62, Color("#3c2c1c"), 2, Color("#1a120b"), Vector2(2, 2))
	dock.inner_highlight = Color("#6d5232")
	_bottom_note = _pix(dock, "", 14, 20, 500, 18, 9, Color("#d8c7a3"))
	_pix(dock, "03 窗口 / WINDOW 03", 750, 22, 226, 14, 7, Color("#8f7d58"), HORIZONTAL_ALIGNMENT_RIGHT)


func _build_sign() -> void:
	var sign := _panel(self, 390, 67, 170, 24, Color("#283024"), 2, Color("#11150f"), Vector2(3, 3))
	sign.rotation = deg_to_rad(-0.4)
	Ui.hline(sign, 12, 8, 6, Color("#83aa7b"), 6)
	_pix(sign, "灯灭之前", 25, 5, 90, 14, 11, Color("#e3d8b9"))
	_pix(sign, "WINDOW 03", 112, 7, 52, 10, 8, Color("#91a083"))


# ============================================================
# REFRESH
# ============================================================
func _refresh() -> void:
	_rules_day.text = str(_day + 1)
	_refresh_projects()
	_refresh_dossier()
	_sync_desk()
	_refresh_rail()
	if _bottom_note != null:
		_bottom_note.text = "第 %d 夜 · 灯灭之前" % (_day + 1)


func _refresh_projects() -> void:
	if _project_grid == null:
		return
	_clear(_project_grid)
	var projects := MODEL.projects()
	for i in range(projects.size()):
		_build_project_chip(projects[i], i)


func _build_project_chip(row: Dictionary, index: int) -> void:
	var pid := str(row.get("id", ""))
	var placed := int(state.alloc_placed.get(pid, 0))
	var cap := int(row.get("cap", 1))
	var full := placed >= cap
	var card := _panel(_project_grid, 0, 0, 150, 45, Color("#e7dcbc"), 2, Color("#1a140d"), Vector2(2, 2))
	card.custom_minimum_size = Vector2(150, 45)
	card.inner_highlight = Color(1, 1, 1, 0.28)
	card.bg_texture = Ui.TEX_PAPER
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(_on_project_input.bind(pid))
	var base := card.bg_color
	card.mouse_entered.connect(func():
		if is_instance_valid(card):
			card.bg_color = base.lightened(0.06)
			card.queue_redraw()
	)
	card.mouse_exited.connect(func():
		if is_instance_valid(card):
			card.bg_color = Color("#f0e4c2") if full else base
			card.queue_redraw()
	)
	if full:
		card.bg_color = Color("#f0e4c2")
	_pix(card, str(row.get("label", "")), 6, 3, 100, 14, 10.5, Color("#2a2318"))
	_pix(card, "%s ×%d" % [MODEL.coin_label(str(row.get("coin", "energy"))), cap], 6, 18, 100, 10, 7, Color("#7b5a45"))
	_pix(card, "%d/%d" % [placed, cap], 104, 3, 40, 11, 8, Color("#5a4a33"), HORIZONTAL_ALIGNMENT_RIGHT)
	if full:
		_pix(card, "满", 104, 17, 40, 11, 8, Color("#9b3127"), HORIZONTAL_ALIGNMENT_RIGHT)
	var seg_w := (138.0 - float(maxi(0, cap - 1)) * 3.0) / float(maxi(1, cap))
	for seg_i in range(cap):
		var seg := ColorRect.new()
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seg.color = Color("#8b382b") if seg_i < placed else Color(91 / 255.0, 72 / 255.0, 44 / 255.0, 0.22)
		card.add_child(seg)
		seg.position = Vector2(6.0 + float(seg_i) * (seg_w + 3.0), 37.0)
		seg.size = Vector2(seg_w, 3.0)


func _refresh_dossier() -> void:
	_energy_value.text = str(int(state.energy))
	_money_value.text = str(int(state.money))
	var offer: Dictionary = state.alloc_offer
	var left := MODEL.remaining(state)
	var placed_count := 0
	for key in state.alloc_placed:
		placed_count += int(state.alloc_placed[key])
	var total := maxi(int(offer.get("energy", 0)) + int(offer.get("money", 0)), placed_count + left)
	var elsewhere := total - placed_count - left
	_alloc_line.text = "已分配 %d / %d" % [placed_count, total]
	if elsewhere > 0:
		_alloc_line.text += " · 来访/开销 %d" % elsewhere
	var effects := preview_effects()
	var bits: Array = []
	var fav: Dictionary = effects.get("favor", {})
	for row in MODEL.roles():
		var id := str(row.get("id", ""))
		var d := int(fav.get(id, 0))
		if d != 0:
			bits.append("%s +%d" % [str(row.get("name", id)), d])
	var perf := int(effects.get("perf", 0)) + int(effects.get("flat_perf", 0))
	var head := "预计绩效 +¥%s" % Ui.fmt_money(perf)
	if int(effects.get("rep", 0)) != 0:
		head += " · 声誉 +%d" % int(effects.get("rep", 0))
	if bits.is_empty():
		_preview.text = head
	else:
		_preview.text = head + "\n人情：" + " · ".join(PackedStringArray(bits))
	_finish_btn.disabled = left > 0
	_finish_btn.modulate = Color(1, 1, 1, 0.52 if left > 0 else 1.0)
	_finish_btn.text = "安排好了 · 进入第 %d 天" % (_day + 2)


func _refresh_rail() -> void:
	if _rail_list == null:
		return
	_clear(_rail_list)
	var items: Array = state.items
	for raw in items:
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		if bool(item.get("archived", false)):
			continue
		var tr: Dictionary = PROP.traits(str(item.get("kind", "")), item)
		var accent: Color = tr.accent_color
		var row := _panel(_rail_list, 0, 0, 198, 40, tr.paper_color, 2, Color("#1a140d"), Vector2(1, 1))
		row.custom_minimum_size = Vector2(198, 40)
		row.size = Vector2(198, 40)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var base: Color = tr.paper_color
		row.mouse_entered.connect(func():
			if is_instance_valid(row):
				row.bg_color = base.lightened(0.06)
				row.queue_redraw()
		)
		row.mouse_exited.connect(func():
			if is_instance_valid(row):
				row.bg_color = base
				row.queue_redraw()
		)
		var stripe := ColorRect.new()
		stripe.color = accent
		stripe.position = Vector2.ZERO
		stripe.size = Vector2(4, 40)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(stripe)
		var icon_box := _panel(row, 8, 5, 27, 30, Color(accent.r, accent.g, accent.b, 0.14), 1, accent, Vector2.ZERO)
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := MATERIAL_ICON.new()
		icon_box.add_child(icon)
		Ui.place(icon, 1, 1, 25, 28)
		icon.configure(str(tr.get("icon", "form")), accent)
		var title := _pix(row, str(item.get("title", id)), 43, 11, 128, 17, 10.5, Color("#2b2418"))
		title.clip_text = true
		_pix(row, "›", 182, 10, 12, 18, 12, Color("#8a3b2f"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		var item_id := id
		row.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					open_item(item_id)
					row.accept_event()
		)


func _item_badge(item: Dictionary) -> String:
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


func _item_accent(item: Dictionary) -> Color:
	match str(item.get("kind", "")):
		"favor", "college":
			return Color("#8fc08a")
		"schedule":
			return Color("#d9b06f")
		"letter":
			return Color("#d98f7f")
		"pass":
			return Color("#8fb1d9")
	return Color("#c7b890")


func _item_summary(item: Dictionary) -> String:
	match str(item.get("kind", "")):
		"favor":
			var total := 0
			for v in state.favor.values():
				total += int(v)
			return "总人情 %d" % total
		"college":
			return "6 学部"
		"schedule":
			return "8 项"
		"letter":
			return "第 %d 天 · 一次性" % (int(item.get("day", 0)) + 1)
		"pass":
			return "一次性"
	return ""


# ============================================================
# DESK / PROP DOCUMENTS
# ============================================================
func _sync_desk() -> void:
	if _desk == null:
		return
	if state.items.is_empty():
		state.ensure_base_items()
	var alive: Dictionary = {}
	var used: Dictionary = {}
	for existing in _desk_items.values():
		if is_instance_valid(existing):
			var slot_meta := int(existing.get_meta("slot", -1))
			if slot_meta >= 0:
				used[slot_meta] = true
	for raw in state.items:
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		if id == "":
			continue
		if bool(item.get("archived", false)) != _archive_mode:
			continue
		alive[id] = true
		var card = _desk_items.get(id, null)
		if card == null:
			card = DESK_ITEM.new()
			_desk.add_child(card)
			card.setup(item, state, Callable(self, "_item_body"), Vector2(DESK_W, DESK_H))
			card.drag_moved.connect(_on_prop_drag_moved)
			card.drag_finished.connect(_on_prop_drag_finished)
			card.item_changed.connect(_on_item_changed)
			card.archive_requested.connect(_on_item_archive)
			var slot := 0
			while used.has(slot) and slot < 19:
				slot += 1
			var col := slot % 5
			var row := slot / 5
			card.position = Vector2(8.0 + float(col) * 142.0, 5.0 + float(row) * 76.0)
			card.set_meta("slot", slot)
			used[slot] = true
			card._clamp()
			_desk_items[id] = card
		else:
			card.item = item
			card.refresh()
	for id in _desk_items.keys():
		if !alive.has(id):
			var dead = _desk_items[id]
			dead.queue_free()
			_desk_items.erase(id)


func _toggle_archive() -> void:
	_archive_mode = !_archive_mode
	if _archive_btn != null:
		_archive_btn.text = "返回桌面" if _archive_mode else "卷宗"
	_sync_desk()
	_refresh_rail()
	if _archive_mode and _desk_items.is_empty():
		_toast("卷宗里还没有材料。", "warn")


func _on_item_changed(_id: String) -> void:
	pass


func _on_item_archive(id: String) -> void:
	var item: Dictionary = state.item_of(id)
	if item.is_empty():
		return
	item["archived"] = !bool(item.get("archived", false))
	_sync_desk()
	_refresh_rail()
	_toast("材料已归入卷宗。" if bool(item.get("archived", false)) else "材料已取回桌面。", "good")


func open_item(id: String) -> void:
	_sync_desk()
	var card = _desk_items.get(id, null)
	if card == null:
		return
	card.expand()
	card.bring_to_front()


func _on_prop_drag_moved(_id: String, global_pos: Vector2) -> void:
	if _visitor_chat == null or !_visitor_chat.visible or _visitor_chat.is_resolved():
		return
	_visitor_chat.set_drop_hover(_visitor_chat.get_drop_rect().has_point(global_pos))


func _on_prop_drag_finished(id: String, global_pos: Vector2) -> void:
	if _visitor_chat == null or !_visitor_chat.visible or _visitor_chat.is_resolved():
		return
	var over: bool = _visitor_chat.get_drop_rect().has_point(global_pos)
	_visitor_chat.set_drop_hover(false)
	if !over:
		return
	var card = _desk_items.get(id, null)
	if card != null:
		card.restore_origin()
	_visitor_chat.attach_item(id)


func _item_body(item: Dictionary, body: Control) -> void:
	match str(item.get("kind", "")):
		"favor":
			_item_favor(body)
		"college":
			_item_college(body)
		"schedule":
			_item_schedule(body)
		"letter":
			_item_letter(body, item)
		"pass":
			_item_pass(body, item)


func _item_favor(body: Control) -> void:
	var rows := MODEL.roles()
	var total := 0
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var id := str(row.get("id", ""))
		var value := int(state.favor.get(id, 0))
		total += value
		var y := float(i) * 23.0
		var seal := _panel(body, 0, y + 2, 18, 18, Color("#a83a2f"), 1, Color("#5b1f19"), Vector2.ZERO)
		_pix(seal, str(row.get("seal", "")), 0, 0, 18, 18, 9, Color("#f6e7c8"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		_pix(body, str(row.get("name", "")), 24, y + 1, 100, 13, 10.0, Color("#3a3020"))
		_pix(body, str(row.get("role", "")), 24, y + 13, 110, 9, 8.0, Color("#7a6847"))
		_pix(body, str(value), 286, y, 26, 15, 11.5, Color("#8b382b"), HORIZONTAL_ALIGNMENT_RIGHT)
		_pix(body, MODEL.favor_label(value), 316, y + 2, 44, 10, 7.5, Color("#6d5a3c"))
		for pip_i in range(10):
			var pip := ColorRect.new()
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip.color = Color("#a83a2f") if pip_i < value else Color(91 / 255.0, 110 / 255.0, 88 / 255.0, 0.22)
			body.add_child(pip)
			pip.position = Vector2(364.0 + float(pip_i) * 7.0, y + 8.0)
			pip.size = Vector2(4.0, 7.0)
		_item_rule(body, y + 22)
	_pix(body, "总 %d · 来访时可作为随附文件" % total, 0, 164, 440, 12, 8.2, Color("#5a4a33"))


func _item_college(body: Control) -> void:
	var groups := COLLEGE.groups()
	for i in range(groups.size()):
		var g: Dictionary = groups[i]
		var gid := str(g.get("id", ""))
		var e := COLLEGE.entry(state.college_favor, gid)
		var y := float(i) * 24.0
		_pix(body, str(g.get("label", gid)), 0, y, 160, 13, 10.0, Color("#3a3020"))
		_pix(body, "导师 %s" % COLLEGE.advisor_name(g), 0, y + 12, 155, 9, 8.0, Color("#6d5a3c"))
		_pix(body, "主任 %s" % COLLEGE.director_name(g), 160, y + 12, 155, 9, 8.0, Color("#6d5a3c"))
		_pix(body, "人情 %d/%d" % [int(e.get("advisor", 0)), int(e.get("director", 0))], 300, y + 2, 80, 11, 8.5, Color("#5a4a33"), HORIZONTAL_ALIGNMENT_RIGHT)
		_pix(body, "规范 %d/%d" % [int(e.get("passes", 0)), COLLEGE.milestone_at()], 385, y + 2, 55, 11, 8.5, Color("#3f6b45"), HORIZONTAL_ALIGNMENT_RIGHT)
		_item_rule(body, y + 22)


func _item_schedule(body: Control) -> void:
	var rows := MODEL.projects()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var id := str(row.get("id", ""))
		var placed := int(state.alloc_placed.get(id, 0))
		var cap := int(row.get("cap", 0))
		var x := float(i % 2) * 218.0
		var y := float(i / 2) * 42.0
		_pix(body, str(row.get("label", "")), x, y, 130, 14, 10.0, Color("#2f281c"))
		_pix(body, "%s %d/%d" % [MODEL.coin_label(str(row.get("coin", "energy"))), placed, cap], x + 125, y + 1, 88, 11, 8.2, Color("#6d5a3c"), HORIZONTAL_ALIGNMENT_RIGHT)
		_pix(body, MODEL.project_text(row), x, y + 16, 210, 24, 8.2, Color("#5a4a33"))
		_item_rule(body, y + 39, 210, x)


func _item_letter(body: Control, item: Dictionary) -> void:
	var g := COLLEGE.group(str(item.get("group", "")))
	_pix(body, str(g.get("label", "学部")), 0, 0, 300, 16, 12.5, Color("#8b382b"))
	_item_rule(body, 18)
	_pix(body, "导师 %s · 主任 %s" % [COLLEGE.advisor_name(g), COLLEGE.director_name(g)], 0, 24, 440, 14, 9.5, Color("#3f3524"))
	_item_rule(body, 40)
	_pix(body, "学生 %s" % str(item.get("student", "—")), 0, 46, 300, 14, 9.5, Color("#3f3524"))
	_pix(body, "第 %d 天 · 感谢函" % (int(item.get("day", 0)) + 1), 0, 64, 300, 14, 9.5, Color("#3f3524"))
	_item_rule(body, 80)
	_pix(body, "学院回礼与感谢已入账。来访时可把这张函递给对方，", 0, 90, 440, 14, 9.5, Color("#3f3524"))
	_pix(body, "对方人情 +2、绩效 +¥40；递交后归档。", 0, 108, 440, 14, 9.5, Color("#3f3524"))


func _item_pass(body: Control, item: Dictionary) -> void:
	_pix(body, "临时通行条", 0, 0, 300, 16, 12.5, Color("#2d4d78"))
	_item_rule(body, 18)
	_pix(body, "03 窗口 · 第 %d 天" % (int(item.get("day", 0)) + 1), 0, 24, 300, 14, 9.5, Color("#5a4a33"))
	_item_rule(body, 42)
	_pix(body, "凭此条可在今晚的来访里补一份材料。", 0, 52, 440, 14, 9.5, Color("#6d5a3c"))
	_item_rule(body, 70)
	_pix(body, "来访时递交：对方人情 +1、绩效 +¥20；递交后归档。", 0, 80, 440, 14, 9.5, Color("#6d5a3c"))


func _item_rule(body: Control, y: float, width: float = 440.0, x: float = 0.0) -> void:
	var line := ColorRect.new()
	line.color = Color(67 / 255.0, 55 / 255.0, 34 / 255.0, 0.18)
	line.position = Vector2(x, y)
	line.size = Vector2(width, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(line)


# ============================================================
# VISITOR CHAT / PORTRAIT
# ============================================================
func show_visitor(v: Dictionary, role: Dictionary, display_name: String, index: int, total: int,
		state: Dictionary, items: Array, attached: String = "") -> void:
	if _dossier != null:
		_dossier.visible = false
	if _chat != null:
		_chat.visible = false
	if _visitor_chat != null:
		_visitor_chat.show_visitor(v, role, display_name, index, total, state, items, attached)
	if _portrait != null:
		_portrait.setup(role, display_name)
		_portrait.modulate = Color(1, 1, 1, 1)
	if _portrait_name != null:
		_portrait_name.text = display_name
	if _portrait_role != null:
		_portrait_role.text = str(role.get("role", "来访"))


func show_visitor_result(v: Dictionary, role: Dictionary, display_name: String, opt: Dictionary,
		index: int, total: int, is_last: bool, state: Dictionary) -> void:
	if _dossier != null:
		_dossier.visible = false
	if _chat != null:
		_chat.visible = false
	if _visitor_chat != null:
		_visitor_chat.show_result(opt, is_last)
		_visitor_chat.set_budget(int(state.get("energy", 0)), int(state.get("money", 0)))
	if _portrait != null:
		_portrait.setup(role, display_name)
		_portrait.modulate = Color(1, 1, 1, 1)
	if _portrait_name != null:
		_portrait_name.text = display_name
	if _portrait_role != null:
		_portrait_role.text = str(role.get("role", "来访"))


func clear_visitor(status: String = "等待来访") -> void:
	if _visitor_chat != null:
		_visitor_chat.clear()
	if _dossier != null:
		_dossier.visible = true
	if _chat != null:
		_chat.visible = true
		if _chat_title != null:
			_chat_title.text = "来访登记"
		if _chat_status != null:
			_chat_status.text = status
	if _portrait != null:
		_portrait.setup({}, "")
		_portrait.modulate = Color(1, 1, 1, 0.55)
	if _portrait_name != null:
		_portrait_name.text = "暂无来访"
	if _portrait_role != null:
		_portrait_role.text = "WAITING"


func set_attached_item(id: String) -> void:
	if _visitor_chat != null and _visitor_chat.visible:
		_visitor_chat.attach_item(id)


func clear_attached_item() -> void:
	if _visitor_chat != null:
		_visitor_chat.clear_attachment()


# ============================================================
# INPUT / MUTATION
# ============================================================
func _on_project_input(event: InputEvent, pid: String) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_place(pid)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_remove(pid)
			accept_event()


func _coin_left(kind: String) -> int:
	return int(state.energy) if kind == "energy" else int(state.money)


func _place(pid: String, silent: bool = false) -> void:
	var row := MODEL.project(pid)
	if row.is_empty():
		return
	var placed := int(state.alloc_placed.get(pid, 0))
	var cap := int(row.get("cap", 0))
	var label := str(row.get("label", pid))
	if placed >= cap:
		if !silent:
			_toast("「%s」已经排满了" % label, "warn")
		return
	var coin := str(row.get("coin", "energy"))
	if _coin_left(coin) <= 0:
		if !silent:
			_toast("没有%s了" % MODEL.coin_label(coin), "warn")
			_play("wrong")
		return
	state.alloc_placed[pid] = placed + 1
	if coin == "energy":
		state.energy = int(state.energy) - 1
	else:
		state.money = int(state.money) - 1
	if !silent:
		_play("drop")
		_toast("放入：%s" % label)
		if placed + 1 >= cap:
			_play("select")
	call_deferred("_refresh")
	changed.emit()


func _remove(pid: String, silent: bool = false) -> void:
	var row := MODEL.project(pid)
	if row.is_empty():
		return
	var placed := int(state.alloc_placed.get(pid, 0))
	if placed <= 0:
		return
	state.alloc_placed[pid] = placed - 1
	var coin := str(row.get("coin", "energy"))
	if coin == "energy":
		state.energy = int(state.energy) + 1
	else:
		state.money = int(state.money) + 1
	if !silent:
		_play("pick")
	call_deferred("_refresh")
	changed.emit()


func _recall_all() -> void:
	for pid in state.alloc_placed.keys():
		var row := MODEL.project(str(pid))
		var n := int(state.alloc_placed.get(pid, 0))
		if row.is_empty() or n <= 0:
			continue
		if str(row.get("coin", "energy")) == "energy":
			state.energy = int(state.energy) + n
		else:
			state.money = int(state.money) + n
	state.alloc_placed = {}
	_play("pick")
	_refresh()
	changed.emit()


func _remaining_text() -> String:
	var bits: Array = []
	if int(state.energy) > 0:
		bits.append("精力 %d" % int(state.energy))
	if int(state.money) > 0:
		bits.append("金钱 %d" % int(state.money))
	return "还剩 " + " · ".join(PackedStringArray(bits))


# ============================================================
# SMALL HELPERS
# ============================================================
func _play(name: String) -> void:
	if play_cb.is_valid():
		play_cb.call(name)


func _toast(text: String, kind: String = "") -> void:
	if toast_cb.is_valid():
		toast_cb.call(text, kind)


func _panel(parent: Node, x: float, y: float, w: float, h: float, bg: Color, border: int, bcol: Color, shadow: Vector2) -> PixelPanel:
	return Ui.panel(parent, x, y, w, h, bg, border, bcol, shadow, Color(0, 0, 0, 0.42))


func _pix(parent: Node, text: String, x: float, y: float, w: float, h: float, size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP) -> Label:
	return Ui.label(parent, text, x, y, w, h, size, color, Ui.F_PIXEL, align, valign, false)


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
