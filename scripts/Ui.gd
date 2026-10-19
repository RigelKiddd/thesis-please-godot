class_name Ui
extends RefCounted

## Shared palette, fonts and control factories for the THESIS, PLEASE port.

const SettingsCtl := preload("res://scripts/SettingsStore.gd")

# --- palette (from the original CSS custom properties) ---
static var INK := Color("#241f17")
static var INK_SOFT := Color("#4b4233")
static var PAPER := Color("#e7dcbc")
static var PAPER_HI := Color("#f4e9c9")
static var PAPER_LO := Color("#cdbf99")
static var PAPER_DEEP := Color("#b9a97f")
static var WALL := Color("#3d4638")
static var WALL_DARK := Color("#2b3329")
static var WALL_HI := Color("#4b5544")
static var WOOD := Color("#6d4a2c")
static var WOOD_DARK := Color("#493019")
static var WOOD_HI := Color("#886137")
static var GREEN := Color("#4f7652")
static var GREEN_BRIGHT := Color("#83aa7b")
static var AMBER := Color("#b77b2e")
static var AMBER_BRIGHT := Color("#d7a34d")
static var RED := Color("#a83a2f")
static var RED_BRIGHT := Color("#cf5b46")
static var BLUE_INK := Color("#2d4d78")
static var GOLD := Color("#d8b45e")

static var F_PIXEL: Font
static var F_PIXEL_SPACED: Font
static var F_PIXEL_TITLE: Font
static var F_UI: Font
static var F_UI_BOLD: Font
static var F_DOC: Font
static var F_DOC_BOLD: Font
static var F_HAND: Font
static var F_MONO: Font
# Tiny supplemental fonts for glyphs that predate the v1.13/v1.14/v1.15 text
# subsets (仁函岚扶栋熄瑾砚钱销韩).  They are attached as Font.fallbacks.
static var F_FALLBACK_SANS: Font
static var F_FALLBACK_SANS_BOLD: Font
static var F_FALLBACK_SERIF: Font
static var F_FALLBACK_SERIF_BOLD: Font
static var F_FALLBACK_KAI: Font
static var F_FALLBACK_PIXEL: Font

static var TEX_PAPER: Texture2D
static var TEX_PAPER_HI: Texture2D
static var TEX_PAPER_CARD: Texture2D
static var TEX_DESK: Texture2D
static var TEX_WALL: Texture2D
static var TEX_FOLDER: Texture2D
static var TEX_RAIL: Texture2D
static var TEX_GRAIN: Texture2D
static var TEX_CARD: Texture2D

static func init() -> void:
	if F_PIXEL != null:
		return
	F_PIXEL = load("res://assets/fonts/ZCOOLQingKeHuangYou-400.ttf")
	F_UI = load("res://assets/fonts/NotoSansSC-400.ttf")
	F_UI_BOLD = load("res://assets/fonts/NotoSansSC-700.ttf")
	F_DOC = load("res://assets/fonts/NotoSerifSC-400.ttf")
	F_DOC_BOLD = load("res://assets/fonts/NotoSerifSC-700.ttf")
	F_HAND = load("res://assets/fonts/NotoSerifSC-400.ttf")
	F_MONO = load("res://assets/fonts/NotoSansSC-400.ttf")
	F_FALLBACK_SANS = load("res://assets/fonts/FallbackSans-400.ttf")
	F_FALLBACK_SANS_BOLD = load("res://assets/fonts/FallbackSans-700.ttf")
	F_FALLBACK_SERIF = load("res://assets/fonts/FallbackSerif-400.ttf")
	F_FALLBACK_SERIF_BOLD = load("res://assets/fonts/FallbackSerif-700.ttf")
	F_FALLBACK_KAI = load("res://assets/fonts/FallbackSerif-400.ttf")
	F_FALLBACK_PIXEL = load("res://assets/fonts/FallbackPixel-400.ttf")
	if F_FALLBACK_SANS != null:
		F_UI.fallbacks = [F_FALLBACK_SANS]
		F_MONO.fallbacks = [F_FALLBACK_SANS]
		F_PIXEL.fallbacks = [F_FALLBACK_PIXEL]
	if F_FALLBACK_SERIF != null:
		F_DOC.fallbacks = [F_FALLBACK_SERIF]
		F_DOC_BOLD.fallbacks = [F_FALLBACK_SERIF_BOLD]
	if F_FALLBACK_KAI != null:
		F_HAND.fallbacks = [F_FALLBACK_KAI]

	var spaced := FontVariation.new()
	spaced.base_font = F_PIXEL
	spaced.spacing_glyph = 1
	F_PIXEL_SPACED = spaced

	var title := FontVariation.new()
	title.base_font = F_PIXEL
	title.spacing_glyph = 2
	F_PIXEL_TITLE = title
	if F_FALLBACK_SANS != null:
		F_UI_BOLD.fallbacks = [F_FALLBACK_SANS_BOLD]
		F_PIXEL_SPACED.fallbacks = [F_FALLBACK_PIXEL]
		F_PIXEL_TITLE.fallbacks = [F_FALLBACK_PIXEL]

	for f in [F_PIXEL, F_UI, F_UI_BOLD, F_DOC, F_DOC_BOLD, F_HAND, F_MONO]:
		f.set("oversampling", 0.0)
		f.set("hinting", TextServer.HINTING_NORMAL)
		f.set("subpixel_positioning", TextServer.SUBPIXEL_POSITIONING_DISABLED)
		f.set("antialiasing", TextServer.FONT_ANTIALIASING_GRAY)
	F_PIXEL_SPACED.set("oversampling", 0.0)
	F_PIXEL_TITLE.set("oversampling", 0.0)

	TEX_PAPER = load("res://assets/textures/paper.png")
	TEX_PAPER_HI = load("res://assets/textures/paper_hi.png")
	TEX_PAPER_CARD = load("res://assets/textures/paper_card.png")
	TEX_DESK = load("res://assets/textures/desk.png")
	TEX_WALL = load("res://assets/textures/wall.png")
	TEX_FOLDER = load("res://assets/textures/folder.png")
	TEX_RAIL = load("res://assets/textures/rail.png")
	TEX_GRAIN = load("res://assets/textures/grain.png")
	TEX_CARD = load("res://assets/textures/card_paper.png")

# --- layout helpers ---

static func place(c: Control, x: float, y: float, w: float, h: float) -> Control:
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)
	c.pivot_offset = Vector2(w * 0.5, h * 0.5)
	return c

static func panel(parent: Node, x: float, y: float, w: float, h: float, bg: Color,
		border: int = 0, border_color: Color = Color.BLACK,
		shadow: Vector2 = Vector2.ZERO, shadow_color: Color = Color(0, 0, 0, 0.38),
		tex: Texture2D = null) -> PixelPanel:
	var p := PixelPanel.new()
	p.bg_color = bg
	p.bg_texture = tex
	p.border_width = border
	p.border_color = border_color
	p.shadow_offset = shadow
	p.shadow_color = shadow_color
	parent.add_child(p)
	place(p, x, y, w, h)
	return p

static func scaled_font(base: int) -> int:
	return maxi(1, int(round(float(base) * SettingsCtl.text_scale)))

static func _line_spacing(base: int) -> int:
	return maxi(0, int(round((SettingsCtl.text_scale - 1.0) * float(base) * 0.55)))

static func set_font(c: Control, base: int) -> void:
	if c == null:
		return
	c.set_meta("base_font_size", base)
	c.add_theme_font_size_override("font_size", scaled_font(base))
	c.add_theme_constant_override("line_spacing", _line_spacing(base))

static func apply_text_scale(root: Node) -> void:
	if root == null:
		return
	for n in root.find_children("*", "Control", true, false):
		if !(n is Control):
			continue
		var c: Control = n
		if c.has_meta("base_font_size"):
			var base := int(c.get_meta("base_font_size"))
			c.add_theme_font_size_override("font_size", scaled_font(base))
			c.add_theme_constant_override("line_spacing", _line_spacing(base))
		if c.has_meta("base_button_height"):
			var bh := float(c.get_meta("base_button_height"))
			var fs := float(c.get_meta("base_font_size", 12))
			c.custom_minimum_size.y = maxf(bh, fs * SettingsCtl.text_scale * 1.35)

static func label(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color = Color(0.141176, 0.121569, 0.090196), font: Font = null,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP,
		wrap: bool = false) -> Label:
	var base_size := size
	size = scaled_font(size)
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	if font == null:
		font = F_UI
	elif base_size < 14 and (font == F_PIXEL or font == F_PIXEL_SPACED):
		font = F_UI_BOLD if base_size <= 10 else F_UI
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("line_spacing", _line_spacing(base_size))
	l.add_theme_color_override("font_color", color)
	l.set_meta("base_font_size", base_size)
	l.horizontal_alignment = align
	l.vertical_alignment = valign
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.clip_text = false
	else:
		l.clip_text = false
	parent.add_child(l)
	place(l, x, y, w, h)
	return l

static func pixel(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color = Color(0.141176, 0.121569, 0.090196),
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP,
		spaced: bool = false) -> Label:
	return label(parent, text, x, y, w, h, size, color,
		F_PIXEL_SPACED if spaced else F_PIXEL, align, valign, false)

static func doc_label(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color = Color(0.141176, 0.121569, 0.090196), bold: bool = false,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP,
		wrap: bool = false) -> Label:
	return label(parent, text, x, y, w, h, size, color, F_DOC_BOLD if bold else F_DOC, align, valign, wrap)

static func line_gap(size: int, target_px: float, font: Font = null) -> int:
	if font == null:
		font = F_UI
	return max(0, int(round(target_px - font.get_height(size))))

static func label_line(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color, font: Font, target_line_px: float,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		valign: VerticalAlignment = VERTICAL_ALIGNMENT_TOP) -> Label:
	var l := label(parent, text, x, y, w, h, size, color, font, align, valign, true)
	l.add_theme_constant_override("line_spacing", line_gap(size, target_line_px, font))
	return l

static func rich(parent: Node, text: String, x: float, y: float, w: float, h: float,
		size: int, color: Color = Color(0.141176, 0.121569, 0.090196), font: Font = null,
		target_line_px: float = 0.0, wrap: bool = true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = text
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if !wrap:
		r.autowrap_mode = TextServer.AUTOWRAP_OFF
	else:
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font == null:
		font = F_UI
	if size < 14 and font == F_PIXEL:
		font = F_UI
	r.add_theme_font_override("normal_font", font)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.add_theme_font_override("bold_font", F_UI_BOLD if font == F_UI else F_DOC_BOLD)
	if target_line_px > 0.0:
		r.add_theme_constant_override("line_separation", line_gap(size, target_line_px, font))
	parent.add_child(r)
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	return r

static func vbox(parent: Node, x: float, y: float, w: float, h: float, sep: int = 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(v)
	place(v, x, y, w, h)
	return v

static func hbox(parent: Node, x: float, y: float, w: float, h: float, sep: int = 0) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", sep)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hb)
	place(hb, x, y, w, h)
	return hb

static func margin(parent: Node, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(m)
	return m

static func scroller(parent: Node, x: float, y: float, w: float, h: float) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(s)
	place(s, x, y, w, h)
	return s

static func texture(parent: Node, tex: Texture2D, x: float, y: float, w: float, h: float,
		cover: bool = false, tiled: bool = false) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tiled:
		t.stretch_mode = TextureRect.STRETCH_TILE
		t.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	elif cover:
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		t.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(t)
	place(t, x, y, w, h)
	return t

static func flat_style(bg: Color, border: int = 0, border_color: Color = Color.BLACK,
		shadow: Vector2 = Vector2.ZERO, shadow_color: Color = Color(0, 0, 0, 0.4),
		radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = border
	s.border_width_top = border
	s.border_width_right = border
	s.border_width_bottom = border
	s.border_color = border_color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.anti_aliasing = false
	if shadow != Vector2.ZERO:
		s.shadow_color = shadow_color
		s.shadow_size = 1
		s.shadow_offset = shadow
	return s

static func button(parent: Node, x: float, y: float, w: float, h: float, text: String,
		size: int = 13, color: Color = Color(0.141176, 0.121569, 0.090196), bg: Color = Color(0.956863, 0.913725, 0.788235),
		border_color: Color = Color(0.090196, 0.07451, 0.05098), font: Font = null,
		shadow: Vector2 = Vector2(3, 3)) -> Button:
	var b := Button.new()
	style_button(b, text, size, h, color, bg, border_color, font, shadow)
	parent.add_child(b)
	place(b, x, y, w, maxf(h, float(scaled_font(size)) * 1.35))
	return b

static func style_button(b: Button, text: String, size: int, h: float, color: Color, bg: Color, border_color: Color, font: Font = null, shadow: Vector2 = Vector2.ZERO) -> void:
	var base_size := size
	var base_h := h
	size = scaled_font(size)
	h = maxf(h, float(size) * 1.35)
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.set_meta("base_font_size", base_size)
	b.set_meta("base_button_height", base_h)
	if font == null:
		font = F_PIXEL
	if font == F_PIXEL and base_size < 14:
		font = F_UI_BOLD if base_size <= 10 else F_UI
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", color)
	b.add_theme_color_override("font_pressed_color", color)
	b.add_theme_color_override("font_focus_color", color)
	var normal := flat_style(bg, 3, border_color, shadow)
	var hover := flat_style(bg.lightened(0.08), 3, border_color, shadow)
	var pressed := flat_style(bg.darkened(0.06), 3, border_color, Vector2.ZERO)
	var focus := flat_style(Color(0, 0, 0, 0), 2, Color("#f0d58a"))
	focus.expand_margin_left = 2
	focus.expand_margin_top = 2
	focus.expand_margin_right = 2
	focus.expand_margin_bottom = 2
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)

static func clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

static func hline(parent: Node, x: float, y: float, w: float, color: Color, thickness: float = 1.0) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	r.position = Vector2(x, y)
	r.size = Vector2(w, thickness)
	return r

static func fmt_money(n: int) -> String:
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if neg else "") + out

