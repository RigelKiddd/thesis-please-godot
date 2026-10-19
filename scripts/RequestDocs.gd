extends RefCounted

## Renders one document from a face-to-face request packet. Each paper stock has
## its own ornament, typography and seal treatment, but all share the game's
## ink / paper / red-seal palette.

const MaterialPaperCtl := preload("res://scripts/MaterialPaper.gd")

static func render(doc: Dictionary, width: float = 560.0) -> Control:
	var st := MaterialPaperCtl.style(str(doc.get("style", "certificate")))
	var outer := PanelContainer.new()
	outer.custom_minimum_size.x = width
	var ob := StyleBoxFlat.new()
	ob.bg_color = st.border
	ob.border_width_left = 2
	ob.border_width_top = 2
	ob.border_width_right = 2
	ob.border_width_bottom = 2
	ob.content_margin_left = 2
	ob.content_margin_top = 2
	ob.content_margin_right = 2
	ob.content_margin_bottom = 2
	outer.add_theme_stylebox_override("panel", ob)

	var sheet := PanelContainer.new()
	sheet.custom_minimum_size.x = width - 4
	if st.tex != null:
		var ts := StyleBoxTexture.new()
		ts.texture = st.tex
		ts.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		ts.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		ts.content_margin_left = 24
		ts.content_margin_top = 18
		ts.content_margin_right = 24
		ts.content_margin_bottom = 20
		sheet.add_theme_stylebox_override("panel", ts)
	else:
		var ss := StyleBoxFlat.new()
		ss.bg_color = st.bg
		ss.content_margin_left = 24
		ss.content_margin_top = 18
		ss.content_margin_right = 24
		ss.content_margin_bottom = 20
		sheet.add_theme_stylebox_override("panel", ss)
	outer.add_child(sheet)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_child(v)

	var inner_w := width - 4 - 48
	_top_ornament(v, doc, st, inner_w)
	_header(v, doc, st, inner_w)

	# identity fields; applications reserve a photo box on the right
	var fields: Array = doc.get("fields", [])
	if !fields.is_empty():
		if bool(doc.get("photo", false)):
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 12)
			v.add_child(h)
			var grid_w := inner_w - 92.0
			var grid := _field_grid(fields, grid_w, st)
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(grid)
			h.add_child(_photo_box(st))
		else:
			v.add_child(_field_grid(fields, inner_w, st))

	var stats: Array = doc.get("stats", [])
	if !stats.is_empty():
		_rule(v, Color(st.border.r, st.border.g, st.border.b, 0.5), 1)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		v.add_child(row)
		for item in stats:
			var box := PanelContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(1, 1, 1, 0.28)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(st.border.r, st.border.g, st.border.b, 0.55)
			sb.content_margin_left = 8
			sb.content_margin_top = 5
			sb.content_margin_right = 8
			sb.content_margin_bottom = 6
			box.add_theme_stylebox_override("panel", sb)
			var bv := VBoxContainer.new()
			bv.add_theme_constant_override("separation", 0)
			box.add_child(bv)
			_lab(bv, str(item.get("k", "")), 8, st.soft, st.bold)
			_lab(bv, str(item.get("v", "")), 16, st.ink, st.title_font)
			row.add_child(box)

	var table: Dictionary = doc.get("table", {})
	if !table.is_empty():
		_table(v, table, inner_w, st)

	var paragraphs: Array = doc.get("paragraphs", [])
	for para in paragraphs:
		if typeof(para) != TYPE_DICTIONARY:
			continue
		var label := str(para.get("label", ""))
		if label != "":
			_lab(v, label, 8, st.soft, st.label_font)
		_para(v, str(para.get("text", "")), inner_w, st)

	var signature: Array = doc.get("signature", [])
	if !signature.is_empty():
		_signatures(v, signature, inner_w, st)

	_seal_float(v, doc, st, inner_w)
	var note := str(doc.get("note", ""))
	if note != "":
		_note(v, note, inner_w, st)
	_footer(v, doc, st)
	return outer

# ------------------------------------------------------------
# pieces
# ------------------------------------------------------------
static func _lab(parent: Node, text: String, size: int, color: Color, font: Font,
		wrap: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Ui.label(parent, text, 0, 0, 0, 0, size, color, font, align, VERTICAL_ALIGNMENT_TOP, wrap)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap:
		l.custom_minimum_size.y = _text_height(text, size, 420)
	else:
		l.custom_minimum_size.y = float(Ui.scaled_font(size)) * 1.32
	return l

static func _text_height(text: String, size: int, width: float) -> float:
	if width <= 10.0:
		width = 420.0
	var px := float(Ui.scaled_font(size))
	var approx_chars := maxf(1.0, width / (px * 1.02))
	var lines := maxf(1.0, ceil(float(text.length()) / approx_chars))
	return lines * px * 1.58 + px * 0.45

static func _spacer(parent: Node, h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)

static func _rule(parent: Node, color: Color, h: float = 1.0, w: float = -1.0) -> void:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size = Vector2(maxf(0.0, w), h)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(r)

static func _top_ornament(parent: Node, doc: Dictionary, st: Dictionary, width: float) -> void:
	var ornament := str(st.get("ornament", "gold"))
	match ornament:
		"mimeo":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color("#2e312c")
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 5
			bs.content_margin_bottom = 5
			band.add_theme_stylebox_override("panel", bs)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			band.add_child(h)
			_lab(h, "公示材料", 7, Color("#d9d4c1"), Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(h, ref, 7, Color("#b9b29d"), Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
		"kraft":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(st.accent.r, st.accent.g, st.accent.b, 0.94)
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 5
			bs.content_margin_bottom = 5
			band.add_theme_stylebox_override("panel", bs)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			band.add_child(h)
			_lab(h, "OFFICIAL RECOMMENDATION / 推荐材料", 7, Color("#f1e2c4"), Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(h, ref, 7, Color("#e4c9a5"), Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
		"carbon":
			var line := PixelPanel.new()
			line.custom_minimum_size.y = 4
			line.border_width = 1
			line.dashed = true
			line.dash_length = 6
			line.border_color = Color(st.soft.r, st.soft.g, st.soft.b, 0.55)
			parent.add_child(line)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 6)
			parent.add_child(h)
			_lab(h, "第一联 · 存根", 7, st.soft, st.label_font)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(h, ref, 7, st.soft, Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"sealed":
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.85), 3)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			parent.add_child(h)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(h, "REF. " + ref, 7, st.soft, Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"idcard":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(st.accent.r, st.accent.g, st.accent.b, 0.94)
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 5
			bs.content_margin_bottom = 5
			band.add_theme_stylebox_override("panel", bs)
			var bh := HBoxContainer.new()
			bh.add_theme_constant_override("separation", 8)
			band.add_child(bh)
			var id_label := "STUDENT ID / 学生证" if str(doc.get("style", "")) == "student_id" else "ID CARD / 证件卡"
			_lab(bh, id_label, 7, Color("#eaf4f4"), Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(bh, ref, 7, Color("#cfe4e8"), Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
			var stripe := ColorRect.new()
			stripe.color = Color(st.ink.r, st.ink.g, st.ink.b, 0.78)
			stripe.custom_minimum_size.y = 7
			stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(stripe)
		"foil":
			_rule(parent, Color("#8a5a26"), 2)
			_rule(parent, Color("#c9a252"), 1)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			parent.add_child(h)
			_lab(h, "SCHOLARSHIP / 奖学金证书", 7, st.soft, Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(h, "NO. " + ref, 7, st.soft, Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"letter":
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.85), 2)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			parent.add_child(h)
			_lab(h, "OFFICE OF ADMISSIONS / 录取通知", 7, st.soft, Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(h, ref, 7, st.soft, Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.32), 1)
		"ledger":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(st.accent.r, st.accent.g, st.accent.b, 0.9)
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 5
			bs.content_margin_bottom = 5
			band.add_theme_stylebox_override("panel", bs)
			var bh := HBoxContainer.new()
			bh.add_theme_constant_override("separation", 8)
			band.add_child(bh)
			_lab(bh, "BURSAR LEDGER / 财务台账", 7, Color("#eef3e2"), Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(bh, ref, 7, Color("#d5dfc5"), Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.45), 1)
		"index":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(st.accent.r, st.accent.g, st.accent.b, 0.85)
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 4
			bs.content_margin_bottom = 4
			band.add_theme_stylebox_override("panel", bs)
			var bh := HBoxContainer.new()
			bh.add_theme_constant_override("separation", 8)
			band.add_child(bh)
			_lab(bh, "ARCHIVE INDEX / 档案卡", 7, Color("#f4e6c8"), Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(bh, ref, 7, Color("#edd5b2"), Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.5), 2)
		"passport":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color("#344f6b")
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 7
			bs.content_margin_bottom = 7
			band.add_theme_stylebox_override("panel", bs)
			var bh := HBoxContainer.new()
			bh.add_theme_constant_override("separation", 8)
			band.add_child(bh)
			_lab(bh, "PASSPORT / 护照 · 签证页", 7, Color("#e8edf4"), Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(bh, ref, 7, Color("#c9d7e8"), Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
			_rule(parent, Color("#b08a3e"), 1)
		"boarding":
			var band := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color("#e9e7de")
			bs.border_width_left = 1
			bs.border_width_right = 1
			bs.border_width_top = 1
			bs.border_width_bottom = 1
			bs.border_color = Color(st.border.r, st.border.g, st.border.b, 0.55)
			bs.content_margin_left = 10
			bs.content_margin_right = 10
			bs.content_margin_top = 5
			bs.content_margin_bottom = 5
			band.add_theme_stylebox_override("panel", bs)
			var bh := HBoxContainer.new()
			bh.add_theme_constant_override("separation", 8)
			band.add_child(bh)
			_lab(bh, "BOARDING PASS / 登机牌", 7, st.soft, Ui.F_PIXEL)
			var ref := str(doc.get("ref", ""))
			if ref != "":
				var r := _lab(bh, ref, 7, st.soft, Ui.F_PIXEL)
				r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(band)
			var cut := PixelPanel.new()
			cut.custom_minimum_size.y = 4
			cut.border_width = 1
			cut.dashed = true
			cut.dash_length = 8
			cut.border_color = Color(st.soft.r, st.soft.g, st.soft.b, 0.5)
			parent.add_child(cut)
		_:
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.6), 2)
			_rule(parent, Color(st.accent.r, st.accent.g, st.accent.b, 0.35), 1)

static func _header(parent: Node, doc: Dictionary, st: Dictionary, width: float) -> void:
	var org := str(doc.get("org", ""))
	if org != "":
		var ol := _lab(parent, org, 9, st.soft, st.bold, false, HORIZONTAL_ALIGNMENT_CENTER)
		ol.add_theme_constant_override("line_spacing", 1)
	var title := str(doc.get("title", ""))
	var title_size := 21 if str(st.get("ornament", "")) in ["gold", "sealed"] else 19
	var tl := _lab(parent, title, title_size, st.ink, st.title_font)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size.y = float(Ui.scaled_font(title_size)) * 1.45
	var subtitle := str(doc.get("subtitle", ""))
	if subtitle != "":
		_lab(parent, subtitle, 7, st.soft, Ui.F_PIXEL)
	var ref := str(doc.get("ref", ""))
	if ref != "" and !["mimeo", "kraft", "carbon", "sealed"].has(str(st.get("ornament", ""))):
		var rl := _lab(parent, "编号 " + ref, 7, Color(st.soft.r, st.soft.g, st.soft.b, 0.9), Ui.F_PIXEL)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rule(parent, Color(st.border.r, st.border.g, st.border.b, 0.72), 2 if str(st.get("ornament", "")) == "sealed" else 1)

static func _field_grid(fields: Array, width: float, st: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 5)
	var cell_w := maxf(80.0, (width - 16.0) * 0.5)
	for item in fields:
		if typeof(item) != TYPE_ARRAY or item.size() < 2:
			continue
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		cell.custom_minimum_size.x = cell_w
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
		_lab(cell, str(item[0]), 7, st.soft, st.label_font)
		var vl := _lab(cell, str(item[1]), 9, st.ink, st.font, true)
		vl.custom_minimum_size.x = cell_w
		vl.custom_minimum_size.y = float(Ui.scaled_font(9)) * 1.35
	return grid

static func _photo_box(st: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(84, 106)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.22)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(st.border.r, st.border.g, st.border.b, 0.6)
	box.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	box.add_child(v)
	_lab(v, "照", 15, Color(st.soft.r, st.soft.g, st.soft.b, 0.55), st.title_font, false, HORIZONTAL_ALIGNMENT_CENTER)
	_lab(v, "片", 15, Color(st.soft.r, st.soft.g, st.soft.b, 0.55), st.title_font, false, HORIZONTAL_ALIGNMENT_CENTER)
	var tag := _lab(v, "骑缝章", 7, Color(st.accent.r, st.accent.g, st.accent.b, 0.75), Ui.F_PIXEL, false, HORIZONTAL_ALIGNMENT_CENTER)
	tag.rotation = deg_to_rad(-8)
	return box

static func _table(parent: Node, table: Dictionary, width: float, st: Dictionary) -> void:
	var columns: Array = table.get("columns", [])
	var rows: Array = table.get("rows", [])
	if columns.is_empty():
		return
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	box.add_child(head)
	var n := columns.size()
	var cw := (width - 4.0) / float(maxi(1, n))
	for i in range(n):
		var hc := PanelContainer.new()
		var hs := StyleBoxFlat.new()
		hs.bg_color = Color(st.border.r, st.border.g, st.border.b, 0.13)
		hs.border_width_bottom = 1
		hs.border_color = Color(st.border.r, st.border.g, st.border.b, 0.55)
		hs.content_margin_left = 5
		hs.content_margin_right = 5
		hs.content_margin_top = 3
		hs.content_margin_bottom = 3
		hc.add_theme_stylebox_override("panel", hs)
		hc.custom_minimum_size.x = cw
		hc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hc)
		_lab(hc, str(columns[i]), 8, st.soft, st.label_font)
	for ri in range(rows.size()):
		var row: Array = rows[ri]
		var rh := HBoxContainer.new()
		rh.add_theme_constant_override("separation", 0)
		box.add_child(rh)
		for ci in range(n):
			var cell := PanelContainer.new()
			var cs := StyleBoxFlat.new()
			cs.bg_color = Color(1, 1, 1, 0.10 if ri % 2 == 0 else 0.0)
			cs.border_width_bottom = 1
			cs.border_color = Color(st.border.r, st.border.g, st.border.b, 0.18)
			cs.content_margin_left = 5
			cs.content_margin_right = 5
			cs.content_margin_top = 2
			cs.content_margin_bottom = 2
			cell.add_theme_stylebox_override("panel", cs)
			cell.custom_minimum_size.x = cw
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rh.add_child(cell)
			var text := ""
			if ci < row.size():
				text = str(row[ci])
			_lab(cell, text, 9, st.ink, st.font if ci != 0 else st.bold)

static func _para(parent: Node, text: String, width: float, st: Dictionary) -> void:
	var body := "　　" + text
	var l := Ui.label(parent, body, 0, 0, 0, 0, 9, st.ink, st.font, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = width
	l.add_theme_constant_override("line_spacing", 3)
	l.custom_minimum_size.y = _text_height(body, 9, width) + 2.0

static func _signatures(parent: Node, items: Array, width: float, st: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	parent.add_child(grid)
	for item in items:
		if typeof(item) != TYPE_ARRAY or item.size() < 2:
			continue
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		cell.custom_minimum_size.x = (width - 20.0) * 0.5
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
		_lab(cell, str(item[0]), 7, st.soft, st.label_font)
		var val := str(item[1])
		var color: Color = st.ink
		var font: Font = st.font
		if val.contains("未签字") or val.contains("（未"):
			color = Color("#9b3127")
			font = st.bold
		elif str(item[0]).contains("签字"):
			font = Ui.F_HAND
		var l := _lab(cell, val, 11 if font == Ui.F_HAND else 9, color, font)
		l.custom_minimum_size.y = float(Ui.scaled_font(11 if font == Ui.F_HAND else 9)) * 1.45

static func _note(parent: Node, text: String, width: float, st: Dictionary) -> void:
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.22)
	sb.border_width_left = 3
	sb.border_color = Color(st.accent.r, st.accent.g, st.accent.b, 0.75)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	box.add_theme_stylebox_override("panel", sb)
	parent.add_child(box)
	var l := _lab(box, text, 8, st.soft, st.font, true)
	l.custom_minimum_size.y = _text_height(text, 8, width - 18) + 2.0

## The seal floats over the signature area instead of taking a full row of its
## own. That keeps it visible on the first screen of a long transcript, and it
## looks like a stamp pressed across the paper rather than a printed badge.
static func _seal_float(parent: Node, doc: Dictionary, st: Dictionary, width: float) -> void:
	var seal_d: Dictionary = doc.get("seal", {})
	if seal_d.is_empty():
		return
	var layer := Control.new()
	layer.custom_minimum_size = Vector2(width, 0)
	layer.size = Vector2(width, 0)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(layer)
	var seal := RequestSeal.new()
	seal.custom_minimum_size = Vector2(100, 100)
	seal.size = Vector2(100, 100)
	seal.position = Vector2(width - 104, -92)
	# Draw in tree order, not with a positive z_index. Godot's z_index is
	# relative to the parent, so seal.z_index=8 escaped the 520px window and
	# drew the first material's seal on top of the second overlapping material.
	layer.add_child(seal)
	# School seals stay red across every stock; the paper changes, the seal does not.
	seal.configure(str(seal_d.get("top", "明州大学")), str(seal_d.get("bottom", "教务处")),
		str(seal_d.get("date", "")), Color("#a83a2f"), bool(seal_d.get("broken", false)))

static func _footer(parent: Node, doc: Dictionary, st: Dictionary) -> void:
	_rule(parent, Color(st.border.r, st.border.g, st.border.b, 0.35), 1)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	parent.add_child(h)
	var footer_label := "MINGZHOU UNIVERSITY · 材料存档"
	if str(doc.get("style", "")) in ["admission", "passport", "boarding"]:
		footer_label = "OFFICE OF THE REGISTRAR · STUDENT RECORD"
	_lab(h, footer_label, 6, Color(st.soft.r, st.soft.g, st.soft.b, 0.8), Ui.F_PIXEL)
	var ref := str(doc.get("ref", ""))
	var r := _lab(h, ref, 6, Color(st.soft.r, st.soft.g, st.soft.b, 0.8), Ui.F_PIXEL)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
