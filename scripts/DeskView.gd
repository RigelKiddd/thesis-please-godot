extends Control

const DocumentWindowScene := preload("res://scenes/ui/DocumentWindow.tscn")
const ChatPanelScene := preload("res://scenes/ui/ChatPanel.tscn")
const MaterialCardScene := preload("res://scenes/ui/MaterialCard.tscn")

const RunStateCtl := preload("res://scripts/RunState.gd")
var run_state := RunStateCtl.new()

## DeskView — the hand-placed desk/booth UI layer.
## Main inherits this class; game flow and controllers live in Main.gd.

const W := 1380.0
const H := 860.0
const SettingsStore := preload("res://scripts/SettingsStore.gd")

var day: int:
	get:
		return run_state.day
	set(value):
		run_state.day = value
var layer_world: Control
var layer_hud: Control
var layer_rules: Control
var layer_booth: Control
var layer_desk: Control
var layer_loose: Control
var layer_fx: Control
var layer_alloc: Control
var layer_toast: Control
var layer_modal: Control
var layer_ghost: Control

var hud_day: Label
var hud_weekday: Label
var hud_date: Label
var hud_progress: Label
var hud_perf: Label
var hud_clock: Label
var rep_pips: Array = []
var rep_value: Label
var last_rep := 5

var rules_box: VBoxContainer
var rule_version: Label
var rule_count: Label
var rules_panel: PixelPanel
var official_card: PixelPanel
var folder_panel: PixelPanel

var official_name: Label
var official_id: Label
var official_major: Label
var official_class: Label
var official_college: Label
var official_advisor: Label
var official_director: Label
var plate_name: Label
var plate_no: Label
var talk_text: Label
var talk_meta: Label
var talk_ticket: Label
var portrait: TextureRect
var portrait_normal: Texture2D
var portrait_blink: Texture2D
var portrait_shadow: TextureRect
var portrait_shader_mat: ShaderMaterial
var blink_gen := 0

var queue_root: Control
var queue_title_label: Label
var queue_kicker_label: Label
var file_no: Label
var file_major: Label
var tabs_root: Control
var doc_scroll: ScrollContainer
var doc_box: VBoxContainer

var material_count: Label
var materials_box: VBoxContainer
var rail_foot_left: Label
var rail_foot_right: Label

var chip_panels: Array = []
var chip_faces: Array = []
var chip_marks: Array = []
var chip_bgs: Array = []
var chip_rots: Array = []
var stamp_target: PixelPanel
var stamp_target_text: Label
var stamp_target_sub: Label
var annotate_btn: TextureButton
var annotate_plate: PixelPanel
var annotate_mark: ColorRect
var annotation_layer: Control
var annotation_guard: Control
var annotation_content: Control
var annotation_debug: Control
var ann
var annotating := false
var annot_drawing := false
var annot_ring: InkRing
var annot_box: PixelPanel
var annot_start := Vector2.ZERO
var annot_end := Vector2.ZERO
var annot_seed := 0.0
var day_annotation_count: int:
	get:
		return run_state.day_annotation_count
	set(value):
		run_state.day_annotation_count = value
var day_chat_replies: Array:
	get:
		return run_state.day_chat_replies
	set(value):
		run_state.day_chat_replies = value
var chat_student: Dictionary:
	get:
		return run_state.chat_student
	set(value):
		run_state.chat_student = value
var stamp_mark_holder: Control
var stamp_selected := ""

# --- run stats / accessibility ---
var annotation_hits: int:
	get:
		return run_state.annotation_hits
	set(value):
		run_state.annotation_hits = value
var annotation_wrong: int:
	get:
		return run_state.annotation_wrong
	set(value):
		run_state.annotation_wrong = value
var annotation_missed: int:
	get:
		return run_state.annotation_missed
	set(value):
		run_state.annotation_missed = value
var time_saved_total: int:
	get:
		return run_state.time_saved_total
	set(value):
		run_state.time_saved_total = value
var modal_closable := false
var settings_modal := false

var reset_btn: Button
var help_btn: Button
var sound_btn: Button
var sticky_count_label: Label

var toast_panel: PixelPanel
var toast_label: Label
var toast_tween: Tween
var toast_accent: ColorRect

var story_console: Control
var story_kicker: Label
var story_title: Label
var story_sub: Label
var story_count: Label
var story_dots: Control
var story_actions: Control
var story_choice_btns: Array = []
var story_finish_btn: Button
var night_label: Control
var booth_sign: PixelPanel
var talk_bubble: PixelPanel
var talk_label: Label
var chat_panel: PixelPanel
var chat_scroll: ScrollContainer
var chat_box: VBoxContainer
var chat_status: Label
var chat_avatar: Label
var chat_auto_note: Label
var chat_reply_btns: Array = []
var chat_gen := 0
var chat_reply := -1
var chat_dialogue_active := false
var chat_dialogue: Dictionary = {}
var chat_dialogue_choices: Array = []
var chat_dialogue_node := ""
var chat
var requests
var metrics
var request_stack: Control
var request_paper: Control
var request_resume_end := false
var desk_left: Control
var rail_panel: PixelPanel
var rail_kicker: Label
var rail_title: Label
var verdict_dock: PixelPanel

var modal_center: CenterContainer
var modal_loose: Control
var modal_top: Control
var modal_root: Control
var modal_fx_layer: Control

var loose_layer: Control
var desktop := preload("res://scripts/DesktopWindowManager.gd").new()
var loose_files: Dictionary:
	get: return desktop.windows
var ghost: Control

var type_full := ""
var type_index := 0
var type_accum := 0.0
var typing := false

var panel_offsets := {}
var panel_home := {}
var drag_state: Dictionary = {}
var drag_outline: PixelPanel
var suppress_until := 0
var hover_kind := ""
var toast_gen := 0
var modal_is_help := false

var sfx: Sfx

func _setup_cursors() -> void:
	var specs := [
		["arrow", Input.CURSOR_ARROW, Vector2(4, 2)],
		["hand", Input.CURSOR_POINTING_HAND, Vector2(8, 2)],
		["drag", Input.CURSOR_DRAG, Vector2(16, 16)],
		["stamp", Input.CURSOR_CROSS, Vector2(16, 16)],
		["pen", Input.CURSOR_HELP, Vector2(2, 28)],
	]
	for spec in specs:
		var path := "res://assets/cursors/%s.png" % spec[0]
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				Input.set_custom_mouse_cursor(tex, int(spec[1]), spec[2])

func _exit_tree() -> void:
	# Release custom textures while RenderingServer is still alive.
	for cursor in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_DRAG, Input.CURSOR_CROSS, Input.CURSOR_HELP]:
		Input.set_custom_mouse_cursor(null, cursor)

func _draw() -> void:
	# outer frame
	draw_rect(Rect2(0, 0, W, H), Color("#0c0e0a"))
	# wall
	draw_texture_rect(Ui.TEX_WALL, Rect2(5, 61, 1370, 300), true)
	# desk
	draw_texture_rect(Ui.TEX_DESK, Rect2(5, 361, 1370, 494), true)
	# wall / desk separator
	draw_rect(Rect2(5, 357, 1370, 8), Color("#252c22"))
	draw_rect(Rect2(5, 357, 1370, 3), Color("#0e110d"))
	draw_rect(Rect2(5, 363, 1370, 2), Color("#59634f"))
	# desk top border
	draw_rect(Rect2(5, 361, 1370, 4), Color("#1b140d"))
	# HUD bottom
	draw_rect(Rect2(5, 57, 1370, 4), Color("#0c0e0a"))
	draw_rect(Rect2(5, 61, 1370, 2), Color("#5b6551"))
	# frame rings
	draw_rect(Rect2(2, 2, 1376, 856), Color("#444b3e"), false, 2)
	draw_rect(Rect2(0, 0, W, H), Color("#0c0e0a"), false, 5)

func _make_layer(z: int) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	c.position = Vector2.ZERO
	c.size = Vector2(W, H)
	c.z_index = z
	return c

func _build_layers() -> void:
	layer_world = _make_layer(0)
	var glow := ColorRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gs := Shader.new()
	gs.code = """
shader_type canvas_item;
void fragment() {
	float d = distance(UV, vec2(0.62, 0.18));
	float a = smoothstep(0.66, 0.0, d) * 0.13;
	COLOR = vec4(0.54, 0.61, 0.46, a);
}
"""
	var gm := ShaderMaterial.new()
	gm.shader = gs
	glow.material = gm
	layer_world.add_child(glow)
	Ui.place(glow, 5, 61, 1370, 300)
	layer_hud = _make_layer(10)
	layer_rules = _make_layer(20)
	layer_booth = _make_layer(20)
	layer_desk = _make_layer(21)
	layer_loose = _make_layer(60)
	layer_fx = _make_layer(79)
	layer_alloc = _make_layer(85)
	layer_toast = _make_layer(90)
	layer_modal = _make_layer(200)
	layer_ghost = _make_layer(400)
	loose_layer = layer_loose

func _box(parent: Node, x: float, y: float, w: float, h: float, bg: Color,
		tex: Texture2D = null, border: int = 0, bcol: Color = Color.BLACK,
		shadow: Vector2 = Vector2.ZERO) -> PixelPanel:
	return Ui.panel(parent, x, y, w, h, bg, border, bcol, shadow, Color(0, 0, 0, 0.38), tex)

func _hover_fill(p: PixelPanel, base: Color, hover: Color) -> void:
	p.bg_color = base
	p.mouse_entered.connect(func():
		if is_instance_valid(p):
			p.bg_color = hover
			p.queue_redraw()
	)
	p.mouse_exited.connect(func():
		if is_instance_valid(p):
			p.bg_color = base
			p.queue_redraw()
	)

func _pix(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP) -> Label:
	return Ui.label(parent, text, x, y, w, h, size, color, Ui.F_PIXEL, align, valign, false)

func _txt(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color, font: Font = null,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP,
		wrap: bool = false) -> Label:
	return Ui.label(parent, text, x, y, w, h, size, color, font, align, valign, wrap)

func _wrap_height(text: String, font: Font, size: int, width: float, line_px: float) -> float:
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lines: int = max(1, int(ceil(tw / max(1.0, width))))
	return lines * line_px + 2.0

# ============================================================
# HUD
# ============================================================
func _build_hud() -> void:
	var bg := _box(layer_hud, 5, 5, 1370, 56, Color("#30382c"))
	bg.stripe_width = 4
	bg.stripe_color = Color("#2d352a")
	bg.top_glow = Color(1, 1, 1, 0.03)
	Ui.hline(layer_hud, 5, 57, 1370, Color("#0c0e0a"), 4)
	Ui.hline(layer_hud, 5, 61, 1370, Color("#5b6551"), 2)

	var badge := _box(layer_hud, 19, 12, 74, 39, Ui.PAPER, null, 3, Color("#0f100c"), Vector2(3, 3))
	badge.inner_highlight = Color(1, 1, 1, 0.42)
	badge.rotation = deg_to_rad(-0.6)
	_pix(badge, "DAY", 12, 13, 22, 12, 12, Ui.INK)
	hud_day = _pix(badge, "01", 34, 1, 34, 32, 27, Ui.INK)

	hud_weekday = _pix(layer_hud, "周一", 104, 14, 70, 18, 16, Color("#f0e6c9"))
	hud_date = _pix(layer_hud, "2026.05.11", 104, 34, 100, 12, 11.5, Color("#a9b09a"))

	var cn := _pix(layer_hud, "论文审批处", 478, 10, 246, 27, 25, Color("#eee3c6"), HORIZONTAL_ALIGNMENT_CENTER)
	cn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	cn.add_theme_constant_override("shadow_offset_x", 2)
	cn.add_theme_constant_override("shadow_offset_y", 2)
	_pix(layer_hud, "UNDERGRADUATE THESIS REVIEW OFFICE · WINDOW 03", 478, 40, 246, 9, 8.5, Color("#99a28e"), HORIZONTAL_ALIGNMENT_CENTER)

	hud_progress = _hud_stat(972, 66, "进度", "1 / 4", false)
	_build_rep_stat()
	hud_perf = _hud_stat(1123, 66, "绩效", "¥ 0", false)
	hud_clock = _hud_stat(1191, 72, "值班时间", "09:00", true)

	var settings_btn := Ui.button(layer_hud, 1265, 14, 34, 34, "设", 12, Color("#d8d0b6"), Color("#232b21"), Color("#10130e"), Ui.F_UI_BOLD, Vector2(2, 2))
	settings_btn.pressed.connect(Callable(self, "_open_settings"))
	settings_btn.tooltip_text = "设置：缩放 / 震动 / 文字速度 (G)"
	sound_btn = Ui.button(layer_hud, 1301, 14, 34, 34, "♪", 15, Color("#d8d0b6"), Color("#232b21"), Color("#10130e"), Ui.F_PIXEL, Vector2(2, 2))
	sound_btn.pressed.connect(Callable(self, "_toggle_sound"))
	sound_btn.tooltip_text = "开关音效 (M)"
	help_btn = Ui.button(layer_hud, 1337, 14, 34, 34, "?", 15, Color("#d8d0b6"), Color("#232b21"), Color("#10130e"), Ui.F_PIXEL, Vector2(2, 2))
	help_btn.pressed.connect(Callable(self, "_on_help_btn"))
	help_btn.tooltip_text = "操作说明 (H)"

func _hud_stat(x: float, w: float, label_text: String, value_text: String, is_clock: bool) -> Label:
	var p := _box(layer_hud, x, 12, w, 38, Color("#20271e"), null, 2, Color("#12150f"))
	p.inner_highlight = Color("#434d3d")
	if is_clock:
		p.bg_color = Color("#181d16")
		p.border_color = Color("#0d0f0b")
		_pix(p, label_text, 0, 4, w, 9, 9.5, Color("#929c87"), HORIZONTAL_ALIGNMENT_CENTER)
		return _pix(p, value_text, 0, 17, w, 20, 19, Color("#d6c28b"), HORIZONTAL_ALIGNMENT_CENTER)
	_pix(p, label_text, 9, 4, w - 14, 9, 9.5, Color("#929c87"))
	return _pix(p, value_text, 9, 17, w - 14, 17, 16, Color("#eee2c3"))

func _build_rep_stat() -> void:
	var p := _box(layer_hud, 1046, 12, 77, 38, Color("#20271e"), null, 2, Color("#12150f"))
	p.inner_highlight = Color("#434d3d")
	p.tooltip_text = "声誉：误判 ∀ ，归零停职"
	_pix(p, "声誉", 9, 3, 60, 9, 9.5, Color("#929c87"))
	rep_pips.clear()
	var seal := _box(p, 7, 16, 13, 14, Color("#c14b39"), null, 1, Color("#5b1f19"))
	seal.inner_highlight = Color("#e9a28f")
	_pix(seal, "誉", 0, 0, 13, 14, 8, Color("#f6e7c8"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	rep_pips.append(seal)
	rep_value = _pix(p, "5/5", 25, 16, 46, 15, 14, Color("#f0e2c0"))

# ============================================================
# RULES
# ============================================================
func _build_rules() -> void:
	var book := _box(layer_rules, 17, 71, 352, 281, Ui.PAPER, Ui.TEX_PAPER, 2, Color("#1a1710"), Vector2(4, 5))
	book.inner_highlight = Color(1, 1, 1, 0.38)
	rules_panel = book
	var clip := _box(layer_rules, 157, 66, 70, 18, Color("#8d8b7c"), null, 2, Color("#1b1a14"))
	clip.inner_highlight = Color("#c2beaa")
	var hole := _box(layer_rules, 177, 70, 20, 8, Color("#2d2d26"), null, 2, Color("#605e51"))

	_pix(layer_rules, "教务处", 32, 89, 250, 14, 8.5, Color("#6e6046"))
	_pix(layer_rules, "毕业论文审查条例", 32, 104, 240, 19, 18, Color("#2a2419"))
	var ed := _box(layer_rules, 307, 87, 46, 38, Color(0, 0, 0, 0), null, 2, Ui.RED)
	ed.rotation = deg_to_rad(3)
	_pix(ed, "第", 3, 6, 10, 12, 9.5, Ui.RED)
	rule_version = _pix(ed, "1", 13, 1, 18, 18, 16, Ui.RED, HORIZONTAL_ALIGNMENT_CENTER)
	_pix(ed, "物", 31, 6, 12, 12, 9.5, Ui.RED)
	_pix(ed, "现行", 0, 22, 46, 12, 9.5, Ui.RED, HORIZONTAL_ALIGNMENT_CENTER)

	var scroll := Ui.scroller(layer_rules, 33, 132, 321, 197)
	rules_box = VBoxContainer.new()
	rules_box.add_theme_constant_override("separation", 7)
	rules_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_box.custom_minimum_size.x = 315
	scroll.add_child(rules_box)

	rule_count = _pix(layer_rules, "1 组 / 2 条生效", 34, 332, 300, 9, 8.5, Color("#75674c"))

func render_rules() -> void:
	for c in rules_box.get_children():
		c.queue_free()
	var active: Array = []
	for g in GameData.rules:
		if int(g.get("day", 99)) <= day + 1:
			active.append(g)
	active.reverse()
	var count := 0
	for g in active:
		var is_new := int(g.get("day", 0)) == day + 1
		count += g.get("rules", []).size()
		rules_box.add_child(_rule_group(g, is_new))
	rule_version.text = str(day + 1)
	rule_count.text = "%d 组 / %d 条生效" % [active.size(), count]
	rules_box.get_parent().scroll_vertical = 0

func _rule_group(g: Dictionary, is_new: bool) -> Control:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.973, 0.941, 0.784, 0.55) if is_new else Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_color = Ui.RED if is_new else Color(88 / 255.0, 74 / 255.0, 49 / 255.0, 0.32)
	sb.content_margin_left = 7
	sb.content_margin_right = 5
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	pc.add_theme_stylebox_override("panel", sb)
	if !is_new:
		pc.modulate.a = 0.88
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 1)
	pc.add_child(inner)

	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 5)
	th.custom_minimum_size.y = 14
	inner.add_child(th)
	var code := _box(th, 0, 0, 15, 13, Color("#3b3426"))
	code.custom_minimum_size = Vector2(15, 13)
	code.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pix(code, str(g.get("code", "")), 0, 0, 15, 13, 8.5, Color("#e8ddbd"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	var title := _pix(th, str(g.get("title", "")), 0, 1, 80, 13, 11.5, Color("#3a3021"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if is_new:
		var tag := _box(th, 0, 0, 22, 13, Ui.RED)
		tag.custom_minimum_size = Vector2(22, 13)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_pix(tag, "NEW", 0, 1, 22, 11, 7.5, Color("#f5e9c9"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	inner.add_child(list)
	var rules: Array = g.get("rules", [])
	for rule in rules:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var bullet := _pix(row, "·", 0, 0, 8, 14, 9.5, Ui.RED)
		bullet.custom_minimum_size.x = 8
		var rl := Ui.label(row, str(rule), 0, 0, 290, 16, 10, Color("#3f3628"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
		rl.add_theme_constant_override("line_spacing", Ui.line_gap(10, 15.2, Ui.F_UI))
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rl.custom_minimum_size.y = _wrap_height(str(rule), Ui.F_UI, 10, 286, 15.2)
		list.add_child(row)
	return pc

# ============================================================
# BOOTH
# ============================================================
func _build_booth() -> void:
	var sign := _box(layer_booth, 390, 67, 170, 24, Color("#283024"), null, 2, Color("#11150f"), Vector2(3, 3))
	sign.rotation = deg_to_rad(-0.4)
	booth_sign = sign
	Ui.hline(sign, 12, 8, 6, Color("#83aa7b"), 6)
	_pix(sign, "答辩资格审查", 25, 5, 80, 14, 11, Color("#e3d8b9"))
	_pix(sign, "WINDOW 03", 108, 7, 56, 10, 8, Color("#91a083"))

	var card := _box(layer_booth, 389, 96, 287, 254, Color("#dfd3b1"), Ui.TEX_PAPER_CARD, 2, Color("#1a1711"), Vector2(4, 5))
	card.inner_highlight = Color(1, 1, 1, 0.34)
	card.mouse_default_cursor_shape = Control.CURSOR_DRAG
	card.tooltip_text = "拖动学籍档案 · 双击归位"
	official_card = card
	var tabstop := _box(card, -8, 18, 22, 34, Color("#6a4a2d"), null, 2, Color("#20180f"))
	_pix(card, "学籍档案", 13, 9, 180, 10, 9.5, Color("#66573d"))
	_pix(card, "2022 级", 236, 9, 39, 13, 8.5, Color("#7b6745"))
	official_name = _pix(card, "——", 13, 29, 150, 24, 23, Color("#2a2318"))
	var status := _box(card, 108, 44, 21, 11, Color("#4e6d4f"))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pix(status, "在籍", 0, 0, 21, 11, 8.5, Color("#e8e0c4"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	Ui.hline(card, 13, 31, 262, Color(65 / 255.0, 52 / 255.0, 31 / 255.0, 0.45), 1)

	_id_field(card, 13, 55, 127, "学号", "——")
	official_id = _id_value_label
	_id_field(card, 148, 56, 127, "专业", "——")
	official_major = _id_value_label
	_id_field(card, 13, 75, 127, "班级", "——")
	official_class = _id_value_label
	_id_field(card, 148, 76, 127, "学院", "——")
	official_college = _id_value_label
	_id_field(card, 13, 95, 262, "导师", "——")
	official_advisor = _id_value_label
	_id_field(card, 13, 115, 262, "主任", "——")
	official_director = _id_value_label

	_pix(card, "教务库档案", 12, 233, 180, 10, 8, Color("#88785a"))
	var seal := _box(card, 234, 205, 43, 43, Color(0, 0, 0, 0), null, 2, Color(148 / 255.0, 47 / 255.0, 37 / 255.0, 0.78))
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.rotation = deg_to_rad(-11)
	_pix(seal, "教务处", 0, 9, 43, 8, 7, Color(148 / 255.0, 47 / 255.0, 37 / 255.0, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	_pix(seal, "核验", 0, 21, 43, 8, 7, Color(148 / 255.0, 47 / 255.0, 37 / 255.0, 0.8), HORIZONTAL_ALIGNMENT_CENTER)

	talk_label = _pix(layer_booth, "学生陈述", 693, 181, 300, 9, 8.5, Color("#8d9a83"))
	var bubble := _box(layer_booth, 689, 193, 441, 78, Ui.PAPER, null, 2, Color("#171912"), Vector2(4, 4))
	talk_bubble = bubble
	var tail := _box(bubble, 439, 26, 12, 12, Ui.PAPER, null, 0, Color("#171912"))
	tail.border_widths = Vector4i(0, 2, 2, 0)
	tail.rotation = deg_to_rad(45)
	talk_text = Ui.label(bubble, "下一位，请进。", 13, 12, 415, 38, 11.5, Color("#332d20"), Ui.F_DOC,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	talk_text.add_theme_constant_override("line_spacing", Ui.line_gap(11.5, 19.2, Ui.F_DOC))
	Ui.hline(bubble, 13, 60, 415, Color(62 / 255.0, 51 / 255.0, 32 / 255.0, 0.32), 1)
	talk_meta = _pix(bubble, "主件6 · 附件4", 13, 62, 300, 12, 8, Color("#7c6c4e"))
	talk_ticket = _pix(bubble, "A-001", 380, 62, 48, 12, 8, Color("#7c6c4e"), HORIZONTAL_ALIGNMENT_RIGHT)

	chat_panel = ChatPanelScene.instantiate()
	layer_booth.add_child(chat_panel)
	Ui.place(chat_panel, 689, 140, 441, 205)
	chat_panel.reply_selected.connect(Callable(self, "_on_chat_reply"))
	chat_avatar = chat_panel.chat_avatar
	chat_status = chat_panel.chat_status
	chat_scroll = chat_panel.chat_scroll
	chat_box = chat_panel.chat_box
	chat_reply_btns = chat_panel.chat_reply_btns
	chat_auto_note = chat_panel.chat_auto_note
	talk_label.visible = false
	talk_bubble.visible = false

	var win := _box(layer_booth, 1143, 97, 216, 253, Color("#1b231e"), null, 5, Color("#14130e"), Vector2(4, 5))
	win.clip_contents = true
	var city := Ui.texture(win, load("res://assets/city.png"), 5, 5, 206, 243, true)
	city.modulate.a = 0.92
	var blinds := Blinds.new()
	win.add_child(blinds)
	Ui.place(blinds, 5, 5, 206, 92)
	# Dark silhouette underlay: covers the baked light edge without adding a
	# light rim of its own.
	portrait_shadow = TextureRect.new()
	portrait_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_shadow.modulate = Color(0.015, 0.012, 0.02, 0.92)
	portrait_shadow.pivot_offset = Vector2(90, 110)
	portrait_shadow.scale = Vector2(1.045, 1.045)
	win.add_child(portrait_shadow)
	Ui.place(portrait_shadow, 18, 8, 180, 220)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	win.add_child(portrait)
	Ui.place(portrait, 18, 8, 180, 220)
	# v2 立绘 + grimoire 色域层；保留 CRT 作为旧资源回退。
	var portrait_mat: ShaderMaterial = null
	if ResourceLoader.exists("res://shaders/grimoire_bust.gdshader"):
		portrait_mat = ShaderMaterial.new()
		portrait_mat.shader = load("res://shaders/grimoire_bust.gdshader")
		portrait_mat.set_shader_parameter("virtual_size", Vector2(144, 192))
		portrait_mat.set_shader_parameter("palette_mix", 0.55)
		portrait_mat.set_shader_parameter("intensity", 0.35)
		portrait_mat.set_shader_parameter("dither_strength", 0.04)
		portrait_mat.set_shader_parameter("ca_strength", 0.0007)
		portrait_mat.set_shader_parameter("alpha_cutoff", 0.40)
		portrait_mat.set_shader_parameter("grade_strength", 0.30)
		portrait_mat.set_shader_parameter("rim_strength", 0.0)
		portrait_mat.set_shader_parameter("scanline_strength", 0.012)
		portrait_mat.set_shader_parameter("stipple_strength", 0.04)
		portrait_mat.set_shader_parameter("shadow_tint", Color(0.072, 0.034, 0.110, 1.0))
		portrait_mat.set_shader_parameter("light_tint", Color(0.918, 0.855, 0.710, 1.0))
		portrait_mat.set_shader_parameter("rim_color", Color(0.58, 0.73, 0.66, 1.0))
	elif ResourceLoader.exists("res://shaders/portrait_crt.gdshader"):
		portrait_mat = ShaderMaterial.new()
		portrait_mat.shader = load("res://shaders/portrait_crt.gdshader")
	portrait_shader_mat = portrait_mat
	portrait.material = portrait_mat if SettingsStore.portrait_shader else null
	var glass := WindowGlass.new()
	win.add_child(glass)
	Ui.place(glass, 5, 5, 206, 243)
	var plate := _box(win, 5, 226, 206, 22, Color("#2b3227"))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.border_widths = Vector4i(0, 3, 0, 0)
	plate.border_color = Color("#10130e")
	plate_name = _pix(plate, "等待学生", 6, 4, 120, 14, 9, Color("#e8ddbd"))
	plate_no = _pix(plate, "NO. 000", 126, 6, 74, 10, 7, Color("#8d9a82"), HORIZONTAL_ALIGNMENT_RIGHT)

	# Night overlay: covers the whole window after hours.
	night_label = Control.new()
	night_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_label.visible = false
	night_label.z_index = 10
	win.add_child(night_label)
	Ui.place(night_label, 5, 5, 206, 243)
	var grad := ColorRect.new()
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gs := Shader.new()
	gs.code = """
shader_type canvas_item;
void fragment() {
	COLOR = vec4(0.026, 0.041, 0.031, mix(0.48, 0.96, UV.y));
}
"""
	var gm := ShaderMaterial.new()
	gm.shader = gs
	grad.material = gm
	night_label.add_child(grad)
	Ui.place(grad, 0, 0, 206, 243)
	Ui.hline(night_label, 77, 92, 52, Color(217 / 255.0, 189 / 255.0, 120 / 255.0, 0.45), 1)
	_pix(night_label, "03 · 灯已关", 0, 104, 206, 28, 19, Color("#e9dcc0"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	var sill := _box(layer_booth, 378, 356, 997, 5, Color("#1c2219"))
	sill.border_widths = Vector4i(0, 2, 0, 0)
	sill.border_color = Color("#59634f")

var _id_value_label: Label

func _id_field(parent: Node, x: float, y: float, w: float, key: String, value: String) -> void:
	var k := _pix(parent, key, x, y + 4, 22, 9, 8.5, Color("#75664b"))
	var v := _pix(parent, value, x + 23, y, w - 23, 16, 10, Color("#322a1d"))
	v.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	Ui.hline(parent, x, y + 16, w, Color(75 / 255.0, 60 / 255.0, 36 / 255.0, 0.16), 1)
	_id_value_label = v

# ============================================================
# DESK
# ============================================================
## The allocation screen has its own quiet desk: the student queue belongs to
## the review shift, not to the after-hours visitor fold.
func set_queue_visible(on: bool) -> void:
	if queue_root != null:
		queue_root.visible = on
	if queue_title_label != null:
		queue_title_label.visible = on
	if queue_kicker_label != null:
		queue_kicker_label.visible = on


## Hide the review-shift chrome while the after-hours allocation is open:
## the student queue, the stamp tray and the verdict dock all belong to the
## daytime review, not to the visitor desk.
func set_allocation_chrome(on: bool) -> void:
	set_queue_visible(!on)
	for n in [stamp_target, annotate_plate, verdict_dock, stamp_mark_holder, annotate_btn, folder_panel, official_card, chat_panel]:
		if n != null:
			n.visible = !on


func _build_desk() -> void:
	desk_left = Control.new()
	desk_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_desk.add_child(desk_left)
	Ui.place(desk_left, 0, 0, W, H)

	queue_title_label = _pix(desk_left, "今日队列", 23, 377, 90, 8, 8.5, Color("#d4c49d"))
	queue_kicker_label = _pix(desk_left, "QUEUE", 118, 377, 35, 8, 8.5, Color("#f1dfac"), HORIZONTAL_ALIGNMENT_RIGHT)
	queue_root = Control.new()
	queue_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desk_left.add_child(queue_root)
	Ui.place(queue_root, 0, 0, W, H)

	var coffee := CoffeeCup.new()
	desk_left.add_child(coffee)
	Ui.place(coffee, 28, 794, 52, 48)

	var sticky := _box(desk_left, 93, 756, 67, 81, Color("#e3cc74"), null, 1, Color("#8b7336"), Vector2(3, 4))
	sticky.rotation = deg_to_rad(3.6)
	_pix(sticky, "今日", 0, 10, 67, 12, 9, Color("#544421"), HORIZONTAL_ALIGNMENT_CENTER)
	var sc := _pix(sticky, "4", 0, 22, 67, 24, 19, Color("#544421"), HORIZONTAL_ALIGNMENT_CENTER)
	sticky_count_label = sc
	_pix(sticky, "今", 0, 46, 67, 12, 9, Color("#544421"), HORIZONTAL_ALIGNMENT_CENTER)
	_pix(sticky, "勿催", 0, 58, 67, 12, 9, Color("#544421"), HORIZONTAL_ALIGNMENT_CENTER)

	var folder := _box(layer_desk, 268, 375, 760, 396, Color("#b19b6d"), null, 3, Color("#22180e"), Vector2(5, 6))
	folder.inner_highlight = Color(1, 1, 1, 0.18)
	folder.mouse_default_cursor_shape = Control.CURSOR_DRAG
	folder.tooltip_text = "拖动卷宗标题 · 双击归位"
	folder_panel = folder

	var tag := _box(folder, 11, 6, 170, 14, Color("#cbb887"), null, 1, Color("#5d4b2e"))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pix(tag, "卷宗", 4, 1, 20, 11, 8, Color("#3f321d"))
	file_no = _pix(tag, "MD-2026-0001", 24, 1, 68, 11, 8, Color("#6e2b22"))
	_pix(tag, "·", 93, 1, 6, 11, 8, Color("#3f321d"))
	file_major = _pix(tag, "——", 99, 1, 66, 11, 8, Color("#3f321d"))

	var paper := _box(folder, 8, 46, 744, 342, Ui.PAPER_HI, null, 3, Color("#251c11"), Vector2(3, 3))
	paper.inner_highlight = Color(1, 1, 1, 0.46)
	var tape1 := _box(paper, -15, 9, 50, 13, Color(223 / 255.0, 208 / 255.0, 166 / 255.0, 0.66), null, 1, Color(104 / 255.0, 84 / 255.0, 50 / 255.0, 0.18))
	tape1.rotation = deg_to_rad(-38)
	var tape2 := _box(paper, 709, 295, 50, 13, Color(223 / 255.0, 208 / 255.0, 166 / 255.0, 0.66), null, 1, Color(104 / 255.0, 84 / 255.0, 50 / 255.0, 0.18))
	tape2.rotation = deg_to_rad(-42)

	doc_scroll = Ui.scroller(folder, 11, 49, 738, 336)
	var mc := Ui.margin(doc_scroll, 15, 15, 21, 17)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc_box = VBoxContainer.new()
	doc_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc_box.custom_minimum_size.x = 696
	doc_box.add_theme_constant_override("separation", 0)
	mc.add_child(doc_box)

	annotation_layer = Control.new()
	annotation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	annotation_layer.z_index = 40
	annotation_layer.clip_contents = true
	folder.add_child(annotation_layer)
	Ui.place(annotation_layer, 11, 49, 738, 336)

	annotation_content = Control.new()
	annotation_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	annotation_content.size = Vector2(696, 1200)
	annotation_layer.add_child(annotation_content)
	Ui.place(annotation_content, 15, 15, 696, 1200)
	doc_scroll.get_v_scroll_bar().value_changed.connect(func(_v): call("_sync_annotation_offset"))

	annotation_guard = Control.new()
	annotation_guard.mouse_filter = Control.MOUSE_FILTER_STOP
	annotation_guard.mouse_default_cursor_shape = Control.CURSOR_HELP
	annotation_guard.z_index = 41
	annotation_guard.visible = false
	folder.add_child(annotation_guard)
	Ui.place(annotation_guard, 11, 49, 738, 336)

	tabs_root = Control.new()
	tabs_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder.add_child(tabs_root)
	Ui.place(tabs_root, 8, 23, 744, 23)

	_build_rail()
	_build_verdict()
	_build_story_console()

func _build_rail() -> void:
	var rail := _box(layer_desk, 1038, 375, 220, 396, Color("#354034"), Ui.TEX_RAIL, 3, Color("#141912"), Vector2(4, 5))
	rail.inner_highlight = Color("#5c6b56")
	rail.mouse_filter = Control.MOUSE_FILTER_STOP
	rail.mouse_default_cursor_shape = Control.CURSOR_DRAG
	rail.tooltip_text = "拖动材料架 · 双击归位"
	rail.set_meta("rail", true)
	rail_panel = rail
	rail_kicker = Ui.label(rail, "SUPPLEMENTARY / 附加材料", 22, 10, 158, 9, 7.5, Color("#95a287"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	rail_kicker.visible = false
	rail_title = _pix(rail, "其他材料", 22, 12, 150, 18, 16, Color("#f0e4c5"))
	_pix(rail, "⠀", 11, 16, 8, 14, 9, Color("#95a287"), HORIZONTAL_ALIGNMENT_LEFT)
	var cnt := _box(rail, 182, 11, 28, 28, Color(0, 0, 0, 0), null, 1, Color("#899877"))
	cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_count = _pix(cnt, "0/4", 0, 0, 28, 28, 10, Color("#d8cfb3"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	var rail_scroll := ScrollContainer.new()
	rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rail_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	rail.add_child(rail_scroll)
	Ui.place(rail_scroll, 4, 48, 210, 319)
	var rail_margin := MarginContainer.new()
	rail_margin.add_theme_constant_override("margin_left", 7)
	rail_margin.add_theme_constant_override("margin_right", 5)
	rail_margin.add_theme_constant_override("margin_top", 1)
	rail_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail_scroll.add_child(rail_margin)
	materials_box = VBoxContainer.new()
	materials_box.add_theme_constant_override("separation", 5)
	materials_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	materials_box.custom_minimum_size.x = 198
	rail_margin.add_child(materials_box)

	rail_foot_left = _pix(rail, "暂无附件", 11, 371, 90, 11, 7.5, Color("#95a287"))
	rail_foot_right = _pix(rail, "", 121, 371, 78, 11, 7.5, Color("#95a287"), HORIZONTAL_ALIGNMENT_RIGHT)

func _build_verdict() -> void:
	var dock := _box(layer_desk, 268, 780, 430, 62, Color("#3c2c1c"), null, 2, Color("#1a120b"), Vector2(2, 2))
	verdict_dock = dock
	dock.inner_highlight = Color("#6d5232")
	dock.border_widths = Vector4i(1, 1, 1, 1)
	dock.z_index = 30

	chip_panels.clear()
	chip_faces.clear()
	chip_marks.clear()
	chip_bgs.clear()
	chip_rots.clear()
	var defs := [
		{"id": "pass", "stamp": "通过", "bg": Color("#3f6045"), "fg": Color("#d8e5c8")},
		{"id": "revise", "stamp": "修改", "bg": Color("#8a5b22"), "fg": Color("#f2dfb3")},
		{"id": "reject", "stamp": "不通过", "bg": Color("#7f2d26"), "fg": Color("#f1cec1")},
	]
	var xs := [14.0, 134.0, 254.0]
	for i in range(3):
		var d: Dictionary = defs[i]
		var stamp_id := str(d["id"])
		var root := Control.new()
		root.size = Vector2(110, 54)
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		dock.add_child(root)
		Ui.place(root, xs[i], 4, 110, 54)
		root.pivot_offset = Vector2(55, 27)
		root.rotation = deg_to_rad([-1.1, 0.7, -0.8][i])
		var handle := _box(root, 42, 0, 26, 11, Color("#6b4a2c"), null, 2, Color("#100c08"))
		handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		handle.stripe_width = 2
		handle.stripe_color = Color(0, 0, 0, 0.18)
		handle.inner_highlight = Color("#9a6b3f")
		var ferrule := _box(root, 38, 10, 34, 5, Color("#b08a4a"), null, 1, Color("#4e341c"))
		ferrule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ferrule.inner_highlight = Color("#e0c07c")
		var face := _box(root, 8, 15, 94, 36, d["bg"], null, 3, Color("#1a120c"))
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.inner_highlight = Color(1, 1, 1, 0.18)
		face.bottom_edge = Color(0, 0, 0, 0.22)
		face.bottom_edge_height = 3
		_pix(face, d["stamp"], 1, 1, 94, 36, 15, Color(0, 0, 0, 0.35), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		_pix(face, d["stamp"], 0, 0, 94, 36, 15, d["fg"], HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		var pad := _box(root, 16, 51, 78, 3, d["bg"].darkened(0.28), null, 0, Color(0, 0, 0, 0))
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mark := ColorRect.new()
		mark.color = Color("#d9c18f")
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(mark)
		Ui.place(mark, 8, 52, 94, 3)
		mark.visible = false
		root.mouse_entered.connect(func():
			if is_instance_valid(face):
				face.bg_color = d["bg"].lerp(Color.WHITE, 0.12)
				face.queue_redraw()
		)
		root.mouse_exited.connect(func():
			call("render_stamps")
		)
		chip_panels.append(root)
		chip_faces.append(face)
		chip_marks.append(mark)
		chip_bgs.append(d["bg"])
		chip_rots.append(root.rotation)

	reset_btn = Ui.button(dock, 376, 6, 42, 50, "归位", 9, Color("#cbb98f"), Color("#211810"), Color("#6d5739"), Ui.F_PIXEL, Vector2(0, 0))
	reset_btn.pressed.connect(Callable(self, "_reset_all_layout"))

	annotate_plate = _box(layer_desk, 710, 780, 64, 62, Color("#3c2c1c"), null, 2, Color("#1a120b"), Vector2(2, 2))
	annotate_plate.inner_highlight = Color("#6d5232")
	annotate_plate.z_index = 30
	annotate_btn = TextureButton.new()
	annotate_btn.texture_normal = load("res://assets/cursors/pen.png")
	annotate_btn.texture_hover = load("res://assets/cursors/pen.png")
	annotate_btn.texture_pressed = load("res://assets/cursors/pen.png")
	annotate_btn.ignore_texture_size = true
	annotate_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	annotate_btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	annotate_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	annotate_btn.focus_mode = Control.FOCUS_NONE
	annotate_btn.tooltip_text = "圈注：拖一个框，自动生成墨圈 · Backspace 撤销 / Ctrl+Backspace 清空"
	annotate_plate.add_child(annotate_btn)
	Ui.place(annotate_btn, 2, 2, 60, 58)
	annotate_btn.pressed.connect(Callable(self, "_toggle_annotation"))
	annotate_btn.mouse_entered.connect(func():
		annotate_plate.border_color = Color("#d9c18f")
		annotate_btn.modulate = Color(1.0, 0.92, 0.78)
	)
	annotate_btn.mouse_exited.connect(Callable(self, "_update_annotate_visual"))
	annotate_mark = ColorRect.new()
	annotate_mark.color = Color("#d9c18f")
	annotate_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	annotate_plate.add_child(annotate_mark)
	Ui.place(annotate_mark, 8, 56, 48, 3)
	annotate_mark.visible = false
	call("_update_annotate_visual")

	stamp_target = _box(layer_desk, 966, 780, 292, 62, Color(244 / 255.0, 233 / 255.0, 201 / 255.0, 0.55), null, 2, Color("#8c4b3c"))
	stamp_target.z_index = 30
	stamp_target.clip_contents = true
	stamp_target.mouse_default_cursor_shape = Control.CURSOR_CROSS
	stamp_target.dashed = true
	stamp_target.dash_length = 5
	stamp_target_text = _pix(stamp_target, "拖入印章", 0, 15, 292, 16, 11, Color("#7b4b3c"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	stamp_target_sub = _pix(stamp_target, "", 0, 33, 292, 13, 9, Color("#7b4b3c"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	stamp_target_sub.visible = false
	# Ink is a child of the stamp target, not a sibling of the desk panels.
	# This keeps it clipped to the target and below loose material files.
	stamp_mark_holder = Control.new()
	stamp_target.add_child(stamp_mark_holder)
	Ui.place(stamp_mark_holder, 0, 0, 292, 62)
	stamp_mark_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_mark_holder.z_index = 2

# ============================================================
# EFFECTS / TOAST / MODAL / GHOST
# ============================================================
func _build_story_console() -> void:
	story_console = Control.new()
	story_console.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_desk.add_child(story_console)
	Ui.place(story_console, 268, 780, 990, 62)
	story_console.z_index = 32
	story_console.visible = false

	var main := _box(story_console, 0, 0, 800, 62, Color("#2f3a2f"), null, 2, Color("#151a13"), Vector2(3, 3))
	main.inner_highlight = Color("#53624f")
	story_kicker = _pix(main, "夜班", 12, 11, 776, 9, 7.5, Color("#b76550"))
	story_title = _pix(main, "灯灭之后", 12, 20, 776, 18, 14, Color("#f0e4c5"))
	story_sub = Ui.label(main, "", 12, 38, 776, 24, 9, Color("#b9b096"), Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	story_sub.add_theme_constant_override("line_spacing", Ui.line_gap(9, 12.0, Ui.F_UI))

	var prog := _box(story_console, 810, 0, 78, 62, Color("#20281e"), null, 2, Color("#151a13"))
	prog.inner_highlight = Color("#4b5946")
	story_count = _pix(prog, "01 / 03", 0, 22, 78, 9, 9, Color("#d8cfb3"), HORIZONTAL_ALIGNMENT_CENTER)
	story_dots = Control.new()
	story_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog.add_child(story_dots)
	Ui.place(story_dots, 0, 35, 78, 6)

	story_actions = Control.new()
	story_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_console.add_child(story_actions)
	Ui.place(story_actions, 898, 0, 92, 62)

func _story_button(text: String, x: float, y: float, w: float, h: float) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.add_theme_font_override("font", Ui.F_UI_BOLD)
	Ui.set_font(b, int(round(9.5)))
	b.add_theme_color_override("font_color", Color("#302a1d"))
	b.add_theme_color_override("font_hover_color", Color("#302a1d"))
	b.add_theme_color_override("font_pressed_color", Color("#302a1d"))
	var normal := Ui.flat_style(Color("#d8c8a2"), 2, Color("#1b160f"), Vector2(2, 2))
	var hover := Ui.flat_style(Color("#f0e0b8"), 2, Color("#1b160f"), Vector2(2, 2))
	var pressed := Ui.flat_style(Color("#c8b88f"), 2, Color("#1b160f"), Vector2.ZERO)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	story_actions.add_child(b)
	Ui.place(b, x, y, w, h)
	return b

func _build_fx() -> void:
	var grain := TextureRect.new()
	grain.texture = Ui.TEX_GRAIN
	grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.modulate = Color(1, 1, 1, 0.032)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	grain.material = mat
	layer_fx.add_child(grain)
	Ui.place(grain, 5, 5, 1370, 850)

	var scan := Scanlines.new()
	layer_fx.add_child(scan)
	Ui.place(scan, 5, 5, 1370, 850)

	var vig := ColorRect.new()
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 p = UV - 0.5;
	float d = length(p);
	float a = smoothstep(0.30, 0.82, d) * 0.50;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
"""
	var shm := ShaderMaterial.new()
	shm.shader = sh
	vig.material = shm
	layer_fx.add_child(vig)
	Ui.place(vig, 5, 5, 1370, 850)

	_pix(layer_fx, "THESIS, PLEASE · v1.8", 1306, 844, 64, 8, 6, Color(231 / 255.0, 220 / 255.0, 188 / 255.0, 0.36))

func _build_toast() -> void:
	toast_panel = _box(layer_toast, 0, 71, 200, 33, Color("#f0e3bd"), null, 2, Color("#17140e"), Vector2(4, 4))
	toast_panel.visible = false
	toast_accent = ColorRect.new()
	toast_accent.color = Color(0, 0, 0, 0)
	toast_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(toast_accent)
	Ui.place(toast_accent, 0, 0, 5, 33)
	toast_label = _pix(toast_panel, "", 14, 6, 180, 21, 12, Color("#2e271b"))
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _build_modal() -> void:
	modal_root = Control.new()
	modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_root.visible = false
	layer_modal.add_child(modal_root)
	modal_root.position = Vector2.ZERO
	modal_root.size = Vector2(W, H)
	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	bbc.rect = Rect2(0, 0, W, H)
	modal_root.add_child(bbc)
	var dim := ColorRect.new()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.position = Vector2.ZERO
	dim.size = Vector2(W, H)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * 2.0;
	vec4 c = texture(screen_texture, SCREEN_UV) * 0.28;
	c += texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)) * 0.12;
	c += texture(screen_texture, SCREEN_UV - vec2(px.x, 0.0)) * 0.12;
	c += texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)) * 0.12;
	c += texture(screen_texture, SCREEN_UV - vec2(0.0, px.y)) * 0.12;
	c += texture(screen_texture, SCREEN_UV + px) * 0.06;
	c += texture(screen_texture, SCREEN_UV - px) * 0.06;
	c += texture(screen_texture, SCREEN_UV + vec2(px.x, -px.y)) * 0.06;
	c += texture(screen_texture, SCREEN_UV + vec2(-px.x, px.y)) * 0.06;
	COLOR = vec4(c.rgb * 0.64, 0.72);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	dim.material = mat
	modal_root.add_child(dim)
	modal_center = CenterContainer.new()
	modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_root.add_child(modal_center)
	modal_center.position = Vector2(0, 0)
	modal_center.size = Vector2(W, H)
	modal_loose = Control.new()
	modal_loose.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_loose.z_index = 20
	modal_root.add_child(modal_loose)
	Ui.place(modal_loose, 0, 0, W, H)
	modal_fx_layer = Control.new()
	modal_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_fx_layer.z_index = 500
	modal_root.add_child(modal_fx_layer)
	Ui.place(modal_fx_layer, 0, 0, W, H)
	modal_top = Control.new()
	modal_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_top.z_index = 600
	modal_root.add_child(modal_top)
	Ui.place(modal_top, 0, 0, W, H)

func _build_ghost() -> void:
	ghost = Control.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.visible = false
	layer_ghost.add_child(ghost)
	ghost.size = Vector2(86, 78)
