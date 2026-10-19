class_name Docs
extends RefCounted

## Native rebuilds of the ten paper documents in the original HTML game.

const INK := Color("#241f17")
const SOFT := Color("#4b4233")
const PAPER := Color("#e7dcbc")
const PAPER_HI := Color("#f4e9c9")
const RED := Color("#a83a2f")
const BLUE := Color("#2d4d78")

static func render(tab_id: String, s: Dictionary, width: float = 696.0) -> Control:
	match tab_id:
		"cover": return _cover(s, width)
		"abstract": return _abstract(s, width)
		"body": return _body(s, width)
		"refs": return _refs(s, width)
		"dup": return _dup(s, width)
		"form": return _form(s, width)
		"opening": return _extra(s, width, "opening")
		"advisor": return _extra(s, width, "advisor")
		"ethics": return _extra(s, width, "ethics")
		"records": return _extra(s, width, "records")
	return _cover(s, width)

# ------------------------------------------------------------
# primitives
# ------------------------------------------------------------
static func _vbox(width: float, sep: int = 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.custom_minimum_size.x = width
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

static func _hbox(sep: int = 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h

static func _lab(parent: Node, text: String, size: int, color: Color = INK, bold: bool = false,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Ui.label(parent, text, 0, 0, 0, 10, size, color, Ui.F_DOC_BOLD if bold else Ui.F_DOC, align, VERTICAL_ALIGNMENT_TOP, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func _pix(parent: Node, text: String, size: int, color: Color = SOFT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Ui.label(parent, text, 0, 0, 0, 8, size, color, Ui.F_PIXEL, align, VERTICAL_ALIGNMENT_TOP, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func _line(parent: Node, color: Color, thickness: float = 1.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size.y = thickness
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(r)
	return r

static func _space(parent: Node, h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c

static func _para(parent: Node, text: String, width: float, size: float, color: Color,
		line_px: float, indent: bool = true, bold_prefix: bool = false) -> RichTextLabel:
	var body := ("　　" + text) if indent else text
	var fsize := int(size)
	var tw: float = Ui.F_DOC.get_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var lines: int = max(1, int(ceil(tw / max(1.0, width))))
	var h: float = lines * line_px + 2.0
	var r := Ui.rich(parent, body, 0, 0, width, h, fsize, color, Ui.F_DOC, line_px)
	r.custom_minimum_size = Vector2(width, h)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

static func _title_row(title: String, badges: Array, width: float, anchors: Array = []) -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 5)
	wrap.custom_minimum_size.x = width
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := _hbox(8)
	h.custom_minimum_size.y = 20
	var t := _pix(h, title, 14, Color("#30281a"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(spacer)
	for i in range(badges.size()):
		var b: Array = badges[i]
		var badge := _badge(str(b[0]), str(b[1]))
		if i < anchors.size() and str(anchors[i]) != "":
			badge.set_meta("anchor", str(anchors[i]))
		h.add_child(badge)
	wrap.add_child(h)
	_line(wrap, Color(49 / 255.0, 41 / 255.0, 27 / 255.0, 0.48), 2)
	return wrap

static func _badge(label_text: String, value: String) -> Control:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.24)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#756342")
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	var h := _hbox(3)
	var l := _pix(h, label_text, 8, Color("#5d4d31"))
	var v := _pix(h, value, 11, Color("#3b2f1d"))
	p.add_child(h)
	return p

static func _seal(lines: Array, w: float = 82.0, h: float = 52.0, missing: bool = false,
		color: Color = Color(149 / 255.0, 48 / 255.0, 38 / 255.0, 0.82)) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer := PixelPanel.new()
	outer.bg_color = Color(0, 0, 0, 0)
	outer.border_width = 3 if !missing else 2
	outer.dashed = missing
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
		var item: Variant = lines[i]
		var text := ""
		var fs := 9 if i == 0 else 7
		if item is Array:
			text = str(item[0])
			if item.size() > 1:
				fs = int(item[1])
		else:
			text = str(item)
		var l := _pix(v, text, fs, color, HORIZONTAL_ALIGNMENT_CENTER)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.y = 12 if i == 0 else 9
	c.rotation = deg_to_rad(-6)
	c.pivot_offset = Vector2(w * 0.5, h * 0.5)
	return c

static func _field_row(parent: Node, k: String, v: String, width: float, size: float = 9.5,
		dotted: bool = true) -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.custom_minimum_size.x = width
	var h := _hbox(6)
	var kl := _lab(h, k, 9, Color("#786440"))
	kl.custom_minimum_size.x = 52
	kl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var vl := _lab(h, v, int(size), Color("#3e3423"), true)
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(h)
	_line(wrap, Color(97 / 255.0, 78 / 255.0, 47 / 255.0, 0.28) if dotted else Color(154 / 255.0, 134 / 255.0, 95 / 255.0, 0.5), 1)
	parent.add_child(wrap)
	return wrap

static func _hand(text: String, size: int = 14) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.add_theme_font_override("font", Ui.F_HAND)
	Ui.set_font(l, size)
	l.add_theme_color_override("font_color", BLUE)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.rotation = deg_to_rad(-4)
	l.pivot_offset = Vector2(0, 8)
	return l

# ------------------------------------------------------------
# cover
# ------------------------------------------------------------
static func _cover(s: Dictionary, width: float) -> Control:
	var c: Dictionary = s.get("cover", {})
	var o: Dictionary = s.get("official", {})
	var v := _vbox(width, 0)
	var school := _lab(v, "明 州 大 学", 13, Color("#4b3e27"), false, HORIZONTAL_ALIGNMENT_CENTER)
	school.custom_minimum_size.y = 19
	var kind_wrap := CenterContainer.new()
	kind_wrap.custom_minimum_size = Vector2(width, 28)
	kind_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kind := PanelContainer.new()
	kind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0, 0, 0, 0)
	ks.border_width_top = 1
	ks.border_width_bottom = 1
	ks.border_color = Color("#7c6846")
	ks.content_margin_left = 13
	ks.content_margin_right = 13
	ks.content_margin_top = 2
	ks.content_margin_bottom = 3
	kind.add_theme_stylebox_override("panel", ks)
	_lab(kind, "本科毕业论文（设计）", 15, Color("#2f2718"), true, HORIZONTAL_ALIGNMENT_CENTER)
	kind_wrap.add_child(kind)
	v.add_child(kind_wrap)
	_space(v, 8)
	var title := _lab(v, str(c.get("title", s.get("title", ""))), 19, Color("#211c12"), true, HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 30
	title.set_meta("anchor", "identity.title")
	var sub := _pix(v, "UNDERGRADUATE THESIS", 7, Color("#7c6a48"), HORIZONTAL_ALIGNMENT_CENTER)
	sub.custom_minimum_size.y = 10
	_space(v, 9)
	var fields := _vbox(390, 0)
	fields.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cover_field(fields, "学　院", str(c.get("college", "")), 390)
	_cover_field(fields, "专　业", str(c.get("major", "")), 390, "identity.major")
	var row := _hbox(16)
	row.add_child(_cover_field_no_parent("姓　名", str(c.get("name", "")), 187, "identity.name"))
	row.add_child(_cover_field_no_parent("学　号", str(c.get("id", "")), 187, "identity.id"))
	fields.add_child(row)
	_cover_field(fields, "指导教师", "%s　%s" % [str(o.get("advisor", "——")), str(o.get("advisorTitle", ""))], 390)
	v.add_child(fields)
	_space(v, 6)
	var date := _lab(v, "二〇二六年五月", 10, Color("#5e4c31"), false, HORIZONTAL_ALIGNMENT_CENTER)
	date.custom_minimum_size.y = 15
	return v

static func _cover_field(parent: Node, k: String, value: String, width: float, anchor: String = "") -> void:
	parent.add_child(_cover_field_no_parent(k, value, width, anchor))

static func _cover_field_no_parent(k: String, value: String, width: float, anchor: String = "") -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.custom_minimum_size.x = width
	if anchor != "":
		wrap.set_meta("anchor", anchor)
	var h := _hbox(6)
	var kl := _lab(h, k, 10, Color("#6f5b3b"))
	kl.custom_minimum_size.x = 44
	kl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var vl := _lab(h, value, 11, Color("#2d2619"), true)
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(h)
	_line(wrap, Color("#9b875e"), 1)
	return wrap

# ------------------------------------------------------------
# abstract
# ------------------------------------------------------------
static func _abstract(s: Dictionary, width: float) -> Control:
	var chars := int(s.get("abstractChars", 0))
	var kws: Array = s.get("keywords", [])
	var v := _vbox(width, 0)
	v.add_child(_title_row("摘要", [["字数", str(chars)], ["关键词", str(kws.size())]], width, ["summary.chars", "summary.keywords"]))
	_space(v, 6)
	var title := _lab(v, str(s.get("abstractTitle", s.get("title", ""))), 12, Color("#2e271a"), true)
	title.custom_minimum_size.y = 18
	title.set_meta("anchor", "identity.title")
	_para(v, str(s.get("excerpt", "")), width, 10.8, Color("#3a3224"), 19.6, true)
	_space(v, 7)
	var meta_wrap := VBoxContainer.new()
	meta_wrap.add_theme_constant_override("separation", 5)
	_line(meta_wrap, Color(155 / 255.0, 135 / 255.0, 95 / 255.0, 0.65), 1)
	var mh := _hbox(12)
	_lab(mh, "摘　要：%d 字" % chars, 9, Color("#5d4d34"))
	_lab(mh, "关键词：%d 个" % kws.size(), 9, Color("#5d4d34"))
	meta_wrap.add_child(mh)
	v.add_child(meta_wrap)
	_space(v, 4)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for word in kws:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.26)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color("#866f49")
		sb.content_margin_left = 5
		sb.content_margin_right = 5
		sb.content_margin_top = 1
		sb.content_margin_bottom = 1
		chip.add_theme_stylebox_override("panel", sb)
		_lab(chip, str(word), 9, Color("#433722"))
		flow.add_child(chip)
	v.add_child(flow)
	_space(v, 7)
	var note := _pix(v, "摘录页 · 字数以教务处检测系统统计为准", 7, Color("#8b7957"), HORIZONTAL_ALIGNMENT_RIGHT)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v

# ------------------------------------------------------------
# body
# ------------------------------------------------------------
static func _body(s: Dictionary, width: float) -> Control:
	var body: Dictionary = s.get("body", {})
	var pages_total := int(body.get("pages", 0))
	var gap: Variant = body.get("gap", null)
	var pages: Array = []
	for p in range(1, pages_total + 1):
		if gap != null and int(gap) == p:
			continue
		pages.append(p)
	var v := _vbox(width, 0)
	v.add_child(_title_row("正文抽查", [
		["正文 ", "%d 页" % pages_total],
		["约 ", "%s 字" % Ui.fmt_money(int(body.get("wordCount", 0)))],
		["页脚 ", "%d 个" % pages.size()]
	], width, ["body.pages", "body.words", ""]))
	_space(v, 6)
	var heading := _lab(v, str(body.get("heading", "")), 14, Color("#2b2418"), true, HORIZONTAL_ALIGNMENT_CENTER)
	heading.custom_minimum_size.y = 20
	_para(v, str(body.get("excerpt", "")), width, 10.5, Color("#3e3525"), 18.9, true)
	_para(v, "在具体操作层面，本研究对样本的选取标准、资料编码过程与信效度检验进行了说明。为避免结论过度推广，所有访谈材料均经过匿名化处理，并对关键判断进行了交叉验证。", width, 10.5, Color("#3e3525"), 18.9, true)
	_space(v, 5)
	var check := PanelContainer.new()
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.custom_minimum_size = Vector2(width, 84)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.16)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#9b875e")
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	check.add_theme_stylebox_override("panel", sb)
	var cv := _vbox(width - 14, 4)
	var head := _hbox(8)
	var hl := _pix(head, "页码连续性抽查 · 按装订顺序", 8, Color("#6d5a3c"))
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hr := _pix(head, "扫描结果", 8, Color("#6d5a3c"), HORIZONTAL_ALIGNMENT_RIGHT)
	hr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 20
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	grid.custom_minimum_size.y = 39
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p in range(1, pages_total + 1):
		if gap != null and int(gap) == p:
			var hole := PixelPanel.new()
			hole.bg_color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.16)
			hole.border_width = 2
			hole.border_color = Color("#a83a2f")
			hole.custom_minimum_size = Vector2(30, 18)
			hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hole.set_meta("anchor", "body.gap")
			grid.add_child(hole)
			var gap_label := _pix(hole, "缺", 8, Color("#8b382b"), HORIZONTAL_ALIGNMENT_CENTER)
			gap_label.position = Vector2(0, 2)
			gap_label.size = Vector2(30, 14)
			continue
		var cell := PixelPanel.new()
		cell.bg_color = Color(1, 1, 1, 0.27)
		cell.border_width = 1
		cell.border_color = Color("#a18c64")
		cell.custom_minimum_size = Vector2(30, 18)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(cell)
		var l := _pix(cell, str(p), 8, Color("#5f4e33"), HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(0, 2)
		l.size = Vector2(30, 14)
	cv.add_child(grid)
	var nog := _pix(cv, "扫描 %d 个页脚 · 封面标注 %d 页" % [pages.size(), pages_total], 7, Color("#8b7957"), HORIZONTAL_ALIGNMENT_RIGHT)
	nog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check.add_child(cv)
	v.add_child(check)
	return v

# ------------------------------------------------------------
# references
# ------------------------------------------------------------
static func _refs(s: Dictionary, width: float) -> Control:
	var refs: Array = s.get("refs", [])
	var recent := 0
	for r in refs:
		var yy := int(r.get("y", 0))
		if yy >= 2021 and yy <= 2026:
			recent += 1
	var v := _vbox(width, 0)
	v.add_child(_title_row("参考文献", [["著录 ", "%d 篇" % refs.size()], ["近五年 ", "%d 篇" % recent]], width))
	_space(v, 5)
	_lab(v, "GB/T 7714—2015 著录格式；按年份倒序排列。网络来源以 [EB/OL] 标注。", 10, Color("#6b583a"))
	_space(v, 5)
	var list := _vbox(width, 0)
	for i in range(refs.size()):
		var r: Dictionary = refs[i]
		var row := _hbox(6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.set_meta("anchor", "refs.item.%d" % (i + 1))
		var num := _pix(row, "[%d]" % (i + 1), 9, Color("#7c6846"), HORIZONTAL_ALIGNMENT_RIGHT)
		num.custom_minimum_size.x = 25
		num.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var kind := str(r.get("kind", "journal"))
		var kind_label := "EB/OL" if kind == "web" else ("AI" if kind == "ai" else "J")
		var kind_color := "#8b382b" if kind == "web" else "#756341"
		var body_text := "%s. %s [color=%s][%s][/color]. [color=#6f5b3b]%s[/color], %d." % [
			r.get("a", ""), r.get("t", ""), kind_color, kind_label, r.get("j", ""), int(r.get("y", 0))]
		var body := Ui.rich(row, body_text, 0, 0, width - 31, 18, 10, Color("#3a3122"), Ui.F_DOC, 15.2)
		body.custom_minimum_size = Vector2(width - 31, 18)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(row)
		_line(list, Color(115 / 255.0, 94 / 255.0, 57 / 255.0, 0.20), 1)
	v.add_child(list)
	_space(v, 5)
	var flag := _pix(v, "著录总数 %d 篇 · 2021—2026 年 %d 篇" % [refs.size(), recent], 8, Color("#8a7754"))
	flag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v

# ------------------------------------------------------------
# plagiarism report
# ------------------------------------------------------------
static func _dup(s: Dictionary, width: float) -> Control:
	var d: Dictionary = s.get("dup", {})
	var rate := float(d.get("rate", 0.0))
	var outer := PanelContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.custom_minimum_size.x = width
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#e4dfcb")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#4b5560")
	sb.content_margin_left = 15
	sb.content_margin_right = 15
	sb.content_margin_top = 12
	sb.content_margin_bottom = 13
	outer.add_theme_stylebox_override("panel", sb)
	var v := _vbox(width - 34, 0)
	outer.add_child(v)
	_pix(v, "CNKI 科研诚信管理系统 · 学位论文检测", 7, Color("#657a8d"))
	_lab(v, "学位论文查重报告单", 15, Color("#26333d"), true)
	_pix(v, "报告编号：%s　|　检测时间：%s" % [d.get("reportNo", "—"), d.get("date", "")], 8, Color("#6f7b84"))
	var tag_row := _hbox(0)
	var tag_sp := Control.new()
	tag_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_row.add_child(tag_sp)
	var tagp := PanelContainer.new()
	var tgs := StyleBoxFlat.new()
	tgs.bg_color = Color(0, 0, 0, 0)
	tgs.border_width_left = 1
	tgs.border_width_top = 1
	tgs.border_width_right = 1
	tgs.border_width_bottom = 1
	tgs.border_color = Color("#8997a3")
	tgs.content_margin_left = 4
	tgs.content_margin_right = 4
	tgs.content_margin_top = 1
	tgs.content_margin_bottom = 1
	tagp.add_theme_stylebox_override("panel", tgs)
	tag_row.add_child(tagp)
	_pix(tagp, "检测专用", 7, Color("#6e8396"))
	v.add_child(tag_row)
	_space(v, 6)
	var main := _hbox(13)
	var rate_box := _vbox(128, 0)
	var rh := _hbox(2)
	rh.alignment = BoxContainer.ALIGNMENT_CENTER
	rh.custom_minimum_size.y = 36
	var big := _pix(rh, "%.1f" % rate, 36, Color("#24323d"), HORIZONTAL_ALIGNMENT_RIGHT)
	var pct := _pix(rh, "%", 16, Color("#24323d"))
	rate_box.add_child(rh)
	var cap := _pix(rate_box, "总文字复制比", 7, Color("#6c7880"), HORIZONTAL_ALIGNMENT_CENTER)
	cap.custom_minimum_size.y = 12
	main.add_child(rate_box)
	var sep := ColorRect.new()
	sep.color = Color("#b0b7bc")
	sep.custom_minimum_size.x = 1
	sep.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(sep)
	var fg := _vbox(width - 190, 0)
	var r1 := _hbox(8)
	_rep_field(r1, "姓名", str(d.get("name", "")), (width - 200) * 0.5)
	_rep_field(r1, "学号", str(d.get("id", "")), (width - 200) * 0.5)
	fg.add_child(r1)
	var r2 := _hbox(8)
	_rep_field(r2, "检测系统", "CNKI 5.3 / 学位论文检测", (width - 200) * 0.5)
	_rep_field(r2, "去除引用", "%.1f%%" % max(0.0, rate - 4.3), (width - 200) * 0.5)
	fg.add_child(r2)
	var r3 := _hbox(8)
	_rep_field(r3, "学院", str(s.get("official", {}).get("college", "")), width - 210)
	fg.add_child(r3)
	main.add_child(fg)
	v.add_child(main)
	_space(v, 6)
	var bottom := _hbox(10)
	var note := _lab(bottom, "本报告仅用于学位论文审查，复制比超过阈值时须按《学术不端行为处理办法》处理。\n报告信息须与论文封面及学籍档案一致。", 8, Color("#63717c"))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var seal_holder := Control.new()
	seal_holder.custom_minimum_size = Vector2(104, 52)
	if bool(d.get("seal", true)):
		var es := _seal([["教务处", "9"], ["电子签章", "7"], ["2026.05.01", "6"]], 86, 54, false)
		es.position = Vector2(10, 0)
		es.rotation = deg_to_rad(-7)
		seal_holder.add_child(es)
	else:
		var miss := PanelContainer.new()
		var ms := StyleBoxFlat.new()
		ms.bg_color = Color(0, 0, 0, 0)
		ms.border_width_left = 2
		ms.border_width_top = 2
		ms.border_width_right = 2
		ms.border_width_bottom = 2
		ms.border_color = Color("#a65d50")
		ms.border_blend = true
		miss.add_theme_stylebox_override("panel", ms)
		miss.position = Vector2(0, 4)
		miss.size = Vector2(104, 46)
		_pix(miss, "电子签章：缺失", 8, Color("#8b4a3d"), HORIZONTAL_ALIGNMENT_CENTER)
		seal_holder.add_child(miss)
	bottom.add_child(seal_holder)
	v.add_child(bottom)
	_space(v, 6)
	var bar := Barcode.new()
	bar.custom_minimum_size = Vector2(width - 32, 19)
	v.add_child(bar)
	return outer

static func _rep_field(parent: Node, k: String, v: String, width: float) -> void:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size.x = width
	wrap.add_theme_constant_override("separation", 0)
	var h := _hbox(5)
	var kl := _lab(h, k, 9, Color("#71808b"))
	kl.custom_minimum_size.x = 42
	kl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var vl := _lab(h, v, 9, Color("#27343d"), true)
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(h)
	_line(wrap, Color(80 / 255.0, 101 / 255.0, 116 / 255.0, 0.28), 1)
	parent.add_child(wrap)

# ------------------------------------------------------------
# review form
# ------------------------------------------------------------
static func _form(s: Dictionary, width: float) -> Control:
	var f: Dictionary = s.get("form", {})
	var o: Dictionary = s.get("official", {})
	var sigs: Dictionary = f.get("signatures", {})
	var v := _vbox(width, 0)
	var title := _lab(v, "本科毕业论文答辩资格审查表", 15, Color("#2c2518"), true, HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 22
	_space(v, 4)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, 190)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := PixelPanel.new()
	bg.bg_color = Color("#8d7852")
	holder.add_child(bg)
	Ui.place(bg, 0, 0, width, 190)
	var col_w := [84.0, 278.0, 84.0, 250.0]
	var rows := [
		["学生姓名", str(o.get("name", "")), "学　号", str(o.get("id", ""))],
		["指导教师签字", "", "系主任签字", ""],
		["教学院长签字", "", "学院", str(o.get("college", ""))],
		["研究类型", "涉及人体（问卷／访谈／临床）" if bool(f.get("human", false)) else "不涉及人体或动物实验", "伦理批件号", (f.get("ethicsNo") if bool(f.get("human", false)) else "无需")],
		["已修学分", "%d / 160" % int(f.get("credits", 0)), "学费", "已结清" if str(f.get("tuition", "paid")) == "paid" else "欠缴 ¥%s" % Ui.fmt_money(int(f.get("tuitionOwed", 0)))]
	]
	var y := 0.0
	for ri in range(rows.size()):
		var rh := 30.0
		var row: Array = rows[ri]
		var x := 0.0
		for ci in range(4):
			var cw: float = col_w[ci]
			var cell := PixelPanel.new()
			cell.bg_color = Color("#f4e9c9") if ci % 2 == 1 else Color("#eee2c2")
			holder.add_child(cell)
			Ui.place(cell, x, y, cw - 1, rh - 1)
			var cell_anchor := ""
			if ri == 1 and ci == 1:
				cell_anchor = "form.sig.advisor"
			elif ri == 1 and ci == 3:
				cell_anchor = "form.sig.chair"
			elif ri == 2 and ci == 1:
				cell_anchor = "form.sig.dean"
			elif ri == 3 and ci == 3:
				cell_anchor = "form.ethics"
			elif ri == 4 and ci == 1:
				cell_anchor = "admin.credits"
			elif ri == 4 and ci == 3:
				cell_anchor = "admin.tuition"
			if cell_anchor != "":
				cell.set_meta("anchor", cell_anchor)
			var txt := str(row[ci])
			if ri == 1 and (ci == 1 or ci == 3):
				var key := "advisor" if ci == 1 else "chair"
				var signer: Variant = sigs.get(key, null)
				if signer:
					var hand := _hand(str(signer), 14)
					hand.position = Vector2(8, 2)
					hand.size = Vector2(cw - 16, rh - 4)
					cell.add_child(hand)
				else:
					var miss := _pix(cell, "未签", 8, Color("#9a8967"))
					miss.position = Vector2(8, 6)
					miss.size = Vector2(cw - 16, 16)
			elif ri == 2 and ci == 1:
				var signer2: Variant = sigs.get("dean", null)
				if signer2:
					var hand2 := _hand(str(signer2), 14)
					hand2.position = Vector2(8, 2)
					hand2.size = Vector2(cw - 16, rh - 4)
					cell.add_child(hand2)
				else:
					var miss2 := _pix(cell, "未签", 8, Color("#9a8967"))
					miss2.position = Vector2(8, 6)
					miss2.size = Vector2(cw - 16, 16)
			else:
				var lb := _lab(cell, txt, 9, Color("#6a5839") if ci % 2 == 0 else Color("#3d3322"), ci % 2 == 0)
				lb.position = Vector2(6, 7)
				lb.size = Vector2(cw - 12, rh - 10)
				if ci % 2 == 1 and ri == 4:
					if ci == 3:
						lb.add_theme_color_override("font_color", Color("#3e6741") if str(f.get("tuition", "paid")) == "paid" else Color("#8b382b"))
					else:
						lb.add_theme_color_override("font_color", Color("#3d3322"))
			x += cw
		y += rh
	var merged := PixelPanel.new()
	merged.bg_color = Color("#f4e9c9")
	holder.add_child(merged)
	Ui.place(merged, 0, 150, width - 1, 39)
	var mk := _lab(merged, "导师意见", 9, Color("#6a5839"), true)
	mk.position = Vector2(6, 12)
	mk.size = Vector2(78, 16)
	var mv := _lab(merged, "论文已完成既定研究计划，同意提交答辩资格审查。", 9, Color("#3d3322"))
	mv.position = Vector2(90, 12)
	mv.size = Vector2(width - 240, 16)
	if sigs.get("advisor", null):
		var mh := _hand(str(sigs.get("advisor", "")), 11)
		mh.position = Vector2(width - 140, 7)
		mh.size = Vector2(100, 22)
		merged.add_child(mh)
	v.add_child(holder)
	_space(v, 6)
	var foot := _hbox(8)
	var note := _pix(foot, "本表须经导师、系主任、教学院长三方签字后生效。", 7, Color("#857352"))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stamp := _seal([["资格审查", "9"], ["专用", "7"]], 102, 36, false, Color(151 / 255.0, 54 / 255.0, 43 / 255.0, 0.75))
	stamp.custom_minimum_size = Vector2(102, 36)
	foot.add_child(stamp)
	v.add_child(foot)
	return v

# ------------------------------------------------------------
# supplementary sheets
# ------------------------------------------------------------
static func _extra(s: Dictionary, width: float, kind: String) -> Control:
	var o: Dictionary = s.get("official", {})
	var f: Dictionary = s.get("form", {})
	var compact := width < 600
	var v := _vbox(width, 0)
	var head := _hbox(10)
	var left := _vbox(width * 0.62, 0)
	var kicker := {
		"opening": "PROCESS FILE / 过程材料",
		"advisor": "ADVISOR NOTE / 过程材料",
		"ethics": "ETHICS DECLARATION / 合规材料" if !bool(f.get("human", false)) else "ETHICS APPROVAL / 合规材料",
		"records": "ACADEMIC RECORD / 教务材料",
	}
	var office := {
		"opening": "明州大学教务处 · 附件 01",
		"advisor": "指导教师意见书 · 附件 02",
		"ethics": "明州大学伦理委员会 · 附件 03",
		"records": "明州大学教务处学籍科 · 附件 04",
	}
	var right := {
		"opening": "归档日期\n2025.11.21",
		"advisor": "提交日期\n2026.05.08",
		"ethics": "批件日期\n2026.03.18",
		"records": "打印日期\n2026.05.16",
	}
	_pix(left, str(kicker[kind]), 7, Color("#8b382b"))
	_lab(left, str(office[kind]), 9, Color("#6b593b"))
	head.add_child(left)
	var rr := _lab(head, str(right[kind]), 9, Color("#6b593b"), false, HORIZONTAL_ALIGNMENT_RIGHT)
	rr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(head)
	_line(v, Color("#5e4d30"), 2)
	_space(v, 6)
	var title_text := {
		"opening": "本科毕业论文（设计）开题报告",
		"advisor": "指导教师意见书",
		"ethics": "不涉及人体研究声明" if !bool(f.get("human", false)) else "伦理审查批件",
		"records": "学籍与缴费情况证明",
	}
	var subtitle := {
		"opening": "RESEARCH PROPOSAL",
		"advisor": "ADVISOR’S STATEMENT",
		"ethics": "NON-HUMAN RESEARCH DECLARATION" if !bool(f.get("human", false)) else "ETHICS REVIEW APPROVAL",
		"records": "ACADEMIC STATUS & PAYMENT RECORD",
	}
	var t := _lab(v, str(title_text[kind]), 16 if compact else 18, Color("#2b2418"), true, HORIZONTAL_ALIGNMENT_CENTER)
	t.custom_minimum_size.y = 26
	var st := _pix(v, str(subtitle[kind]), 7, Color("#8b7755"), HORIZONTAL_ALIGNMENT_CENTER)
	st.custom_minimum_size.y = 10
	_space(v, 5)
	var meta := PanelContainer.new()
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(1, 1, 1, 0.14)
	ms.border_width_top = 1
	ms.border_width_bottom = 1
	ms.border_color = Color("#9a865f")
	ms.content_margin_left = 8
	ms.content_margin_right = 8
	ms.content_margin_top = 6
	ms.content_margin_bottom = 6
	meta.add_theme_stylebox_override("panel", ms)
	var mv := _vbox(width - 18, 1)
	var w2 := (width - 36) * 0.5
	match kind:
		"opening":
			var r1 := _hbox(14)
			_meta_field(r1, "学生姓名", str(o.get("name", "")), w2, compact)
			_meta_field(r1, "学　号", str(o.get("id", "")), w2, compact)
			mv.add_child(r1)
			var r2 := _hbox(14)
			_meta_field(r2, "专　业", str(o.get("major", "")), w2, compact)
			_meta_field(r2, "指导教师", "%s　%s" % [str(o.get("advisor", "——")), str(o.get("advisorTitle", ""))], w2, compact)
			mv.add_child(r2)
			_meta_wide(mv, "论文题目", str(s.get("title", "")), width - 18, compact)
		"advisor":
			var r1 := _hbox(14)
			_meta_field(r1, "学生姓名", str(o.get("name", "")), w2, compact)
			_meta_field(r1, "学　号", str(o.get("id", "")), w2, compact)
			mv.add_child(r1)
			_meta_wide(mv, "论文题目", str(s.get("title", "")), width - 18, compact)
		"ethics":
			var r1 := _hbox(14)
			_meta_field(r1, "申请人", str(o.get("name", "")), w2, compact)
			_meta_field(r1, "学　号", str(o.get("id", "")), w2, compact)
			mv.add_child(r1)
			_meta_wide(mv, "论文题目", str(s.get("title", "")), width - 18, compact)
			var r2 := _hbox(14)
			_meta_field(r2, "研究类型", "涉及人体" if bool(f.get("human", false)) else "不涉及人体", w2, compact)
			_meta_field(r2, "伦理批件", str(f.get("ethicsNo", "—")) if bool(f.get("human", false)) else "无需", w2, compact)
			mv.add_child(r2)
		"records":
			var r1 := _hbox(14)
			_meta_field(r1, "学生姓名", str(o.get("name", "")), w2, compact)
			_meta_field(r1, "学　号", str(o.get("id", "")), w2, compact)
			mv.add_child(r1)
			var r2 := _hbox(14)
			_meta_field(r2, "专　业", str(o.get("major", "")), w2, compact)
			_meta_field(r2, "班　级", str(o.get("clazz", "")), w2, compact)
			mv.add_child(r2)
	meta.add_child(mv)
	v.add_child(meta)
	_space(v, 7)
	match kind:
		"opening":
			_extra_section(v, "一、选题背景与意义", str(s.get("excerpt", "")), width, compact)
			_extra_section(v, "二、研究计划", "2025 年 11 月至 2026 年 1 月完成文献梳理与框架搭建；2026 年 2 月至 4 月开展资料收集、实验或设计实践；2026 年 5 月完成正文写作、修改与定稿。", width, compact)
		"advisor":
			_extra_section(v, "导师评语", "该生能够按计划完成文献梳理、研究实施与论文写作，材料基本齐全。论文选题符合专业培养目标，研究过程较为规范。请答辩资格审查小组结合查重报告、正文装订及附件材料继续审核。", width, compact)
			_extra_section(v, "对答辩的意见", "同意提交答辩资格审查。", width, compact)
		"ethics":
			if bool(f.get("human", false)):
				_extra_section(v, "审查结论", "经伦理委员会审查，本研究的研究方案、知情同意程序与隐私保护措施符合伦理要求，同意按批准方案实施。" if f.get("ethicsNo", null) else "申请人尚未提交完整伦理审查材料，伦理批件编号为空。涉及人体研究在取得有效批件前，不得进入答辩资格审查。", width, compact)
				var status := _hbox(12)
				_lab(status, "伦理批件：%s" % (str(f.get("ethicsNo", "")) if f.get("ethicsNo", null) else "未提交"), 8, Color("#5e4c30"), true)
				_lab(status, "审查状态：%s" % ("已通过" if f.get("ethicsNo", null) else "未完成"), 8, Color("#5e4c30"))
				v.add_child(status)
			else:
				_extra_section(v, "研究类型声明", "本研究不涉及人体受试者、人体样本或动物实验，不涉及可识别个人身份的访谈资料，依据学校相关规定无需申请伦理批件。", width, compact)
		"records":
			_extra_section(v, "说明", "本证明仅反映打印时点的学籍与缴费状态。已修学分未达到 160 学分或学费未结清的，材料须退回教务处补充核验。", width, compact)
	_space(v, 10)
	var row := _hbox(12)
	var sig_col := _vbox(width - 130, 0)
	var sig_text := {
		"opening": "指导教师签字：",
		"advisor": "指导教师（签字）：",
		"ethics": "伦理委员会（签章）",
		"records": "经办人：教务处学籍科",
	}
	_lab(sig_col, str(sig_text[kind]), 9, Color("#51432e"))
	var sig_line := Label.new()
	sig_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sig_line.add_theme_font_override("font", Ui.F_DOC)
	Ui.set_font(sig_line, int(round(9)))
	sig_line.add_theme_color_override("font_color", Color("#51432e"))
	sig_line.text = {
		"opening": "2025 年 11 月 20 日",
		"advisor": "2026 年 5 月 8 日",
		"ethics": "2026 年 3 月 18 日",
		"records": "2026 年 5 月 16 日",
	}[kind]
	sig_col.add_child(sig_line)
	row.add_child(sig_col)
	var seal_lines: Array = []
	var seal_color := Color(149 / 255.0, 48 / 255.0, 38 / 255.0, 0.82)
	if kind == "opening":
		seal_lines = [["同意开题", "9"]]
		seal_color = Color(76 / 255.0, 112 / 255.0, 80 / 255.0, 0.8)
	elif kind == "advisor":
		seal_lines = [["导师", "9"], ["审阅", "7"], ["2026.05", "6"]]
	elif kind == "ethics":
		seal_lines = [["伦理" if f.get("ethicsNo", null) else "未提交", "9"], ["审查通过" if f.get("ethicsNo", null) else "无批件", "7"], ["2026.03", "6"]]
	else:
		seal_lines = [["教务", "9"], ["学籍科", "7"], ["2026.05", "6"]]
	var seal := _seal(seal_lines, 82, 52, false, seal_color)
	row.add_child(seal)
	v.add_child(row)
	_space(v, 7)
	_line(v, Color(161 / 255.0, 141 / 255.0, 100 / 255.0, 0.6), 1)
	_lab(v, "本页为过程材料，仅供核对题目、专业与进度。" if kind == "opening" else "本页与《答辩资格审查表》中的签字应相互印证。", 7, Color("#8a7754"))
	return v

static func _meta_field(parent: Node, k: String, v: String, width: float, compact: bool) -> void:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size.x = width
	wrap.add_theme_constant_override("separation", 0)
	var h := _hbox(6)
	var kl := _lab(h, k, 8 if compact else 9, Color("#786440"))
	kl.custom_minimum_size.x = 50
	kl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var vl := _lab(h, v, 8 if compact else 9, Color("#3e3423"), true)
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(h)
	_line(wrap, Color(97 / 255.0, 78 / 255.0, 47 / 255.0, 0.25), 1)
	parent.add_child(wrap)

static func _meta_wide(parent: Node, k: String, v: String, width: float, compact: bool) -> void:
	_meta_field(parent, k, v, width, compact)

static func _extra_section(parent: Node, heading: String, text: String, width: float, compact: bool) -> void:
	_space(parent, 6)
	var h := _lab(parent, heading, 10, Color("#3e3423"), true)
	h.custom_minimum_size.y = 16
	_para(parent, text, width, 9.7 if compact else 10.2, Color("#4a3e2c"), 17.0 if compact else 17.9, false)
