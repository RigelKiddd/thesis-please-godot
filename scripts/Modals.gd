class_name Modals
extends RefCounted

## All overlay screens from the original game, rebuilt with native Godot controls.

const INK := Color("#241f17")
const PAPER := Color("#e7dcbc")
const PAPER_HI := Color("#f4e9c9")
const RED := Color("#a83a2f")
const PORTRAIT := preload("res://scripts/VisitorPortrait.gd")

## Material identities for the different paperwork that reaches window 03.
## The card content stays the same; only the paper, edge and filing strip change.
const SKINS := {
	"paper": {"bg": PAPER, "tex": "card", "accent": Color("#7a6847"), "line": Color("#7a6847")},
	"notice": {"bg": Color("#f2e5c4"), "tex": "paper_hi", "accent": Color("#a83a2f"), "line": Color("#8b382b")},
	"form": {"bg": Color("#e9e5d6"), "tex": "paper", "accent": Color("#2d4d78"), "line": Color("#6f7f95")},
	"ledger": {"bg": Color("#efe4c4"), "tex": "paper", "accent": Color("#3f6b45"), "line": Color("#7d8f6f")},
	"dossier": {"bg": Color("#d9c69c"), "tex": "paper", "accent": Color("#6d4a2c"), "line": Color("#8b6b45")},
	"ticket": {"bg": Color("#f1e3bc"), "tex": "paper", "accent": Color("#8b382b"), "line": Color("#9b6a3c")},
	"sticky": {"bg": Color("#e3cc74"), "tex": "", "accent": Color("#7a5c1e"), "line": Color("#b39a52")},
	"dark": {"bg": Color("#211d18"), "tex": "", "accent": Color("#b64a3a"), "line": Color("#6b4a3a"), "label": Color("#d8c49a"), "code": Color("#8f7d5e")},
}

static func _card(width: float, pad_l: int = 24, pad_t: int = 24, pad_r: int = 27, pad_b: int = 22,
		bg: Color = PAPER) -> Array:
	var outer := PanelContainer.new()
	outer.custom_minimum_size.x = width
	outer.mouse_filter = Control.MOUSE_FILTER_STOP
	var os := StyleBoxFlat.new()
	os.bg_color = Color(0, 0, 0, 0.001)
	os.shadow_color = Color(0, 0, 0, 0.42)
	os.shadow_size = 1
	os.shadow_offset = Vector2(8, 9)
	outer.add_theme_stylebox_override("panel", os)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = width
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	outer.add_child(card)
	if bg.get_luminance() > 0.3 and Ui.TEX_CARD != null:
		var st := StyleBoxTexture.new()
		st.texture = Ui.TEX_CARD
		st.texture_margin_left = 18
		st.texture_margin_top = 18
		st.texture_margin_right = 18
		st.texture_margin_bottom = 18
		st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		st.content_margin_left = pad_l
		st.content_margin_top = pad_t
		st.content_margin_right = pad_r
		st.content_margin_bottom = pad_b
		card.add_theme_stylebox_override("panel", st)
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.border_width_bottom = 3
		sb.border_color = Color("#1b1710")
		sb.content_margin_left = pad_l
		sb.content_margin_top = pad_t
		sb.content_margin_right = pad_r
		sb.content_margin_bottom = pad_b
		sb.shadow_color = Color(0, 0, 0, 0.42)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(8, 9)
		card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	return [outer, v]

static func _kicker(parent: Node, text: String, color: Color = Color("#7a6847")) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(h)
	var dot := PixelPanel.new()
	dot.bg_color = RED
	dot.rotation = deg_to_rad(45)
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dot)
	var l := Ui.label(h, text, 0, 0, 0, 12, 9, color, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.y = 12
	return l

static func _h2(parent: Node, text: String, size: int = 38, color: Color = Color("#292317")) -> Label:
	var l := Ui.label(parent, text, 0, 0, 0, size + 6, size, color, Ui.F_PIXEL_TITLE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	l.custom_minimum_size.y = size + 4
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func _body(parent: Node, text: String, size: int, color: Color, width: float,
		line_px: float, font: Font = null) -> RichTextLabel:
	if font == null:
		font = Ui.F_DOC
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lines: int = max(1, int(ceil(tw / max(1.0, width))))
	var h: float = lines * line_px + 2.0
	var r := Ui.rich(parent, text, 0, 0, width, h, size, color, font, line_px)
	r.custom_minimum_size = Vector2(width, h)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

static func _spacer(parent: Node, h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c

static func _actions(parent: Node) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 9)
	h.custom_minimum_size.y = 52
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(h)
	return h

static func _button(parent: Node, text: String, action: String, cb: Callable, primary: bool = true,
		w: float = 0.0, h: float = 40.0) -> Button:
	var bg := Color("#91362d") if primary else PAPER_HI
	var fg := Color("#f5e7c5") if primary else Color("#2b2418")
	var bc := Color("#38100d") if primary else Color("#17130d")
	var b := Ui.button(parent, 0, 0, w if w > 0.0 else 150, h, text, 13, fg, bg, bc, Ui.F_PIXEL, Vector2(4, 4) if primary else Vector2(3, 3))
	b.custom_minimum_size = Vector2(w if w > 0.0 else 150, h)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): cb.call(action))
	return b

static func _stamp_box(lines: Array, w: float, h: float, rot: float = 5.0,
		color: Color = Color(154 / 255.0, 50 / 255.0, 40 / 255.0, 0.8), font_sizes: Array = [7, 25, 7]) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer := PixelPanel.new()
	outer.bg_color = Color(0, 0, 0, 0)
	outer.border_width = 3
	outer.border_color = color
	c.add_child(outer)
	Ui.place(outer, 0, 0, w, h)
	var inner := PixelPanel.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.border_width = 1
	inner.border_color = color
	c.add_child(inner)
	Ui.place(inner, 4, 4, w - 8, h - 8)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	c.add_child(v)
	Ui.place(v, 0, 2, w, h - 4)
	for i in range(lines.size()):
		var l := Ui.label(v, str(lines[i]), 0, 0, 0, 10, int(font_sizes[i]) if i < font_sizes.size() else 9,
			color, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.y = 12 if i == 1 else 9
	c.rotation = deg_to_rad(rot)
	c.pivot_offset = Vector2(w * 0.5, h * 0.5)
	return c

# ------------------------------------------------------------
# material skins
# ------------------------------------------------------------
static func _skin_card(width: float, skin: String, label: String, code: String,
		pad_l: int = 24, pad_t: int = 24, pad_r: int = 27, pad_b: int = 22,
		bg_override: Color = Color(0, 0, 0, 0)) -> Array:
	var s: Dictionary = SKINS.get(skin, SKINS["paper"])
	var bg: Color = s.get("bg", PAPER)
	if bg_override.a > 0.0:
		bg = bg_override
	var parts := _card(width, pad_l, pad_t + 4, pad_r, pad_b, bg)
	var outer: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	var inner: PanelContainer = outer.get_child(0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color("#1b1710") if skin != "dark" else Color("#080a07")
	sb.content_margin_left = pad_l
	sb.content_margin_top = pad_t + 4
	sb.content_margin_right = pad_r
	sb.content_margin_bottom = pad_b
	inner.add_theme_stylebox_override("panel", sb)
	var tex := _skin_texture(str(s.get("tex", "")))
	if tex != null:
		var sheet := TextureRect.new()
		sheet.texture = tex
		sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sheet.stretch_mode = TextureRect.STRETCH_TILE
		sheet.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(sheet)
		inner.move_child(sheet, 0)
		sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var accent: Color = s.get("accent", Color("#7a6847"))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.custom_minimum_size.y = 13
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := ColorRect.new()
	mark.color = accent
	mark.custom_minimum_size = Vector2(3, 11)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(mark)
	var title := Ui.label(head, label, 0, 0, 0, 12, 7,
		s.get("label", accent), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size.y = 11
	var code_label := Ui.label(head, code, 0, 0, 0, 12, 6.5,
		s.get("code", Color("#7a6847")), Ui.F_MONO, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_CENTER, false)
	code_label.custom_minimum_size.y = 11
	v.add_child(head)
	v.move_child(head, 0)
	if skin == "ticket":
		var perf := PixelPanel.new()
		perf.dashed = true
		perf.border_width = 1
		perf.border_color = s.get("line", accent)
		perf.custom_minimum_size.y = 3
		perf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		perf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(perf)
		v.move_child(perf, 1)
	else:
		var rule := ColorRect.new()
		rule.color = Color(accent.r, accent.g, accent.b, 0.72)
		rule.custom_minimum_size.y = 2
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(rule)
		v.move_child(rule, 1)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	v.move_child(spacer, 2)
	return parts


static func _skin_texture(id: String) -> Texture2D:
	match id:
		"paper":
			return Ui.TEX_PAPER
		"paper_hi":
			return Ui.TEX_PAPER_HI
		"card":
			return Ui.TEX_CARD
		"folder":
			return Ui.TEX_FOLDER
	return null


# ------------------------------------------------------------
# title
# ------------------------------------------------------------
static func title(cb: Callable, has_save: bool = false, save_day: int = -1) -> Control:
	var parts := _skin_card(700, "dossier", "03 窗口 · 聘任档案", "NO. 03-00", 30, 30, 34, 25)
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(left)
	Ui.label(left, "明州大学 · 教务处", 0, 0, 0, 12, 10, Color("#7b6846"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var brand := Ui.label(left, "论文审批处", 0, 0, 0, 78, 72, Color("#292216"), Ui.F_PIXEL_TITLE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	brand.custom_minimum_size.y = 74
	brand.add_theme_color_override("font_shadow_color", Color(183 / 255.0, 166 / 255.0, 127 / 255.0, 0.9))
	brand.add_theme_constant_override("shadow_offset_x", 3)
	brand.add_theme_constant_override("shadow_offset_y", 3)
	Ui.label(left, "THESIS, PLEASE", 0, 0, 0, 14, 11, Color("#8c3a2f"), Ui.F_PIXEL_SPACED, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var stamp := _stamp_box(["本科论文", "03", "审查窗"], 86, 86, 7.0, Color(144 / 255.0, 48 / 255.0, 39 / 255.0, 0.8), [9, 22, 7])
	top.add_child(stamp)
	var line := ColorRect.new()
	line.color = Color("#56472e")
	line.custom_minimum_size.y = 2
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(line)
	_spacer(v, 12)
	_body(v, "你是周明远，被借调到教务处 03 窗口，审查 28 份本科论文。核对材料，然后[b]盖章[/b]。", 12, Color("#4f4230"), 620, 22.2, Ui.F_DOC)
	if has_save:
		_spacer(v, 8)
		Ui.label(v, "检测到第 %d 天的自动存档；继续会回到当天早晨。" % maxi(1, save_day + 1), 0, 0, 0, 18, 9, Color("#8c3a2f"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	_spacer(v, 12)
	Ui.label(v, "RULES OF THE WINDOW", 0, 0, 0, 12, 9, Color("#6e5b3b"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var rule_line := HBoxContainer.new()
	rule_line.add_theme_constant_override("separation", 7)
	rule_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(rule_line)
	var rl := Ui.label(rule_line, "7 天 · 28 份论文 · 3 种印章 · 误判会扣绩效与声誉", 0, 0, 0, 40, 9, Color("#7b6846"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.custom_minimum_size.y = 40
	_spacer(v, 12)
	var acts := _actions(v)
	if has_save:
		var cont := _button(acts, "继续值班", "continue", cb, true, 178, 50)
		Ui.set_font(cont, int(round(16)))
		_button(acts, "重新开始", "start", cb, false, 122, 50)
	else:
		var b := _button(acts, "开始值班", "start", cb, true, 190, 50)
		Ui.set_font(b, int(round(16)))
	_button(acts, "设置", "open-settings", cb, false, 86, 50)
	var note := Ui.label(acts, "每天下班后有一次夜班批示。", 0, 0, 0, 42, 8, Color("#8b7957"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, true)
	note.custom_minimum_size.x = 250
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card

# ------------------------------------------------------------
# day intro
# ------------------------------------------------------------
static func day_intro(day_idx: int, day: Dictionary, new_rules: Array, new_materials: Array, cb: Callable) -> Control:
	var parts := _skin_card(610, "notice", "03 窗口 · 每日通告", "NO. 03-D%02d" % (day_idx + 1))
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(left)
	_kicker(left, "教务处通知")
	Ui.label(left, "%s · %s · 第 %d 个工作日" % [day.get("date", ""), day.get("weekday", ""), day_idx + 1], 0, 0, 0, 14, 9, Color("#7a6847"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	head.add_child(_stamp_box(["DAY", "%02d" % (day_idx + 1), str(day.get("weekday", ""))], 67, 67, 5.0, Color(154 / 255.0, 50 / 255.0, 40 / 255.0, 0.8), [7, 25, 7]))
	_h2(v, str(day.get("theme", "")))
	_body(v, str(day.get("notice", "")), 12, Color("#4a3f2d"), 556, 22.2, Ui.F_DOC)
	if new_rules.size() > 0:
		_spacer(v, 6)
		var box := _info_box(v, 556, RED, Color(255, 255, 255, 0.18))
		var box_v: VBoxContainer = box[1]
		Ui.label(box_v, "今日新增条例", 0, 0, 0, 16, 10, Color("#6b5738"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		for g in new_rules:
			Ui.label(box_v, "%s · %s" % [g.get("code", ""), g.get("title", "")], 0, 0, 0, 14, 10, Color("#5d4b2f"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
			for rule in g.get("rules", []):
				_body(box_v, "■  " + str(rule), 10, Color("#3f3524"), 522, 17.3, Ui.F_UI)
	if new_materials.size() > 0:
		_spacer(v, 6)
		var box2 := _info_box(v, 556, Color("#4f6a4c"), Color(107 / 255.0, 133 / 255.0, 101 / 255.0, 0.14))
		var bv2: VBoxContainer = box2[1]
		Ui.label(bv2, "新附件已放入材料架", 0, 0, 0, 16, 10, Color("#4f6a4c"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		for m in new_materials:
			_body(bv2, "▸  %s · %s" % [m.get("label", ""), m.get("unlockNote", "")], 10, Color("#3f3524"), 522, 17.3, Ui.F_UI)
	_spacer(v, 8)
	Ui.label(v, "今日 %d 位学生。先核对材料，再盖章。" % int(day.get("students", []).size()), 0, 0, 0, 28, 9, Color("#7b6846"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	_spacer(v, 10)
	var acts := _actions(v)
	_button(acts, "开始审查", "begin-day", cb, true, 160, 42)
	return card

static func _info_box(parent: Node, width: float, border: Color, bg: Color) -> Array:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = width
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 7
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	parent.add_child(p)
	return [p, v]

# ------------------------------------------------------------
# help
# ------------------------------------------------------------
static func help(cb: Callable) -> Control:
	var parts := _skin_card(680, "sticky", "03 窗口 · 操作说明", "REF. 03-H")
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	_kicker(v, "操作说明")
	_h2(v, "审查操作")
	_spacer(v, 6)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	_help_section(grid, "审查流程", [
		"卷宗标签翻论文主件；附件在右侧材料架。",
		"附件在右侧材料架，点卡片展开；可同时展开多份。",
		"印章拖到论文或结论栏；也可点选后按 Enter。",
		"圈注命中缺陷 +¥20；圈错会提示问题所在方向。",
		"有缺陷的学生可三选一回复；“最担心哪项”每人只能问一次。",
		"每天下班后有一次夜班批示，内容在桌上文件里。",
		"夜班之后分配精力/金钱：放进项目框，再用完硬币进入下一天。",
		"灯灭之前下方是桌子：F/C 展开文件，纸卡可拖动；来访时可随附一份文件。",
		"每次分配开始前可能有人来访；批 / 驳 / 缓会改变不同人的印象。",
		"学生通过后，所在学院的导师与主任各记 1 点人情；满 2 位规范通过会收到学院感谢函。"
	])
	_help_section(grid, "三种结论", [
		"通过：材料符合全部现行条例。",
		"退回修改：存在可整改的格式、材料或行政问题。",
		"不通过：查重 >30%、伪造报告等学术不端红线。"
	])
	var keys := [["选择通过", "1"], ["选择退回修改", "2"], ["选择不通过", "3"], ["盖章", "Enter"], ["切换材料", "← →"], ["人情簿", "F"], ["学院关系", "C"], ["设置", "G"], ["关闭弹窗", "Esc / Tab"], ["音效 / 帮助", "M / H"]]
	var kh := VBoxContainer.new()
	kh.add_theme_constant_override("separation", 0)
	kh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(kh)
	Ui.label(kh, "快捷键", 0, 0, 0, 18, 11, Color("#5e4d32"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	for pair in keys:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var a := Ui.label(row, str(pair[0]), 0, 0, 0, 16, 10, Color("#514533"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kb := Ui.label(row, str(pair[1]), 0, 0, 0, 16, 9, Color("#3c3120"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
		kb.custom_minimum_size = Vector2(36, 16)
		kh.add_child(row)
	var last := VBoxContainer.new()
	last.add_theme_constant_override("separation", 2)
	grid.add_child(last)
	Ui.label(last, "绩效与投诉", 0, 0, 0, 18, 11, Color("#5e4d32"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	_body(last, "正确 +¥120；误判 −¥80，并记 1 次投诉。声誉 5 点，归零停职。零误判每天 +¥300。", 10, Color("#564935"), 300, 16.5, Ui.F_UI)
	_spacer(v, 12)
	var acts := _actions(v)
	_button(acts, "知道了", "close-help", cb, true, 180, 42)
	return card

static func _help_section(parent: Node, title: String, lines: Array) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = Color("#a08c65")
	line.custom_minimum_size.y = 1
	v.add_child(line)
	Ui.label(v, title, 0, 0, 0, 18, 11, Color("#5e4d32"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	for text in lines:
		_body(v, "· " + str(text), 10, Color("#564935"), 300, 16.5, Ui.F_UI)
	parent.add_child(v)

# ------------------------------------------------------------
# settings
# ------------------------------------------------------------
static func duty_log(st: Dictionary, entries: Array, cb: Callable) -> Control:
	var card := preload("res://scripts/ui/DutyLogCard.gd").new()
	card.setup(entries, cb)
	return card

static func settings(st: Dictionary, cb: Callable) -> Control:
	var parts := _skin_card(560, "form", "03 窗口 · 设置", "REF. 03-G", 26, 24, 29, 20)
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	_kicker(v, "可访问性 / SETTINGS")
	_h2(v, "窗口设置", 34)
	_body(v, "改动立即生效并保存。Esc 关闭，Tab 移动焦点，Enter / Space 激活。", 10, Color("#564935"), 500, 17.0, Ui.F_UI)
	_spacer(v, 8)
	var grid := GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	_setting_row(grid, "界面缩放", str(st.get("scale", "100%")), "settings-scale", cb, "整扇窗口等比放大，不裁切桌面。")
	_setting_row(grid, "字号", str(st.get("text_scale", "100%")), "settings-text", cb, "放大文字并增加行距，不改变窗口大小。")
	_setting_row(grid, "立绘 shader", "开" if bool(st.get("portrait_shader", true)) else "关", "settings-portrait", cb, "grimoire 色域层；关掉回到 STYLE 原色。")
	_setting_row(grid, "减少屏幕震动 / 闪光", "已开启" if bool(st.get("reduce_motion", false)) else "关闭", "settings-motion", cb, "保留印章颜色与声音反馈。")
	_setting_row(grid, "文字速度", str(st.get("text_speed", "正常")), "settings-speed", cb, "同时影响学生陈述与微信节奏。")
	_setting_row(grid, "本地 playtest 记录", "开" if bool(st.get("metrics_enabled", true)) else "关", "settings-metrics", cb, "只写本机 user://session.json，不联网、不上报。")
	_setting_row(grid, "音效", "开" if !bool(st.get("muted", false)) else "关", "settings-sound", cb, "与 M 键同步。")
	_spacer(v, 10)
	var acts := _actions(v)
	_button(acts, "关闭", "settings-close", cb, true, 160, 42)
	return card

static func _setting_row(parent: Node, k: String, value: String, action: String, cb: Callable, hint: String) -> void:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(255, 255, 255, 0.16)
	sb.border_width_left = 2
	sb.border_color = Color("#8d7852")
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	Ui.label(left, k, 0, 0, 0, 16, 11, Color("#3d3322"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	Ui.label(left, hint, 0, 0, 0, 12, 8, Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	_button(h, value + "  ›", action, cb, false, 104, 34)
	parent.add_child(p)

# ------------------------------------------------------------
# complaint
# ------------------------------------------------------------
static func complaint(student: Dictionary, audit: Dictionary, chosen: String, state: Dictionary, cb: Callable) -> Control:
	var parts := _skin_card(650, "form", "03 窗口 · 投诉单", "NO. 03-C")
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	var top := ColorRect.new()
	top.color = RED
	top.custom_minimum_size.y = 7
	v.add_child(top)
	v.move_child(top, 0)
	_kicker(v, "教学投诉单", RED)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(left)
	_h2(left, "判错了。", 38, Color("#6f271f"))
	Ui.label(left, "学生：%s · %s · %s" % [student.get("name", ""), student.get("official", {}).get("id", ""), student.get("official", {}).get("major", "")], 0, 0, 0, 14, 8, Color("#7a6847"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	head.add_child(_stamp_box(["剩余声誉", str(state.get("rep", 0)), "/ 05"], 67, 67, 5.0, Color(154 / 255.0, 50 / 255.0, 40 / 255.0, 0.8), [7, 25, 7]))
	_spacer(v, 6)
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	var picked := GameData.outcome(chosen)
	var expected := GameData.outcome(str(audit.get("expected", "pass")))
	_complaint_box(grid, "你盖下的章", str(picked.get("label", "")), Color("#b07162"), Color("#342b1d"))
	_complaint_box(grid, "正确结论", str(expected.get("label", "")), Color("#5d7d58"), Color("#3e603f"))
	_spacer(v, 4)
	Ui.label(v, "问题", 0, 0, 0, 24, 14, Color("#4b3f2a"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var defects: Array = audit.get("defects", [])
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	v.add_child(list)
	var line0 := ColorRect.new()
	line0.color = Color("#9b875e")
	line0.custom_minimum_size.y = 1
	list.add_child(line0)
	if defects.is_empty():
		_defect_row(list, "材料本身符合全部现行条例，不应退回或否决。", false)
	else:
		for d in defects:
			_defect_row(list, str(d.get("text", "")), str(d.get("severity", "")) == "critical")
	_spacer(v, 5)
	var replay_head := HBoxContainer.new()
	replay_head.add_theme_constant_override("separation", 8)
	v.add_child(replay_head)
	Ui.label(replay_head, "你的圈注回放", 0, 0, 0, 16, 9, Color("#5d4b2f"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	var attempts: Array = state.get("annotations", [])
	Ui.label(replay_head, "%d 次落笔" % attempts.size(), 0, 0, 0, 16, 8, Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_CENTER, false)
	var replay := VBoxContainer.new()
	replay.add_theme_constant_override("separation", 0)
	v.add_child(replay)
	if attempts.is_empty():
		_body(replay, "· 这一份你没有圈注。", 9, Color("#6d5b3e"), 590, 14.0, Ui.F_UI)
	else:
		var shown := 0
		for a in attempts:
			if shown >= 3:
				break
			var hit := bool(a.get("hit", false))
			var text := str(a.get("label", "圈注"))
			if !hit:
				text = "圈在空白或非问题区"
			_body(replay, ("✓ " if hit else "✗ ") + text, 9, Color("#3f6b45") if hit else Color("#8b382b"), 590, 14.0, Ui.F_UI)
			shown += 1
		if attempts.size() > shown:
			_body(replay, "…另有 %d 次未列出" % (attempts.size() - shown), 8, Color("#7a6847"), 590, 12.0, Ui.F_UI)
	_spacer(v, 8)
	var pen := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.08)
	ps.border_width_left = 2
	ps.border_width_top = 2
	ps.border_width_right = 2
	ps.border_width_bottom = 2
	ps.border_color = Color("#8d3c31")
	ps.content_margin_left = 8
	ps.content_margin_right = 8
	ps.content_margin_top = 6
	ps.content_margin_bottom = 6
	pen.add_theme_stylebox_override("panel", ps)
	var ph := HBoxContainer.new()
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ui.label(ph, "绩效 -¥80　·　教学投诉 +1", 0, 0, 0, 16, 9, Color("#762d24"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ph.add_child(sp)
	Ui.label(ph, "剩余声誉：%d / 5" % int(state.get("rep", 0)), 0, 0, 0, 16, 9, Color("#762d24"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	pen.add_child(ph)
	v.add_child(pen)
	_spacer(v, 6)
	_body(v, "投诉单将计入年度考核，不能撤回。", 11, Color("#4b3e2b"), 590, 18.7, Ui.F_DOC)
	_spacer(v, 10)
	var acts := _actions(v)
	_button(acts, "签收停职" if int(state.get("rep", 0)) <= 0 else "签收", "ack-wrong", cb, true, 180, 42)
	return card

static func _complaint_box(parent: Node, k: String, value: String, border: Color, color: Color) -> void:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.18)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	Ui.label(v, k, 0, 0, 0, 10, 8, Color("#7c6a49"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	Ui.label(v, value, 0, 0, 0, 22, 15, color, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	parent.add_child(p)

static func _defect_row(parent: Node, text: String, critical: bool) -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#6f1f18") if critical else Color("#a83a2f")
	bs.content_margin_left = 4
	bs.content_margin_right = 4
	badge.add_theme_stylebox_override("panel", bs)
	h.add_child(badge)
	var ml := Ui.label(badge, "!", 0, 0, 0, 12, 8, Color("#f4e6c5"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	ml.custom_minimum_size = Vector2(12, 12)
	var body := _body(h, text, 10, Color("#4a3c28"), 540, 16.3, Ui.F_DOC)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(h)
	var line := ColorRect.new()
	line.color = Color(179 / 255.0, 161 / 255.0, 123 / 255.0, 0.6)
	line.custom_minimum_size.y = 1
	wrap.add_child(line)
	parent.add_child(wrap)

# ------------------------------------------------------------
# shift report
# ------------------------------------------------------------
static func shift(day_idx: int, day: Dictionary, st: Dictionary, cb: Callable) -> Control:
	var perfect := int(st.get("daily_wrong", 0)) == 0
	var parts := _skin_card(610, "ticket", "03 窗口 · 下班打卡", "NO. 03-S%02d" % (day_idx + 1))
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(left)
	_kicker(left, "下班打卡单")
	Ui.label(left, "%s · %s · %s 打卡" % [day.get("shortDate", ""), day.get("weekday", ""), _clock(int(st.get("clock", 1030)))], 0, 0, 0, 14, 9, Color("#7a6847"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	head.add_child(_stamp_box(["DAY", "%02d" % (day_idx + 1), "零差错" if perfect else "有投诉"], 67, 67, 5.0, Color(154 / 255.0, 50 / 255.0, 40 / 255.0, 0.8), [7, 25, 6]))
	_h2(v, "今日零误判。" if perfect else "今日有误判。", 34)
	_spacer(v, 8)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 7)
	v.add_child(cards)
	var total := int(day.get("students", []).size())
	var delta := int(st.get("perf", 0)) - int(st.get("day_start_perf", 0))
	var accuracy := int(round(float(st.get("daily_correct", 0)) / max(1.0, float(total)) * 100.0))
	_stat_card(cards, "正确审查", "%d / %d" % [int(st.get("daily_correct", 0)), total], Color("#302819"))
	_stat_card(cards, "误判", str(int(st.get("daily_wrong", 0))), RED if int(st.get("daily_wrong", 0)) > 0 else Color("#302819"))
	_stat_card(cards, "今日绩效", ("+" if delta >= 0 else "−") + "¥" + Ui.fmt_money(abs(delta)), Color("#4f7652") if delta >= 0 else RED)
	_stat_card(cards, "正确率", "%d%%" % accuracy, Color("#302819"))
	_spacer(v, 8)
	var msg := PanelContainer.new()
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(79 / 255.0, 118 / 255.0, 82 / 255.0, 0.07) if perfect else Color(155 / 255.0, 60 / 255.0, 47 / 255.0, 0.07)
	ms.border_width_left = 4
	ms.border_color = Color("#4f7652") if perfect else Color("#9b3c2f")
	ms.content_margin_left = 10
	ms.content_margin_right = 10
	ms.content_margin_top = 8
	ms.content_margin_bottom = 8
	msg.add_theme_stylebox_override("panel", ms)
	var mtxt := "零误判：+¥300，声誉 +1。" if perfect else (
		"零误判。" if int(st.get("daily_wrong", 0)) == 0 else
		("%d 次误判，教务处已记录。" % int(st.get("daily_wrong", 0))))
	_body(msg, mtxt, 11, Color("#4b3e2b"), 570, 18.7, Ui.F_DOC)
	v.add_child(msg)
	var ac := int(st.get("annotation_count", 0))
	var cr: Array = st.get("chat_replies", [])
	var chat_line := str(st.get("chat_line", ""))
	var request_total := int(st.get("request_total", 0))
	var request_pending := int(st.get("request_pending", 0))
	if ac > 0 or cr.size() > 0 or chat_line != "" or request_total > 0:
		var bits: Array = []
		if ac > 0:
			bits.append("圈注 %d 处" % ac)
		if cr.size() > 0:
			bits.append("微信回复 %d 次" % cr.size())
		if chat_line != "":
			bits.append(chat_line)
		if request_total > 0:
			bits.append("行政待办 %d/%d" % [request_total - request_pending, request_total])
		if int(st.get("time_saved", 0)) > 0:
			bits.append("提前 %d 分钟收工" % int(st.get("time_saved", 0)))
		Ui.label(v, " · ".join(PackedStringArray(bits)), 0, 0, 0, 18, 8, Color("#6d5a3c"), Ui.F_DOC, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	var favor_today: Array = st.get("favor_today", [])
	if !favor_today.is_empty():
		var fbits: Array = []
		for entry in favor_today:
			var fdelta := int(entry.get("delta", 0))
			fbits.append("%s %s%d" % [str(entry.get("name", "")), "+" if fdelta > 0 else "−", absi(fdelta)])
		Ui.label(v, "今日人情：" + " · ".join(PackedStringArray(fbits)), 0, 0, 0, 18, 8,
			Color("#3f6b45"), Ui.F_DOC, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	_spacer(v, 6)
	Ui.label(v, "教务处 · %s" % day.get("date", ""), 0, 0, 0, 22, 9, Color("#6d5a3c"), Ui.F_DOC, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_TOP, true)
	_spacer(v, 8)
	var acts := _actions(v)
	_button(acts, "结束" if day_idx >= 6 else "下班", "next-day", cb, true, 180, 42)
	return card

static func _stat_card(parent: Node, label_text: String, value: String, color: Color) -> void:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.2)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#7b6747")
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 6
	sb.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var l := Ui.label(v, label_text, 0, 0, 0, 10, 7, Color("#7a6847"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Ui.label(v, value, 0, 0, 0, 22, 18, color, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)

static func _clock(minutes: int) -> String:
	var m := ((minutes % 1440) + 1440) % 1440
	return "%02d:%02d" % [int(m / 60), m % 60]

# ------------------------------------------------------------
# game over
# ------------------------------------------------------------
static func game_over(st: Dictionary, cb: Callable) -> Control:
	var parts := _skin_card(600, "dark", "03 窗口 · 停职通知", "NO. 03-X", 24, 24, 27, 22, Color("#211d18"))
	var card: PanelContainer = parts[0]
	var sb := card.get_theme_stylebox("panel") as StyleBoxFlat
	sb.border_color = Color("#0a0a07")
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_offset = Vector2(12, 14)
	card.add_theme_stylebox_override("panel", sb)
	var v: VBoxContainer = parts[1]
	_kicker(v, "教务处通知", Color("#b69b69"))
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(540, 78)
	v.add_child(holder)
	holder.add_child(_stamp_box(["停 职"], 112, 70, -6.0, Color("#b64a3a"), [27]))
	_h2(v, "审查资格暂停。", 34, Color("#e4d2ac"))
	_body(v, "声誉归零，审查资格暂停。未审材料转交 04 窗口。", 12, Color("#b9aa8b"), 540, 22.2, Ui.F_DOC)
	_spacer(v, 8)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 7)
	v.add_child(cards)
	_dark_stat(cards, "坚持到", "第 %d 日" % (int(st.get("day", 0)) + 1))
	_dark_stat(cards, "正确", str(int(st.get("total_correct", 0))))
	_dark_stat(cards, "误判", str(int(st.get("total_wrong", 0))))
	_dark_stat(cards, "绩效", "¥" + Ui.fmt_money(int(st.get("perf", 0))))
	_spacer(v, 8)
	var acts := _actions(v)
	_button(acts, "重新开始", "restart", cb, true, 160, 42)
	return card

static func _dark_stat(parent: Node, k: String, value: String) -> void:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.035)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#5e5543")
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var l := Ui.label(v, k, 0, 0, 0, 10, 7, Color("#94866c"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Ui.label(v, value, 0, 0, 0, 22, 18, Color("#e3d2ac"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)

# ------------------------------------------------------------
# visitor / favors (v1.14)
# ------------------------------------------------------------
static func _visitor_header(v: Dictionary, role: Dictionary, display_name: String,
		state: Dictionary, index: int, total: int, stamp_line: String, stamp_color: Color,
		compact: bool = false) -> HBoxContainer:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	if !compact:
		var portrait := PORTRAIT.new()
		portrait.setup(role, display_name)
		head.add_child(portrait)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 1)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(left)
	_kicker(left, "来访登记 / VISITOR · 第 %d / %d 位" % [index, total])
	var name := Ui.label(left, display_name, 0, 0, 0, 34, 28 if compact else 30, Color("#292317"), Ui.F_PIXEL_TITLE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	name.custom_minimum_size.y = 34
	Ui.label(left, "今晚剩余：精力 %d · 金钱 %d" % [int(state.get("energy", 0)), int(state.get("money", 0))],
		0, 0, 0, 16, 9, Color("#7a6847"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	head.add_child(_stamp_box(["来 访", str(role.get("seal", "")), stamp_line], 74, 74, 4.0, stamp_color, [7, 22, 7]))
	return head


static func _visitor_story(v: Dictionary, width: float = 580.0) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	for para in v.get("story", []):
		_body(box, str(para), 11.5, Color("#4a3e2c"), width, 21.4, Ui.F_DOC)
	return box


static func _section_title(parent: Node, text: String, color: Color = Color("#8b382b")) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sq := ColorRect.new()
	sq.color = color
	sq.custom_minimum_size = Vector2(5, 5)
	sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sq)
	var l := Ui.label(h, text, 0, 0, 0, 16, 8.5, color, Ui.F_PIXEL,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	l.custom_minimum_size.y = 14
	var line := ColorRect.new()
	line.color = Color(color.r, color.g, color.b, 0.26)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(line)
	parent.add_child(h)


static func _visitor_field(parent: Node, label: String, value: String, width: float) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 1)
	cell.custom_minimum_size.x = width
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.label(cell, label, 0, 0, 0, 10, 7, Color("#7a6847"), Ui.F_UI_BOLD,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var val := Ui.label(cell, value, 0, 0, 0, 15, 9.5, Color("#2b2418"), Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	val.clip_text = true
	val.custom_minimum_size.y = 14
	var line := ColorRect.new()
	line.color = Color(85 / 255.0, 70 / 255.0, 45 / 255.0, 0.32)
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(line)
	parent.add_child(cell)
	return cell


static func _visitor_fields(v: Dictionary, role: Dictionary, display_name: String, state: Dictionary) -> VBoxContainer:
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 5)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 14)
	_visitor_field(r1, "来访人", display_name, 190)
	_visitor_field(r1, "单位 / 职务", "%s · %s" % [str(role.get("role", "")), str(role.get("office", ""))], 430)
	grid.add_child(r1)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 14)
	_visitor_field(r2, "来访时间", _clock(int(state.get("clock", 0))), 190)
	_visitor_field(r2, "接待窗口", "03 号窗口 · 周明远", 430)
	grid.add_child(r2)
	var r3 := HBoxContainer.new()
	r3.add_theme_constant_override("separation", 14)
	_visitor_field(r3, "来访事由", str(v.get("title", "")), 634)
	grid.add_child(r3)
	return grid


static func _visitor_items(parent: Node, items: Array, selected: String, cb: Callable) -> void:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 5)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(flow)
	if items.is_empty():
		Ui.label(flow, "没有可提交的文件。", 0, 0, 0, 16, 8, Color("#7a6847"), Ui.F_UI,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
		return
	var shown: Array = []
	for raw in items:
		var d: Dictionary = raw
		if bool(d.get("consumable", false)):
			shown.append(raw)
	for raw in items:
		var d: Dictionary = raw
		if !bool(d.get("consumable", false)) and shown.size() < 8:
			shown.append(raw)
	if shown.size() > 8:
		shown = shown.slice(0, 8)
	var hidden := items.size() - shown.size()
	var has_selected := false
	for raw in shown:
		var d: Dictionary = raw
		if str(d.get("id", "")) == selected:
			has_selected = true
			break
	if selected != "" and !has_selected:
		var picked_item := {}
		for raw in items:
			var d: Dictionary = raw
			if str(d.get("id", "")) == selected:
				picked_item = raw
				break
		if !picked_item.is_empty():
			shown.insert(0, picked_item)
			if shown.size() > 8:
				shown = shown.slice(0, 8)
	for raw in shown:
		var item: Dictionary = raw
		var id := str(item.get("id", ""))
		var picked := id == selected
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(150, 34)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#f4e9cd") if !picked else Color("#f7e3b8")
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color("#a83a2f") if picked else Color("#8d7a53")
		sb.content_margin_left = 5
		sb.content_margin_right = 5
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		chip.add_theme_stylebox_override("panel", sb)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 0)
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var title := Ui.label(info, str(item.get("title", id)), 0, 0, 0, 14, 8.5,
			Color("#2b2418"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		title.clip_text = true
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var use := "一次性" if bool(item.get("consumable", false)) else "可复用"
		var sub := Ui.label(info, "%s · 人情 +%d · 绩效 +¥%d" % [use, int(item.get("submit_favor", 1)), int(item.get("submit_perf", 20))],
			0, 0, 0, 9, 6.2, Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if picked:
			title.add_theme_color_override("font_color", Color("#a83a2f"))
			sub.text = "已附 · " + sub.text
		chip.add_child(info)
		var item_id := id
		chip.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					cb.call("visitor-item:" + item_id)
					chip.accept_event()
		)
		flow.add_child(chip)
	hidden = items.size() - shown.size()
	var note := "一次来访只能附一份；感谢函/通行条会归档，簿子/账本可复用。"
	if hidden > 0:
		note += " 另有 %d 份文件未列出（桌上可查看）。" % hidden
	Ui.label(parent, note, 0, 0, 0, 13, 7,
		Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)


static func _visitor_option_row(parent: Node, opt: Dictionary, index: int, affordable: bool, cb: Callable) -> void:
	var tag := str(opt.get("tag", "批"))
	var tag_color := Color("#3f6b45") if tag == "批" else (Color("#9b3127") if tag == "驳" else Color("#a56a22"))
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if affordable else Control.CURSOR_ARROW
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.018)
	sb.border_width_bottom = 1
	sb.border_color = Color(85 / 255.0, 70 / 255.0, 45 / 255.0, 0.26)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	row.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tick := PixelPanel.new()
	tick.bg_color = Color(0, 0, 0, 0)
	tick.border_width = 2
	tick.border_color = tag_color if affordable else Color("#a59a82")
	tick.custom_minimum_size = Vector2(14, 14)
	tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tick)
	var stamp := PixelPanel.new()
	stamp.bg_color = Color(tag_color.r, tag_color.g, tag_color.b, 0.13)
	stamp.border_width = 1
	stamp.border_color = tag_color
	stamp.custom_minimum_size = Vector2(22, 22)
	stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl := Ui.label(stamp, tag, 0, 0, 22, 22, 11, tag_color, Ui.F_PIXEL,
		HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stamp)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := Ui.label(info, str(opt.get("label", "")), 0, 0, 0, 15, 11, Color("#2b2418"), Ui.F_UI_BOLD,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	lab.custom_minimum_size.y = 15
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview := effect_preview(opt)
	var short := "效果：%s" % preview if affordable else "余额不足 · %s" % preview
	var pl := Ui.label(info, short, 0, 0, 0, 12, 8.5,
		Color("#6d5a3c") if affordable else Color("#9b3127"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	pl.custom_minimum_size.y = 12
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(info)
	row.add_child(h)
	if affordable:
		var oi := index
		row.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					cb.call("visitor:%d" % oi)
					row.accept_event()
		)
		row.mouse_entered.connect(func():
			if is_instance_valid(row):
				sb.bg_color = Color(0, 0, 0, 0.065)
				row.add_theme_stylebox_override("panel", sb)
		)
		row.mouse_exited.connect(func():
			if is_instance_valid(row):
				sb.bg_color = Color(0, 0, 0, 0.018)
				row.add_theme_stylebox_override("panel", sb)
		)
	else:
		row.modulate = Color(1, 1, 1, 0.48)
	parent.add_child(row)


static func _visitor_footer(parent: Node, state: Dictionary) -> void:
	var line := ColorRect.new()
	line.color = Color(85 / 255.0, 70 / 255.0, 45 / 255.0, 0.30)
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Ui.label(foot, "经办：03 窗口 周明远", 0, 0, 0, 12, 7, Color("#7a6847"), Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r := Ui.label(foot, "归档：来访登记 · %s" % str(state.get("date", "")), 0, 0, 0, 12, 7,
		Color("#7a6847"), Ui.F_MONO, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_CENTER, false)
	parent.add_child(foot)


static func visitor(v: Dictionary, role: Dictionary, display_name: String, state: Dictionary,
		day_idx: int, index: int, total: int, items: Array, selected_item: String,
		compact: bool, cb: Callable) -> Control:
	var parts := _skin_card(700, "form", "03 窗口 · 来访登记", "NO. 03-V%02d" % index, 26, 26, 29, 20)
	var card: PanelContainer = parts[0]
	var root: VBoxContainer = parts[1]
	root.add_theme_constant_override("separation", 0)
	var box: VBoxContainer = root
	if compact:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(634, 470)
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		root.add_child(scroll)
		box = VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 0)
		scroll.add_child(box)
	box.add_child(_visitor_header(v, role, display_name, state, index, total, "待 批", Color(154 / 255.0, 50 / 255.0, 40 / 255.0, 0.85), compact))
	_spacer(box, 6)
	box.add_child(_visitor_fields(v, role, display_name, state))
	if !compact:
		_spacer(box, 8)
		_section_title(box, "来访人陈述")
		_spacer(box, 3)
		box.add_child(_visitor_story(v, 634))
	_spacer(box, 6)
	var ask := _info_box(box, 634, RED, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.07))
	var ask_v: VBoxContainer = ask[1]
	Ui.label(ask_v, "来 意", 0, 0, 0, 14, 8, Color("#8b382b"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	_body(ask_v, str(v.get("ask", "")), 11.5, Color("#3f3524"), 602, 20.4, Ui.F_DOC)
	_spacer(box, 7)
	_section_title(box, "随附文件（可选）")
	_spacer(box, 2)
	_visitor_items(box, items, selected_item, cb)
	_spacer(box, 6)
	_section_title(box, "拟办意见")
	_spacer(box, 2)
	var options: Array = v.get("options", [])
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var affordable := int(state.get("energy", 0)) + int(opt.get("energy", 0)) >= 0 \
			and int(state.get("money", 0)) + int(opt.get("money", 0)) >= 0
		_visitor_option_row(box, opt, i, affordable, cb)
	if !compact:
		_spacer(box, 3)
		Ui.label(box, "批 / 驳 / 缓没有标准答案：不同的人会记住不同的选择。", 0, 0, 0, 14, 7.5,
			Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	_spacer(box, 4)
	_visitor_footer(box, state)
	return card


static func visitor_result(v: Dictionary, role: Dictionary, display_name: String, opt: Dictionary,
		state: Dictionary, day_idx: int, index: int, total: int, is_last: bool,
		compact: bool, cb: Callable) -> Control:
	var tag := str(opt.get("tag", "批"))
	var tag_color := Color("#3f6b45") if tag == "批" else (Color("#9b3127") if tag == "驳" else Color("#a56a22"))
	var word := "已 批" if tag == "批" else ("已 驳" if tag == "驳" else "已 缓")
	var parts := _skin_card(700, "form", "03 窗口 · 来访回执", "NO. 03-V%02d" % index, 26, 26, 29, 20)
	var card: PanelContainer = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(_visitor_header(v, role, display_name, state, index, total, word, tag_color, compact))
	_spacer(box, 6)
	box.add_child(_visitor_fields(v, role, display_name, state))
	_spacer(box, 8)
	_section_title(box, "办理结果", tag_color)
	_spacer(box, 3)
	_body(box, str(opt.get("result", "")), 12, Color("#3f3524"), 634, 22.5, Ui.F_DOC)
	_spacer(box, 6)
	var chosen := _info_box(box, 634, tag_color, Color(tag_color.r, tag_color.g, tag_color.b, 0.07))
	var cv: VBoxContainer = chosen[1]
	Ui.label(cv, "拟办：%s · %s" % [tag, str(opt.get("label", ""))], 0, 0, 0, 15, 9, tag_color,
		Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	_body(cv, effect_preview(opt, true), 9.5, Color("#3f3524"), 602, 17.0, Ui.F_UI)
	var submitted: Dictionary = opt.get("submitted", {})
	if !submitted.is_empty():
		var use := "已归档" if bool(submitted.get("consumable", false)) else "已阅"
		Ui.label(box, "随附：《%s》 · %s · 对方人情 +%d" % [str(submitted.get("title", "文件")), use, int(submitted.get("submit_favor", 1))],
			0, 0, 0, 14, 7.5, Color("#6d5a3c"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		_spacer(box, 3)
	Ui.label(box, "已记入人情簿 · 本单归入来访登记", 0, 0, 0, 12, 7.5, tag_color, Ui.F_UI,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	_spacer(box, 4)
	_visitor_footer(box, state)
	_spacer(box, 8)
	var acts := _actions(box)
	_button(acts, "去排班" if is_last else "下一位", "visitor-next", cb, true, 190, 42)
	return card


static func effect_preview(effects: Dictionary, with_reason: bool = false) -> String:
	var parts: Array = []
	var fav: Dictionary = effects.get("favor", {})
	for key in fav:
		var delta := int(fav[key])
		if delta == 0:
			continue
		var role := AllocationModel.role(str(key))
		var who := str(role.get("name", key))
		parts.append("%s %s%d" % [who, "+" if delta > 0 else "−", absi(delta)])
	var perf := int(effects.get("perf", 0))
	if perf != 0:
		parts.append("绩效 %s¥%s" % ["+" if perf > 0 else "−", Ui.fmt_money(absi(perf))])
	var energy := int(effects.get("energy", 0))
	if energy != 0:
		parts.append("精力 %s%d" % ["+" if energy > 0 else "−", absi(energy)])
	var money := int(effects.get("money", 0))
	if money != 0:
		parts.append("金钱 %s%d" % ["+" if money > 0 else "−", absi(money)])
	var rep := int(effects.get("rep", 0))
	if rep != 0:
		parts.append("声誉 %s%d" % ["+" if rep > 0 else "−", absi(rep)])
	if parts.is_empty():
		return "没有直接变化"
	return " · ".join(PackedStringArray(parts))


static func favor_ledger(roles: Array, favor: Dictionary, log: Array, cb: Callable) -> Control:
	var parts := _skin_card(700, "ledger", "03 窗口 · 人情簿", "BOOK. 03-F", 26, 26, 29, 20)
	var card: PanelContainer = parts[0]
	var box: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(left)
	_kicker(left, "人情簿 / FAVORS")
	_h2(left, "这一周，谁记着你", 34)
	Ui.label(left, "分配硬币、处理待办、盖章与夜班批示都会改变不同人的印象。", 0, 0, 0, 18, 9,
		Color("#6a583a"), Ui.F_DOC, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var total := 0
	for role in roles:
		total += int(favor.get(str(role.get("id", "")), 0))
	head.add_child(_stamp_box(["人 情", str(total), "总 计"], 86, 86, 5.0, Color(154 / 255.0, 50 / 255.0, 40 / 255.0, 0.84), [7, 26, 7]))
	_spacer(box, 8)
	var line := ColorRect.new()
	line.color = Color("#55462d")
	line.custom_minimum_size.y = 2
	box.add_child(line)
	_spacer(box, 6)
	for role in roles:
		var rid := str(role.get("id", ""))
		var value := int(favor.get(rid, 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		row.custom_minimum_size.y = 46
		var seal := PixelPanel.new()
		seal.bg_color = Color("#a83a2f")
		seal.border_width = 1
		seal.border_color = Color("#5b1f19")
		seal.inner_highlight = Color("#e9a28f")
		seal.custom_minimum_size = Vector2(30, 30)
		seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(seal)
		var sv := VBoxContainer.new()
		sv.alignment = BoxContainer.ALIGNMENT_CENTER
		sv.add_theme_constant_override("separation", 0)
		seal.add_child(sv)
		Ui.label(sv, str(role.get("seal", "")), 0, 0, 0, 30, 16, Color("#f6e7c8"), Ui.F_PIXEL,
			HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
		sv.custom_minimum_size = Vector2(30, 30)
		var who := VBoxContainer.new()
		who.add_theme_constant_override("separation", 0)
		who.custom_minimum_size.x = 170
		row.add_child(who)
		Ui.label(who, str(role.get("name", "")), 0, 0, 0, 17, 12, Color("#2b2418"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		Ui.label(who, "%s · %s" % [str(role.get("role", "")), str(role.get("office", ""))], 0, 0, 0, 14, 8,
			Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		var meter := VBoxContainer.new()
		meter.add_theme_constant_override("separation", 1)
		meter.custom_minimum_size.x = 160
		row.add_child(meter)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 5)
		meter.add_child(top)
		Ui.label(top, "%d / 10" % value, 0, 0, 0, 16, 12, Color("#8b382b"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		Ui.label(top, AllocationModel.favor_label(value), 0, 0, 0, 16, 9, Color("#6a583a"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 2)
		meter.add_child(pips)
		for i in range(10):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(11, 5)
			pip.color = Color("#a83a2f") if i < value else Color(60 / 255.0, 48 / 255.0, 30 / 255.0, 0.22)
			pips.add_child(pip)
		var perk_box := VBoxContainer.new()
		perk_box.add_theme_constant_override("separation", 0)
		perk_box.custom_minimum_size.x = 250
		perk_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(perk_box)
		var perk: Dictionary = role.get("perk", {})
		var at := int(perk.get("at", 999))
		var active := value >= at
		Ui.label(perk_box, "✓ 已达成" if active else "未解锁 · 还需 %d 点" % at,
			0, 0, 0, 14, 8, Color("#3f6b45") if active else Color("#9b3127"), Ui.F_PIXEL,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		Ui.label(perk_box, str(perk.get("text", "")), 0, 0, 0, 14, 8,
			Color("#4a3e2c") if active else Color("#8a7752"), Ui.F_UI,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
		box.add_child(row)
	var recent: Array = []
	for i in range(log.size() - 1, -1, -1):
		if recent.size() >= 5:
			break
		recent.append(log[i])
	if !recent.is_empty():
		_spacer(box, 4)
		var lp := PanelContainer.new()
		var ls := StyleBoxFlat.new()
		ls.bg_color = Color(47 / 255.0, 58 / 255.0, 47 / 255.0, 0.07)
		ls.border_width_left = 3
		ls.border_color = Color("#4f6a4c")
		ls.content_margin_left = 9
		ls.content_margin_right = 9
		ls.content_margin_top = 5
		ls.content_margin_bottom = 5
		lp.add_theme_stylebox_override("panel", ls)
		var lv := VBoxContainer.new()
		lv.add_theme_constant_override("separation", 2)
		lp.add_child(lv)
		Ui.label(lv, "最近的人情", 0, 0, 0, 13, 8, Color("#6d5a3c"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		for entry in recent:
			var role := AllocationModel.role(str(entry.get("id", "")))
			var delta := int(entry.get("delta", 0))
			var text := "第%d天 · %s %s%d · %s" % [int(entry.get("day", 0)) + 1, str(role.get("name", "")),
				"+" if delta > 0 else "−", absi(delta), str(entry.get("reason", ""))]
			Ui.label(lv, text, 0, 0, 0, 13, 8, Color("#8b382b") if delta < 0 else Color("#3f4f45"),
				Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		box.add_child(lp)
	_spacer(box, 8)
	var acts := _actions(box)
	_button(acts, "学院关系", "college-open", cb, false, 150, 40)
	_button(acts, "合上簿子", "favor-close", cb, false, 170, 40)
	return card


# ------------------------------------------------------------
# college relations (v1.15)
# ------------------------------------------------------------
static func college_ledger(groups: Array, favor: Dictionary, log: Array, cb: Callable) -> Control:
	var parts := _skin_card(760, "ledger", "03 窗口 · 院系账本", "BOOK. 03-C", 27, 27, 30, 20)
	var card: PanelContainer = parts[0]
	var box: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	box.add_child(head)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(left)
	_kicker(left, "学院关系 / COLLEGE RELATIONS")
	_h2(left, "院系账本", 34)
	Ui.label(left, "学生每通过一位，所在学院的导师与主任各记 1 点人情；规范通过满 2 位，学院回礼并寄来感谢函。",
		0, 0, 0, 18, 9, Color("#6a583a"), Ui.F_DOC, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	var total_passes := 0
	for group in groups:
		var e := CollegeModel.entry(favor, str(group.get("id", "")))
		total_passes += int(e.get("passes", 0))
	head.add_child(_stamp_box(["学 院", str(total_passes), "规 范 通 过"], 96, 88, 5.0,
		Color(79 / 255.0, 118 / 255.0, 82 / 255.0, 0.85), [7, 26, 7]))
	_spacer(box, 7)
	var line := ColorRect.new()
	line.color = Color("#55462d")
	line.custom_minimum_size.y = 2
	box.add_child(line)
	_spacer(box, 5)
	for group in groups:
		var gid := str(group.get("id", ""))
		var e := CollegeModel.entry(favor, gid)
		var advisor := CollegeModel.advisor_name(group)
		var director := CollegeModel.director_name(group)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		row.custom_minimum_size.y = 62
		var seal := PixelPanel.new()
		seal.bg_color = Color("#a83a2f")
		seal.border_width = 1
		seal.border_color = Color("#5b1f19")
		seal.inner_highlight = Color("#e9a28f")
		seal.custom_minimum_size = Vector2(34, 34)
		seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(seal)
		var sv := VBoxContainer.new()
		sv.alignment = BoxContainer.ALIGNMENT_CENTER
		sv.add_theme_constant_override("separation", 0)
		seal.add_child(sv)
		Ui.label(sv, str(group.get("seal", "")), 0, 0, 0, 34, 11, Color("#f6e7c8"), Ui.F_PIXEL,
			HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
		sv.custom_minimum_size = Vector2(34, 34)
		var who := VBoxContainer.new()
		who.add_theme_constant_override("separation", 1)
		who.custom_minimum_size.x = 220
		row.add_child(who)
		Ui.label(who, str(group.get("label", "")), 0, 0, 0, 16, 12, Color("#2b2418"), Ui.F_UI_BOLD,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		var colleges: Array = group.get("colleges", [])
		var names: Array = []
		for ci in range(mini(3, colleges.size())):
			names.append(str(colleges[ci]))
		var college_text := "、".join(PackedStringArray(names))
		if colleges.size() > 3:
			college_text += " 等 %d 个学院" % colleges.size()
		Ui.label(who, college_text, 0, 0, 0, 13, 7.5,
			Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		Ui.label(who, str(group.get("story", "")), 0, 0, 0, 26, 8, Color("#5a4a33"), Ui.F_DOC,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
		var people := VBoxContainer.new()
		people.add_theme_constant_override("separation", 1)
		people.custom_minimum_size.x = 220
		row.add_child(people)
		_college_person_line(people, "导师", advisor, CollegeModel.advisor_title(group), int(e.get("advisor", 0)))
		_college_person_line(people, "主任", director, CollegeModel.director_title(group), int(e.get("director", 0)))
		var right := VBoxContainer.new()
		right.add_theme_constant_override("separation", 1)
		right.custom_minimum_size.x = 190
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(right)
		var pass_count := int(e.get("passes", 0))
		var pass_text := "规范通过 %d" % pass_count
		if pass_count < CollegeModel.milestone_at():
			pass_text += " / %d" % CollegeModel.milestone_at()
		else:
			pass_text += " · 已满 %d" % CollegeModel.milestone_at()
		Ui.label(right, pass_text,
			0, 0, 0, 15, 9, Color("#3f6b45"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		Ui.label(right, CollegeModel.next_reward_text(group, e), 0, 0, 0, 15, 8,
			Color("#8b382b") if !bool(e.get("milestone", false)) else Color("#6a583a"), Ui.F_UI,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
		Ui.label(right, "上次：%s" % str(e.get("lastStudent", "—")), 0, 0, 0, 13, 7.5,
			Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		box.add_child(row)
		var sep := ColorRect.new()
		sep.color = Color(85 / 255.0, 70 / 255.0, 45 / 255.0, 0.22)
		sep.custom_minimum_size.y = 1
		box.add_child(sep)
	var recent: Array = []
	for i in range(log.size() - 1, -1, -1):
		if recent.size() >= 4:
			break
		recent.append(log[i])
	if !recent.is_empty():
		_spacer(box, 4)
		var lp := PanelContainer.new()
		var ls := StyleBoxFlat.new()
		ls.bg_color = Color(47 / 255.0, 58 / 255.0, 47 / 255.0, 0.07)
		ls.border_width_left = 3
		ls.border_color = Color("#4f6a4c")
		ls.content_margin_left = 9
		ls.content_margin_right = 9
		ls.content_margin_top = 4
		ls.content_margin_bottom = 4
		lp.add_theme_stylebox_override("panel", ls)
		var lv := VBoxContainer.new()
		lv.add_theme_constant_override("separation", 1)
		lp.add_child(lv)
		Ui.label(lv, "最近的学院往来", 0, 0, 0, 12, 8, Color("#6d5a3c"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		for entry in recent:
			var group := CollegeModel.group(str(entry.get("group", "")))
			var bits: Array = []
			if int(entry.get("advisor", 0)) != 0:
				bits.append("%s +%d" % [CollegeModel.advisor_name(group), int(entry.get("advisor", 0))])
			if int(entry.get("director", 0)) != 0:
				bits.append("%s +%d" % [CollegeModel.director_name(group), int(entry.get("director", 0))])
			if int(entry.get("perf", 0)) != 0:
				bits.append("+¥%s" % Ui.fmt_money(int(entry.get("perf", 0))))
			if bool(entry.get("milestone", false)):
				bits.append("感谢函")
			if !bool(entry.get("pass", false)):
				bits.append("误判放行")
			var text := "第%d天 · %s %s · %s" % [int(entry.get("day", 0)) + 1,
				str(entry.get("college", "")), str(entry.get("student", "")), " · ".join(PackedStringArray(bits))]
			Ui.label(lv, text, 0, 0, 0, 12, 8, Color("#3f4f45"), Ui.F_UI,
				HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
		box.add_child(lp)
	_spacer(box, 8)
	var acts := _actions(box)
	_button(acts, "合上", "college-close", cb, false, 170, 40)
	return card


static func _college_person_line(parent: Node, kind: String, name: String, title: String, value: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var label := Ui.label(row, "%s %s %s" % [kind, name, title], 0, 0, 0, 16, 9,
		Color("#3c3120"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	label.custom_minimum_size.x = 100
	Ui.label(row, str(value), 0, 0, 0, 16, 11, Color("#8b382b"), Ui.F_UI_BOLD,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	Ui.label(row, CollegeModel.favor_label(value), 0, 0, 0, 16, 8, Color("#6a583a"), Ui.F_PIXEL,
		HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 1)
	row.add_child(pips)
	for i in range(10):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(4, 5)
		pip.color = Color("#a83a2f") if i < value else Color(60 / 255.0, 48 / 255.0, 30 / 255.0, 0.20)
		pips.add_child(pip)
	parent.add_child(row)


# ------------------------------------------------------------
# ending
# ------------------------------------------------------------
static func ending(st: Dictionary, rank: Dictionary, cb: Callable) -> Control:
	var parts := _skin_card(760, "dossier", "03 窗口 · 聘期审查", "FINAL. 03", 27, 30, 27, 22)
	var card: PanelContainer = parts[0]
	var v: VBoxContainer = parts[1]
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 15)
	v.add_child(hero)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(left)
	_kicker(left, "聘期审查结果")
	_h2(left, str(rank.get("rank", "")), 46)
	Ui.label(left, str(rank.get("sub", "")), 0, 0, 0, 20, 12, Color("#6a583a"), Ui.F_DOC, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	hero.add_child(_stamp_box(["教务处", str(rank.get("stamp", "")), "2026"], 102, 102, 6.0, Color(150 / 255.0, 50 / 255.0, 40 / 255.0, 0.86), [7, 28, 7]))
	var line := ColorRect.new()
	line.color = Color("#55462d")
	line.custom_minimum_size.y = 2
	v.add_child(line)
	_spacer(v, 8)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 7)
	v.add_child(cards)
	_ending_stat(cards, "总绩效", "¥" + Ui.fmt_money(int(st.get("perf", 0))), Color("#332a1c"))
	_ending_stat(cards, "正确审查", str(int(st.get("total_correct", 0))), Color("#332a1c"))
	_ending_stat(cards, "误判", str(int(st.get("total_wrong", 0))), RED if int(st.get("total_wrong", 0)) > 0 else Color("#332a1c"))
	_ending_stat(cards, "零差错日", str(int(st.get("perfect_days", 0))), Color("#332a1c"))
	var ann_hits := int(st.get("annotation_hits", 0))
	var ann_total := ann_hits + int(st.get("annotation_wrong", 0)) + int(st.get("annotation_missed", 0))
	_ending_stat(cards, "圈注命中", "%d / %d" % [ann_hits, ann_total], Color("#3f4f45"))
	_spacer(v, 10)
	var week := str(st.get("week_line", ""))
	if week != "":
		var wp := PanelContainer.new()
		wp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ws := StyleBoxFlat.new()
		ws.bg_color = Color(63 / 255.0, 107 / 255.0, 69 / 255.0, 0.07)
		ws.border_width_left = 3
		ws.border_color = Color("#3f6b45")
		ws.content_margin_left = 9
		ws.content_margin_right = 9
		ws.content_margin_top = 5
		ws.content_margin_bottom = 5
		wp.add_theme_stylebox_override("panel", ws)
		var wv := VBoxContainer.new()
		wv.add_theme_constant_override("separation", 1)
		wp.add_child(wv)
		Ui.label(wv, "七天人账 / WEEK LEDGER", 0, 0, 0, 12, 8, Color("#3f6b45"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		_body(wv, week, 9.5, Color("#3f3524"), 676, 17.0, Ui.F_UI)
		v.add_child(wp)
		_spacer(v, 6)
	for para in rank.get("story", []):
		_body(v, str(para), 11.5, Color("#4a3e2c"), 700, 21.9, Ui.F_DOC)
	var note := str(st.get("ending_note", ""))
	if note != "":
		_spacer(v, 3)
		_body(v, note, 10.5, Color("#5a4a33"), 700, 19.0, Ui.F_DOC)
	_spacer(v, 4)
	var night: Array = st.get("night_log", [])
	if night.size() > 0:
		var np := PanelContainer.new()
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(47 / 255.0, 58 / 255.0, 47 / 255.0, 0.08)
		ns.border_width_left = 3
		ns.border_color = Color("#4f6a4c")
		ns.content_margin_left = 9
		ns.content_margin_right = 9
		ns.content_margin_top = 6
		ns.content_margin_bottom = 6
		np.add_theme_stylebox_override("panel", ns)
		var nv := VBoxContainer.new()
		nv.add_theme_constant_override("separation", 1)
		np.add_child(nv)
		Ui.label(nv, "夜班记录", 0, 0, 0, 13, 8, Color("#6d5a3c"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		for entry in night:
			var tone := str(entry.get("tone", ""))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			Ui.label(row, "第%d夜" % int(entry.get("day", 0)), 0, 0, 0, 12, 9, Color("#7a6847"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
			Ui.label(row, "· " + str(entry.get("label", "")), 0, 0, 0, 12, 10, Color("#8b382b") if tone == "warn" else Color("#3f4f45"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
			nv.add_child(row)
		v.add_child(np)
		_spacer(v, 6)
	var favor_line := str(st.get("favor_line", ""))
	if favor_line != "":
		var fp := PanelContainer.new()
		fp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fs := StyleBoxFlat.new()
		fs.bg_color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.055)
		fs.border_width_left = 3
		fs.border_color = Color("#8b382b")
		fs.content_margin_left = 9
		fs.content_margin_right = 9
		fs.content_margin_top = 5
		fs.content_margin_bottom = 5
		fp.add_theme_stylebox_override("panel", fs)
		var fv := VBoxContainer.new()
		fv.add_theme_constant_override("separation", 1)
		fp.add_child(fv)
		Ui.label(fv, "人情簿 / FAVORS", 0, 0, 0, 12, 8, Color("#8b382b"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		_body(fv, favor_line, 10.5, Color("#3f3524"), 676, 18.5, Ui.F_UI)
		var note2 := str(st.get("favor_note", ""))
		if note2 != "":
			_body(fv, note2, 9.5, Color("#6a583a"), 676, 17.0, Ui.F_DOC)
		v.add_child(fp)
		_spacer(v, 6)
	var college_line := str(st.get("college_line", ""))
	if college_line != "":
		var cp := PanelContainer.new()
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(79 / 255.0, 118 / 255.0, 82 / 255.0, 0.07)
		cs.border_width_left = 3
		cs.border_color = Color("#4f6a4c")
		cs.content_margin_left = 9
		cs.content_margin_right = 9
		cs.content_margin_top = 5
		cs.content_margin_bottom = 5
		cp.add_theme_stylebox_override("panel", cs)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 1)
		cp.add_child(cv)
		Ui.label(cv, "学院关系 / COLLEGE RELATIONS", 0, 0, 0, 12, 8, Color("#3f6b45"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		_body(cv, college_line, 10.5, Color("#3f3524"), 676, 18.5, Ui.F_UI)
		var cnote := str(st.get("college_note", ""))
		if cnote != "":
			_body(cv, cnote, 9.5, Color("#6a583a"), 676, 17.0, Ui.F_DOC)
		v.add_child(cp)
		_spacer(v, 6)
	var handled: Dictionary = st.get("stamp_counts", {})
	_body(v, "共处理 [b]%d[/b] 份：通过 %d、修改 %d、不通过 %d；误判 %d 次。" % [
		int(st.get("total_correct", 0)) + int(st.get("total_wrong", 0)),
		int(handled.get("pass", 0)), int(handled.get("revise", 0)), int(handled.get("reject", 0)),
		int(st.get("total_wrong", 0))], 11.5, Color("#4a3f2d"), 700, 22.2, Ui.F_DOC)
	_spacer(v, 8)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	v.add_child(foot)
	var gap := Control.new()
	gap.custom_minimum_size.x = 360
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(gap)
	_button(foot, "再来一次", "restart", cb, true, 170, 44)
	var line2 := ColorRect.new()
	line2.color = Color("#9b875e")
	line2.custom_minimum_size.y = 1
	v.add_child(line2)
	_spacer(v, 6)
	return card

static func _ending_stat(parent: Node, k: String, value: String, color: Color) -> void:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.19)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#8d7852")
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var l := Ui.label(v, k, 0, 0, 0, 10, 7, Color("#7a6847"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Ui.label(v, value, 0, 0, 0, 22, 18, color, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
