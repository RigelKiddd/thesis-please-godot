class_name StoryDocs
extends RefCounted

## Native renderers for the v1.8 "after hours" documents.
## They reuse the same paper/folder as the thesis pages, but each material
## (receipt / memo / note / form / email / chat / file / decision) gets its own
## typographic treatment.

const FULL_W := 696.0
const PAD := 32.0
const INNER_W := FULL_W - PAD * 2.0
const INK := Color("#382f22")
const INK_SOFT := Color("#5d513e")
const RED := Color("#8b382b")
const GREEN := Color("#3f4f45")
const PAPER := Color("#e9e4d3")
const PAPER_DARK := Color("#ddd6c3")

static func fill(value: Variant, tokens: Dictionary) -> String:
	var s := str(value)
	for key in tokens.keys():
		s = s.replace("{{%s}}" % str(key), str(tokens[key]))
	return s

static func docs(scene: Dictionary, result: Dictionary) -> Array:
	var arr: Array = scene.get("docs", []).duplicate()
	if !result.is_empty():
		arr.append(result)
	return arr

# ---------------------------------------------------------------- helpers

static func _style(bg: Color, border: int = 0, bcol: Color = Color.BLACK,
		margins: Vector4 = Vector4.ZERO, shadow: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = border
	s.border_width_top = border
	s.border_width_right = border
	s.border_width_bottom = border
	s.border_color = bcol
	s.content_margin_left = margins.x
	s.content_margin_top = margins.y
	s.content_margin_right = margins.z
	s.content_margin_bottom = margins.w
	s.anti_aliasing = false
	if shadow != Vector2.ZERO:
		s.shadow_color = Color(0, 0, 0, 0.24)
		s.shadow_size = 1
		s.shadow_offset = shadow
	return s

static func _text_h(text: String, font: Font, size: int, width: float, line_px: float) -> float:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lines := maxi(1, int(ceil(tw / maxf(24.0, width))))
	return lines * line_px + 1.0

static func _label(parent: Node, text: String, size: int, color: Color, font: Font,
		wrap: bool = true, line_px: float = 0.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		width: float = INNER_W) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", font)
	Ui.set_font(l, size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.clip_text = false
		l.custom_minimum_size.y = _text_h(text, font, size, width, line_px if line_px > 0.0 else size + 4.0)
	else:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.clip_text = false
		l.custom_minimum_size.y = size + 5.0
	if line_px > 0.0:
		l.add_theme_constant_override("line_spacing", maxi(0, int(round(line_px - font.get_height(size)))))
	parent.add_child(l)
	return l

static func _spacer(parent: Node, h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c

static func _hline(parent: Node, color: Color, thick: int = 1, dashed: bool = false) -> void:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size.y = thick
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dashed:
		r.color = Color(color.r, color.g, color.b, color.a * 0.75)
	parent.add_child(r)

static func _tag(parent: Node, text: String, bg: Color, fg: Color = Color("#f2e5c1")) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(bg, 1, Color("#1b160f"), Vector4(5, 2, 5, 2)))
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Ui.F_UI_BOLD)
	Ui.set_font(l, int(round(9)))
	l.add_theme_color_override("font_color", fg)
	p.add_child(l)
	parent.add_child(p)
	return p

static func _panel(parent: Node, bg: Color, border: int, bcol: Color,
		margins: Vector4, fixed_w: float = -1.0, shadow: Vector2 = Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(bg, border, bcol, margins, shadow))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if fixed_w > 0.0:
		p.custom_minimum_size.x = fixed_w
	parent.add_child(p)
	return p

static func _vbox(parent: Node, sep: int = 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(v)
	return v

static func _hbox(parent: Node, sep: int = 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(h)
	return h

static func _root() -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	root.custom_minimum_size.x = FULL_W
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", int(PAD))
	m.add_theme_constant_override("margin_right", int(PAD))
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 12)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(m)
	var v := _vbox(m, 0)
	return {"root": root, "v": v}

static func _narrow_root(w: float) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	root.custom_minimum_size.x = FULL_W
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := MarginContainer.new()
	var side := int(maxf(0.0, (FULL_W - w) * 0.5))
	m.add_theme_constant_override("margin_left", side)
	m.add_theme_constant_override("margin_right", side)
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 10)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(m)
	return {"root": root, "m": m}

# ---------------------------------------------------------------- common blocks

static func _top(v: Node, doc: Dictionary, t: Dictionary, width: float) -> void:
	var h := _hbox(v, 10)
	_tag(h, fill(doc.get("badge", "内部文件"), t), _kind_color(str(doc.get("kind", "form"))))
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(grow)
	if str(doc.get("stamp", "")) != "":
		var sp := PanelContainer.new()
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.0), 1, Color(RED.r, RED.g, RED.b, 0.42), Vector4(4, 1, 4, 1)))
		sp.rotation = deg_to_rad(-2.0)
		var sl := Label.new()
		sl.text = fill(doc.get("stamp", ""), t)
		sl.add_theme_font_override("font", Ui.F_UI_BOLD)
		Ui.set_font(sl, int(round(9)))
		sl.add_theme_color_override("font_color", Color(RED.r, RED.g, RED.b, 0.85))
		sp.add_child(sl)
		h.add_child(sp)
	_spacer(v, 5)
	_hline(v, Color("#b09a70"))
	_spacer(v, 5)

	if str(doc.get("kicker", "")) != "":
		_label(v, fill(doc.get("kicker", ""), t), 8, RED, Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, width)
	if str(doc.get("officeLeft", "")) != "" || str(doc.get("officeRight", "")) != "":
		var oh := _hbox(v, 8)
		_label(oh, fill(doc.get("officeLeft", ""), t), 8, Color("#6c5d44"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, width * 0.6)
		var og := Control.new()
		og.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		og.mouse_filter = Control.MOUSE_FILTER_IGNORE
		oh.add_child(og)
		_label(oh, fill(doc.get("officeRight", ""), t), 8, Color("#6c5d44"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, width * 0.38)
	_label(v, fill(doc.get("title", ""), t), 21, Color("#2b2418"), Ui.F_DOC_BOLD, true, 27.0, HORIZONTAL_ALIGNMENT_LEFT, width)
	_label(v, fill(doc.get("subtitle", ""), t), 7, Color("#7c6b50"), Ui.F_MONO, false)
	_spacer(v, 4)
	_hline(v, Color("#b09a70"))
	_spacer(v, 5)

static func _kind_color(kind: String) -> Color:
	match kind:
		"memo": return Color("#3f4f45")
		"note": return Color("#8b382b")
		"chat": return Color("#2f3a2f")
		"result": return Color("#2f3a2f")
		"email": return Color("#3f4f45")
		_: return Color("#5d4b31")

static func _meta(v: Node, doc: Dictionary, t: Dictionary, width: float) -> void:
	var items: Array = doc.get("meta", [])
	if items.is_empty():
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 3)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grid)
	var half := (width - 16.0) * 0.5
	for it in items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.custom_minimum_size.x = half
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var k := Label.new()
		k.text = fill(it.get("k", ""), t)
		k.add_theme_font_override("font", Ui.F_UI)
		Ui.set_font(k, int(round(9)))
		k.add_theme_color_override("font_color", Color("#7a6b50"))
		k.custom_minimum_size.x = 38
		row.add_child(k)
		var val := Label.new()
		val.text = fill(it.get("v", ""), t)
		val.add_theme_font_override("font", Ui.F_DOC)
		Ui.set_font(val, int(round(11)))
		val.add_theme_color_override("font_color", INK)
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(val)
		grid.add_child(row)
	_spacer(v, 5)

static func _sections(v: Node, doc: Dictionary, t: Dictionary, width: float, hand: bool = false) -> void:
	for sec in doc.get("sections", []):
		if str(sec.get("h", "")) != "":
			_label(v, fill(sec.get("h", ""), t), 10, Color("#5d4b2f"), Ui.F_UI_BOLD, true, 15.0, HORIZONTAL_ALIGNMENT_LEFT, width)
			_spacer(v, 1)
		if str(sec.get("p", "")) != "":
			if hand:
				_label(v, fill(sec.get("p", ""), t), 12, INK, Ui.F_HAND, true, 23.0, HORIZONTAL_ALIGNMENT_LEFT, width)
			else:
				_label(v, fill(sec.get("p", ""), t), 10.5, Color("#453a29"), Ui.F_DOC, true, 18.5, HORIZONTAL_ALIGNMENT_LEFT, width)
			_spacer(v, 5)

static func _table(v: Node, doc: Dictionary, t: Dictionary) -> void:
	var rows: Array = doc.get("table", [])
	if rows.is_empty():
		return
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.025), 1, Color("#b09a70"), Vector4(8, 6, 8, 6)))
	v.add_child(p)
	var vb := _vbox(p, 1)
	for row in rows:
		if typeof(row) != TYPE_ARRAY or row.size() < 2:
			continue
		var h := _hbox(vb, 8)
		_label(h, fill(row[0], t), 8.5, Color("#7a6b50"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 120)
		_label(h, fill(row[1], t), 9.5, INK, Ui.F_DOC, false)
	_spacer(v, 5)

static func _intro(v: Node, doc: Dictionary, t: Dictionary, width: float) -> void:
	if str(doc.get("intro", "")) == "":
		return
	var p := HBoxContainer.new()
	p.add_theme_constant_override("separation", 8)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(p)
	var bar := ColorRect.new()
	bar.color = Color(RED.r, RED.g, RED.b, 0.38)
	bar.custom_minimum_size.x = 2
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(bar)
	_label(p, fill(doc.get("intro", ""), t), 11, Color("#51432e"), Ui.F_DOC, true, 19.0, HORIZONTAL_ALIGNMENT_LEFT, width - 10)
	_spacer(v, 5)

static func _stamp_row(v: Node, doc: Dictionary, t: Dictionary) -> void:
	var sig := str(doc.get("signature", ""))
	var seal := str(doc.get("seal", ""))
	if sig == "" && seal == "":
		return
	_spacer(v, 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(h)
	if sig != "":
		var l := Label.new()
		l.text = fill(sig, t)
		l.add_theme_font_override("font", Ui.F_HAND)
		Ui.set_font(l, int(round(14)))
		l.add_theme_color_override("font_color", INK)
		h.add_child(l)
	if seal != "":
		var sp := PanelContainer.new()
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var missing := bool(doc.get("sealMissing", false))
		sp.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), 2, Color(RED.r, RED.g, RED.b, 0.55 if !missing else 0.28), Vector4(7, 4, 7, 4)))
		sp.rotation = deg_to_rad(-5.0)
		var sv := _vbox(sp, 0)
		_label(sv, fill(seal, t), 11, Color(RED.r, RED.g, RED.b, 0.86), Ui.F_PIXEL, false)
		if str(doc.get("sealSub", "")) != "":
			_label(sv, fill(doc.get("sealSub", ""), t), 6.5, Color(RED.r, RED.g, RED.b, 0.7), Ui.F_UI, false)
		h.add_child(sp)

static func _note(v: Node, doc: Dictionary, t: Dictionary, width: float) -> void:
	if str(doc.get("note", "")) == "":
		return
	_spacer(v, 6)
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.16), 0, Color.BLACK, Vector4(7, 5, 7, 5)))
	v.add_child(p)
	_label(p, fill(doc.get("note", ""), t), 8.5, Color("#5b4c35"), Ui.F_DOC, true, 14.0, HORIZONTAL_ALIGNMENT_LEFT, width - 14)

# ---------------------------------------------------------------- documents

static func render(doc: Dictionary, t: Dictionary) -> Control:
	var kind := str(doc.get("kind", "form"))
	var d: Dictionary
	match kind:
		"receipt": d = _receipt(doc, t)
		"email": d = _email(doc, t)
		"chat": d = _chat(doc, t)
		"file": d = _file(doc, t)
		"note": d = _note_doc(doc, t)
		"result": d = _result(doc, t)
		_: d = _generic(doc, t, kind)
	return d["root"]

static func _generic(doc: Dictionary, t: Dictionary, kind: String) -> Dictionary:
	var r := _root()
	var v: VBoxContainer = r["v"]
	_top(v, doc, t, INNER_W)
	_meta(v, doc, t, INNER_W)
	_intro(v, doc, t, INNER_W)
	_sections(v, doc, t, INNER_W)
	_table(v, doc, t)
	_stamp_row(v, doc, t)
	_note(v, doc, t, INNER_W)
	return {"root": r["root"], "v": v}

static func _receipt(doc: Dictionary, t: Dictionary) -> Dictionary:
	var r := _narrow_root(390.0)
	var m: MarginContainer = r["m"]
	var p := _panel(m, PAPER_DARK, 1, Color("#a99b7c"), Vector4(15, 15, 15, 18), 390.0, Vector2(0, 8))
	var v := _vbox(p, 0)
	var rec: Dictionary = doc.get("receipt", {})

	_label(v, fill(rec.get("office", "明州大学总务处"), t), 10, Color("#4c3f2b"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label(v, fill(rec.get("title", doc.get("title", "")), t), 17, Color("#2d2519"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label(v, fill(rec.get("subtitle", ""), t), 7.5, Color("#6a5b43"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_CENTER)

	var meta := _hbox(v, 8)
	_label(meta, fill(rec.get("no", ""), t), 8, Color("#5d513e"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 180)
	var mg := Control.new()
	mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.add_child(mg)
	_label(meta, fill(rec.get("time", ""), t), 8, Color("#5d513e"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 160)
	_spacer(v, 5)
	_hline(v, Color("#8a7b62"))
	_spacer(v, 4)

	for item in rec.get("items", []):
		var ih := _hbox(v, 4)
		_label(ih, fill(item.get("label", ""), t), 9, INK, Ui.F_MONO, true, 13.0, HORIZONTAL_ALIGNMENT_LEFT, 220)
		_label(ih, "x" + fill(item.get("qty", "1"), t), 9, INK, Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_CENTER, 28)
		_label(ih, fill(item.get("amount", ""), t), 9, INK, Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 58)
	_spacer(v, 3)
	_hline(v, Color("#8a7b62"))

	var total := _hbox(v, 8)
	_label(total, "合计", 14, Color("#2d2519"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 120)
	var tg := Control.new()
	tg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	total.add_child(tg)
	_label(total, fill(rec.get("total", ""), t), 16, Color("#2d2519"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 140)

	var pay := _hbox(v, 8)
	_label(pay, "支付方式", 8, Color("#5d513e"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 100)
	var pg := Control.new()
	pg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pay.add_child(pg)
	_label(pay, fill(rec.get("pay", ""), t), 8, Color("#5d513e"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 140)

	_spacer(v, 5)
	var bc := Barcode.new()
	bc.custom_minimum_size = Vector2(360, 24)
	v.add_child(bc)
	_label(v, fill(rec.get("code", ""), t), 7.5, Color("#5d513e"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_label(v, fill(rec.get("footer", ""), t), 8, Color("#5d513e"), Ui.F_UI, true, 12.0, HORIZONTAL_ALIGNMENT_CENTER, 350)

	if str(doc.get("note", "")) != "":
		_spacer(v, 4)
		var np := PanelContainer.new()
		np.mouse_filter = Control.MOUSE_FILTER_IGNORE
		np.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.16), 0, Color.BLACK, Vector4(5, 4, 5, 4)))
		v.add_child(np)
		_label(np, fill(doc.get("note", ""), t), 9.5, Color("#4f422f"), Ui.F_DOC, true, 15.0, HORIZONTAL_ALIGNMENT_LEFT, 340)

	var sign := _hbox(v, 6)
	var sg := Control.new()
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign.add_child(sg)
	_label(sign, fill(rec.get("signature", ""), t), 10, Color("#4b3f2d"), Ui.F_HAND, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 260)

	if str(rec.get("stamp", "")) != "":
		var st := PanelContainer.new()
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		st.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), 2, Color(RED.r, RED.g, RED.b, 0.75), Vector4(6, 2, 6, 2)))
		st.rotation = deg_to_rad(-8.0)
		st.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var sl := Label.new()
		sl.text = fill(rec.get("stamp", ""), t)
		sl.add_theme_font_override("font", Ui.F_PIXEL)
		Ui.set_font(sl, int(round(11)))
		sl.add_theme_color_override("font_color", Color(RED.r, RED.g, RED.b, 0.8))
		st.add_child(sl)
		v.add_child(st)
	return {"root": r["root"], "v": v}

static func _email(doc: Dictionary, t: Dictionary) -> Dictionary:
	var r := _narrow_root(696.0)
	var m: MarginContainer = r["m"]
	m.add_theme_constant_override("margin_left", 0)
	m.add_theme_constant_override("margin_right", 0)
	var p := _panel(m, PAPER, 1, Color("#a89d82"), Vector4(0, 0, 0, 14), 696.0, Vector2(0, 7))
	var v := _vbox(p, 0)
	var e: Dictionary = doc.get("email", {})

	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", _style(Color("#2f3a2f"), 0, Color.BLACK, Vector4(16, 6, 16, 6)))
	v.add_child(bar)
	var bh := _hbox(bar, 10)
	_label(bh, "邮件打印件 / PRINTED EMAIL", 7.5, Color("#d8c79f"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 260)
	var bg := Control.new()
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bh.add_child(bg)
	if str(e.get("stamp", "")) != "":
		var sp := PanelContainer.new()
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), 1, Color("#cf5b46"), Vector4(4, 1, 4, 1)))
		var sl := Label.new()
		sl.text = fill(e.get("stamp", ""), t)
		sl.add_theme_font_override("font", Ui.F_UI_BOLD)
		Ui.set_font(sl, int(round(7)))
		sl.add_theme_color_override("font_color", Color("#f0c3a8"))
		sp.add_child(sl)
		bh.add_child(sp)
	_label(bh, fill(e.get("printedAt", ""), t), 6, Color("#a6b29d"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 220)

	var head := GridContainer.new()
	head.columns = 2
	head.add_theme_constant_override("h_separation", 16)
	head.add_theme_constant_override("v_separation", 3)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(head)
	var fields := [["发件人", e.get("from", "")], ["收件人", e.get("to", "")], ["抄送", e.get("cc", "")], ["时间", e.get("date", "")]]
	for f in fields:
		if str(f[1]) == "":
			continue
		var fh := _hbox(head, 6)
		fh.custom_minimum_size.x = 320
		fh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var k := Label.new()
		k.text = f[0]
		k.add_theme_font_override("font", Ui.F_UI)
		Ui.set_font(k, int(round(8)))
		k.add_theme_color_override("font_color", Color("#7a6b50"))
		k.custom_minimum_size.x = 38
		fh.add_child(k)
		_label(fh, fill(f[1], t), 8, INK, Ui.F_MONO, true, 12.0, HORIZONTAL_ALIGNMENT_LEFT, 270)

	var subj := PanelContainer.new()
	subj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subj.add_theme_stylebox_override("panel", _style(Color("#ded6bf"), 0, Color.BLACK, Vector4(10, 7, 10, 7)))
	v.add_child(subj)
	var sh := _hbox(subj, 8)
	_label(sh, "主题", 8, Color("#6d5c40"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 34)
	_label(sh, fill(e.get("subject", doc.get("title", "")), t), 12, Color("#2b2418"), Ui.F_DOC_BOLD, true, 17.0, HORIZONTAL_ALIGNMENT_LEFT, 580)

	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 18)
	body.add_theme_constant_override("margin_right", 18)
	body.add_theme_constant_override("margin_top", 8)
	body.add_theme_constant_override("margin_bottom", 2)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(body)
	var bv := _vbox(body, 0)
	_intro(bv, doc, t, 650)
	_sections(bv, doc, t, 650)
	_table(bv, doc, t)
	_note(bv, doc, t, 650)

	var sig := PanelContainer.new()
	sig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sig.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.0), 0, Color.BLACK, Vector4(18, 8, 18, 0)))
	v.add_child(sig)
	_label(sig, fill(e.get("signature", doc.get("signature", "")), t), 11, Color("#4d3d28"), Ui.F_HAND, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)

	var foot := PanelContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.0), 0, Color.BLACK, Vector4(18, 6, 18, 0)))
	v.add_child(foot)
	var fh := _hbox(foot, 10)
	_label(fh, fill(e.get("footer", "本邮件由系统自动打印，仅供内部归档。"), t), 6.5, Color("#817156"), Ui.F_MONO, true, 10.0, HORIZONTAL_ALIGNMENT_LEFT, 500)
	_label(fh, "MAILGATE / 2026", 6, Color("#5b6b5b"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 120)
	return {"root": r["root"], "v": v}

static func _chat(doc: Dictionary, t: Dictionary) -> Dictionary:
	var r := _narrow_root(450.0)
	var m: MarginContainer = r["m"]
	var p := _panel(m, Color("#e9e4d3"), 1, Color("#a89d82"), Vector4(11, 11, 11, 9), 450.0, Vector2(0, 8))
	var v := _vbox(p, 0)
	var c: Dictionary = doc.get("chat", {})

	var phone := PanelContainer.new()
	phone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone.add_theme_stylebox_override("panel", _style(Color("#1b231d"), 3, Color("#0f1510"), Vector4(0, 0, 0, 0)))
	v.add_child(phone)
	var pv := _vbox(phone, 0)

	var status := PanelContainer.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_theme_stylebox_override("panel", _style(Color("#151c17"), 0, Color.BLACK, Vector4(8, 3, 8, 3)))
	pv.add_child(status)
	var sh := _hbox(status, 8)
	_label(sh, "WeChat", 7.5, Color("#9fb39d"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 100)
	var sg := Control.new()
	sg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(sg)
	_label(sh, fill(c.get("time", ""), t), 7.5, Color("#9fb39d"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 80)
	_label(sh, "···", 7, Color("#9fb39d"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 20)

	var head := PanelContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_stylebox_override("panel", _style(Color("#2f3a2f"), 0, Color.BLACK, Vector4(9, 6, 9, 6)))
	pv.add_child(head)
	var hh := _hbox(head, 7)
	_label(hh, "‹", 16, Color("#b8c7b4"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 16)
	var hv := _vbox(hh, 0)
	_label(hv, fill(c.get("contact", ""), t), 11, Color("#e7dcbc"), Ui.F_UI_BOLD, false)
	_label(hv, fill(c.get("role", ""), t), 7, Color("#a6b29d"), Ui.F_MONO, false)
	var hg := Control.new()
	hg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(hg)
	_label(hh, "···", 7, Color("#a6b29d"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 20)

	var body := PanelContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", _style(Color("#d8d4c6"), 0, Color.BLACK, Vector4(9, 8, 9, 12)))
	pv.add_child(body)
	var bv := _vbox(body, 0)
	_label(bv, fill(c.get("dayLabel", "今天"), t), 7.5, Color("#7b705c"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_spacer(bv, 6)
	for msg in c.get("messages", []):
		_chat_message(bv, msg, c, t)

	var input := PanelContainer.new()
	input.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input.add_theme_stylebox_override("panel", _style(Color("#f0ebdb"), 0, Color.BLACK, Vector4(8, 5, 8, 5)))
	pv.add_child(input)
	var ih := _hbox(input, 8)
	_label(ih, "发送消息…", 8, Color("#8a7d67"), Ui.F_UI, false)
	_label(ih, "☺", 10, Color("#6b5f4a"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 30)

	_spacer(v, 3)
	_label(v, "截图打印 · 03窗口归档 · " + fill(c.get("printedAt", ""), t), 6.5, Color("#817156"), Ui.F_MONO, true, 9.0, HORIZONTAL_ALIGNMENT_LEFT, 420)
	_note(v, doc, t, 420)
	return {"root": r["root"], "v": v}

static func _chat_message(parent: Node, msg: Dictionary, c: Dictionary, t: Dictionary) -> void:
	var from := str(msg.get("from", "them"))
	if from == "system" || str(msg.get("type", "")) == "system":
		_label(parent, fill(msg.get("text", ""), t), 7.5, Color("#7b705c"), Ui.F_UI, true, 10.0, HORIZONTAL_ALIGNMENT_CENTER, 380)
		_spacer(parent, 3)
		return
	var mine := from == "me"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	parent.add_child(row)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(22, 22)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.add_theme_stylebox_override("panel", _style(Color("#5d4b31") if mine else Color("#3f4f45"), 1, Color("#8f7952") if mine else Color("#6d7a68"), Vector4(0, 0, 0, 0)))
	var al := Label.new()
	al.text = fill(msg.get("avatar", "周" if mine else str(c.get("contact", "对")).substr(0, 1)), t)
	al.add_theme_font_override("font", Ui.F_PIXEL)
	Ui.set_font(al, int(round(9)))
	al.add_theme_color_override("font_color", Color("#e7dcbc"))
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(al)
	if !mine:
		row.add_child(avatar)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	col.custom_minimum_size.x = 300
	col.size_flags_horizontal = Control.SIZE_SHRINK_END if mine else Control.SIZE_SHRINK_BEGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bubble := PanelContainer.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_stylebox_override("panel", _style(Color("#a9cf88") if mine else Color("#f5f1e3"), 1, Color("#7e9b62") if mine else Color("#b9ae96"), Vector4(7, 5, 7, 5)))
	col.add_child(bubble)
	var bv := _vbox(bubble, 0)
	var mtype := str(msg.get("type", "text"))
	if mtype == "file":
		var fh := _hbox(bv, 5)
		_label(fh, fill(msg.get("fileType", "FILE"), t), 9, Color("#2b5a7a"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 36)
		var fv := _vbox(fh, 0)
		_label(fv, fill(msg.get("fileName", "文件"), t), 10, Color("#2b2418"), Ui.F_UI_BOLD, false)
		_label(fv, fill(msg.get("fileSize", ""), t), 7.5, Color("#7a6b50"), Ui.F_UI, false)
	else:
		if mtype == "voice":
			_label(bv, "▮▮▮▮   " + fill(msg.get("duration", ""), t), 10, Color("#2b2418"), Ui.F_UI, false)
		else:
			_label(bv, fill(msg.get("text", ""), t), 10, Color("#2b2418"), Ui.F_DOC, true, 16.0, HORIZONTAL_ALIGNMENT_LEFT, 280)
	if str(msg.get("time", "")) != "":
		_label(bv, fill(msg.get("time", ""), t), 6.5, Color("#81745e"), Ui.F_MONO, false)
	row.add_child(col)
	if mine:
		row.add_child(avatar)
	_spacer(parent, 5)

static func _file(doc: Dictionary, t: Dictionary) -> Dictionary:
	var r := _root()
	var v: VBoxContainer = r["v"]
	var f: Dictionary = doc.get("file", {})
	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("panel", _style(Color("#2f3a2f"), 0, Color.BLACK, Vector4(10, 7, 10, 7)))
	v.add_child(bar)
	var bh := _hbox(bar, 9)
	var type := PanelContainer.new()
	type.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type.add_theme_stylebox_override("panel", _style(Color("#b76550"), 1, Color("#6d2b22"), Vector4(5, 2, 5, 2)))
	var tl := Label.new()
	tl.text = fill(f.get("type", "PDF"), t)
	tl.add_theme_font_override("font", Ui.F_UI_BOLD)
	Ui.set_font(tl, int(round(8)))
	tl.add_theme_color_override("font_color", Color("#f4e1d0"))
	type.add_child(tl)
	bh.add_child(type)
	var nv := _vbox(bh, 0)
	_label(nv, fill(f.get("name", doc.get("title", "")), t), 10, Color("#f0e4c5"), Ui.F_UI_BOLD, true, 14.0, HORIZONTAL_ALIGNMENT_LEFT, 470)
	_label(nv, fill(f.get("path", ""), t), 6.5, Color("#a6b29d"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 470)
	var bg := Control.new()
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(bg)
	if str(doc.get("stamp", "")) != "":
		_label(bh, fill(doc.get("stamp", ""), t), 7, Color("#d9c79f"), Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 100)
	_label(bh, fill(f.get("pages", ""), t), 7, Color("#a6b29d"), Ui.F_MONO, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 44)

	var mgrid := GridContainer.new()
	mgrid.columns = 2
	mgrid.add_theme_constant_override("h_separation", 16)
	mgrid.add_theme_constant_override("v_separation", 3)
	mgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(mgrid)
	for pair in [["大小", f.get("size", "")], ["页数", f.get("pages", "")], ["修改", f.get("modified", "")], ["哈希", f.get("hash", "")]]:
		var row := _hbox(mgrid, 6)
		row.custom_minimum_size.x = (INNER_W - 16.0) * 0.5
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(row, pair[0], 8, Color("#7a6b50"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, 34)
		_label(row, fill(pair[1], t), 8.5, INK, Ui.F_MONO, true, 12.0, HORIZONTAL_ALIGNMENT_LEFT, 250)
	_spacer(v, 6)
	_hline(v, Color("#b09a70"))
	_spacer(v, 5)
	_topless(v, doc, t, INNER_W)
	_meta(v, doc, t, INNER_W)
	_intro(v, doc, t, INNER_W)
	_sections(v, doc, t, INNER_W)
	_table(v, doc, t)
	_stamp_row(v, doc, t)
	_note(v, doc, t, INNER_W)
	_spacer(v, 6)
	var foot := _hbox(v, 8)
	_label(foot, fill(f.get("hash", f.get("path", "")), t), 6, Color("#817156"), Ui.F_MONO, true, 9.0, HORIZONTAL_ALIGNMENT_LEFT, 480)
	var fg := Control.new()
	fg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(fg)
	_label(foot, fill(f.get("archived", "已归档"), t), 6.5, Color("#817156"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT, 100)
	return {"root": r["root"], "v": v}

static func _topless(v: Node, doc: Dictionary, t: Dictionary, width: float) -> void:
	if str(doc.get("kicker", "")) != "":
		_label(v, fill(doc.get("kicker", ""), t), 8, RED, Ui.F_UI_BOLD, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, width)
	if str(doc.get("officeLeft", "")) != "":
		_label(v, fill(doc.get("officeLeft", ""), t), 8, Color("#6c5d44"), Ui.F_UI, false, 0.0, HORIZONTAL_ALIGNMENT_LEFT, width)
	_label(v, fill(doc.get("title", ""), t), 20, Color("#2b2418"), Ui.F_DOC_BOLD, true, 26.0, HORIZONTAL_ALIGNMENT_LEFT, width)
	_label(v, fill(doc.get("subtitle", ""), t), 7, Color("#7c6b50"), Ui.F_MONO, false)
	_spacer(v, 4)
	_hline(v, Color("#b09a70"))
	_spacer(v, 5)

static func _note_doc(doc: Dictionary, t: Dictionary) -> Dictionary:
	var r := _root()
	var v: VBoxContainer = r["v"]
	_top(v, doc, t, INNER_W)
	var np := PanelContainer.new()
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	np.add_theme_stylebox_override("panel", _style(Color("#f0e3b9"), 1, Color("#c1aa79"), Vector4(13, 11, 13, 10), Vector2(0, 4)))
	v.add_child(np)
	var nv := _vbox(np, 0)
	if str(doc.get("salutation", "")) != "":
		_label(nv, fill(doc.get("salutation", ""), t), 14, INK, Ui.F_HAND, false)
	for sec in doc.get("sections", []):
		_label(nv, fill(sec.get("p", ""), t), 12, INK, Ui.F_HAND, true, 23.0, HORIZONTAL_ALIGNMENT_LEFT, INNER_W - 26)
		_spacer(nv, 2)
	if str(doc.get("signature", "")) != "":
		_label(nv, fill(doc.get("signature", ""), t), 13, Color("#51432e"), Ui.F_HAND, false, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	if str(doc.get("postscript", "")) != "":
		_spacer(v, 4)
		_label(v, fill(doc.get("postscript", ""), t), 8, Color("#6b5c43"), Ui.F_UI, true, 13.0, HORIZONTAL_ALIGNMENT_LEFT, INNER_W)
	_note(v, doc, t, INNER_W)
	return {"root": r["root"], "v": v}

static func _result(doc: Dictionary, t: Dictionary) -> Dictionary:
	var r := _root()
	var v: VBoxContainer = r["v"]
	_top(v, doc, t, INNER_W)
	_meta(v, doc, t, INNER_W)
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.17), 1, Color("#9d8961"), Vector4(10, 8, 10, 8)))
	v.add_child(p)
	var pv := _vbox(p, 0)
	_label(pv, "夜间批示 · " + fill(doc.get("choiceLabel", ""), t), 8, RED, Ui.F_UI_BOLD, false)
	_label(pv, fill(doc.get("result", ""), t), 10.5, Color("#463a29"), Ui.F_DOC, true, 18.0, HORIZONTAL_ALIGNMENT_LEFT, INNER_W - 22)
	_stamp_row(v, doc, t)
	_note(v, doc, t, INNER_W)
	return {"root": r["root"], "v": v}
