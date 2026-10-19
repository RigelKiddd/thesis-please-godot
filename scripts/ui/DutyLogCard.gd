class_name DutyLogCard
extends PixelPanel

## A single paper sheet for the day log.  Kept as a custom control so the
## header, red margin, stamp and ruled body can be drawn without fighting
## VBox minimum sizes.

const W := 680.0
const H := 620.0
const INK := Color("#30271b")
const MUTED := Color("#6d5a3c")

var entries: Array = []
var cb: Callable

func setup(rows: Array, callback: Callable) -> void:
	entries = rows
	cb = callback
	_build()

func _build() -> void:
	size = Vector2(W, H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP
	bg_color = Color("#efe4c4")
	bg_texture = Ui.TEX_PAPER_CARD
	border_width = 3
	border_color = Color("#1b1710")
	shadow_offset = Vector2(7, 8)
	shadow_color = Color(0, 0, 0, 0.42)
	inner_highlight = Color(1, 1, 1, 0.30)

	var bg := ColorRect.new()
	bg.color = Color("#efe4c4")
	bg.position = Vector2(3, 3)
	bg.size = Vector2(W - 6, H - 6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	var margin := ColorRect.new()
	margin.color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.62)
	margin.position = Vector2(15, 0)
	margin.size = Vector2(2, H)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var tape := ColorRect.new()
	tape.color = Color(214 / 255.0, 196 / 255.0, 151 / 255.0, 0.72)
	tape.position = Vector2(28, 0)
	tape.size = Vector2(92, 12)
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tape)

	Ui.pixel(self, "值班日志 / DUTY LOG", 31, 21, 300, 10, 7.5, MUTED)
	Ui.pixel(self, "今日批办", 31, 33, 360, 32, 27, INK, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	var total_perf := 0
	var total_fav := 0
	for e in entries:
		total_perf += int(e.get("perf", 0))
		var fav: Dictionary = e.get("favor", {})
		for k in fav:
			total_fav += int(fav[k])
	Ui.pixel(self, "已记录 %d 条  ·  绩效 %s¥%s  ·  人情净变化 %s%d" % [
		entries.size(), "+" if total_perf >= 0 else "−", Ui.fmt_money(absi(total_perf)),
		"+" if total_fav >= 0 else "−", absi(total_fav)],
		31, 70, 500, 12, 8.5, Color("#5a4a33"))
	Ui.hline(self, 30, 89, 620, Color(93 / 255.0, 75 / 255.0, 46 / 255.0, 0.38), 1)

	# Ruled paper behind the scrolling log.
	var rules := Control.new()
	rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rules)
	Ui.place(rules, 30, 96, 620, 466)
	for i in range(17):
		var line := ColorRect.new()
		line.color = Color(93 / 255.0, 75 / 255.0, 46 / 255.0, 0.075)
		line.position = Vector2(0, float(i) * 27.0)
		line.size = Vector2(620, 1)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rules.add_child(line)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 96)
	scroll.size = Vector2(620, 466)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color("#efe4c4")
	scroll.add_theme_stylebox_override("panel", flat)
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	_render_rows(list)

	var stamp := PixelPanel.new()
	stamp.bg_color = Color(0, 0, 0, 0)
	stamp.border_width = 2
	stamp.border_color = Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.78)
	stamp.rotation = deg_to_rad(-4)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp)
	Ui.place(stamp, 585, 12, 68, 70)
	Ui.pixel(stamp, "教 务 处", 0, 8, 68, 9, 6.5, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
	Ui.pixel(stamp, "值 班", 0, 24, 68, 17, 14, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.9), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
	Ui.pixel(stamp, "03", 0, 45, 68, 10, 7, Color(168 / 255.0, 58 / 255.0, 47 / 255.0, 0.86), HORIZONTAL_ALIGNMENT_CENTER)

	Ui.pixel(self, "拖动纸角移开 · Esc 关闭 · 最近 22 条", 31, 584, 440, 11, 7, MUTED)
	var close := Ui.button(self, 545, 570, 105, 32, "关闭", 10, Color("#f5e7c5"),
		Color("#91362d"), Color("#38100d"), Ui.F_UI_BOLD, Vector2(2, 2))
	close.pressed.connect(func(): cb.call("duty-close"))

func _render_rows(list: VBoxContainer) -> void:
	if entries.is_empty():
		var empty := Ui.panel(list, 0, 0, 590, 52, Color(255, 255, 255, 0.10), 0, Color(0, 0, 0, 0))
		Ui.pixel(empty, "今天还没有批办记录。", 14, 17, 560, 14, 9, MUTED)
		return
	var shown: Array = entries.slice(maxi(0, entries.size() - 22))
	var last_day := -1
	for e in shown:
		var d := int(e.get("day", 0))
		if d != last_day:
			last_day = d
			var day_label := Ui.label(list, "第 %d 天  ·  %s" % [d + 1, str(GameData.day(d).get("date", ""))],
				0, 0, 0, 15, 8, Color("#3f6b45"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
			day_label.custom_minimum_size = Vector2(590, 15)
		var kind := str(e.get("kind", ""))
		var tag := str(e.get("tag", "批"))
		var accent := Color("#3f6b45") if tag == "批" else (Color("#8b382b") if tag == "驳" else (Color("#8a5b22") if tag == "缓" else Color("#3f5f78")))
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(590, 29)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(255, 255, 255, 0.10)
		sb.border_width_left = 3
		sb.border_color = accent
		sb.content_margin_left = 7
		sb.content_margin_right = 7
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		row.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 7)
		row.add_child(h)
		var badge := Ui.panel(h, 0, 0, 20, 20, Color(accent.r, accent.g, accent.b, 0.12), 1, accent, Vector2.ZERO)
		badge.custom_minimum_size = Vector2(20, 20)
		Ui.pixel(badge, tag, 0, 0, 20, 20, 9, accent, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(text)
		var who := str(e.get("who", "记录"))
		var title := str(e.get("title", ""))
		var label := str(e.get("label", ""))
		var line1 := who
		if title != "" and title != who:
			line1 += " · " + title
		if label != "":
			line1 += " · " + label
		var l1 := Ui.label(text, line1, 0, 0, 0, 13, 8.3, INK, Ui.F_UI,
			HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
		l1.custom_minimum_size = Vector2(490, 13)
		l1.clip_text = true
		var detail := ""
		if kind == "visitor":
			detail = str(e.get("result", ""))
		elif kind == "projects":
			var counts: Dictionary = e.get("counts", {})
			detail = "排班 %d 项 · 绩效 %s¥%s" % [counts.size(), "+" if int(e.get("perf", 0)) >= 0 else "−",
				Ui.fmt_money(absi(int(e.get("perf", 0))))]
		elif kind == "audit":
			detail = "人情簿与院系账本对不上"
		if detail != "":
			var l2 := Ui.label(text, detail, 0, 0, 0, 11, 7.2, MUTED, Ui.F_UI,
				HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
			l2.custom_minimum_size = Vector2(490, 11)
			l2.clip_text = true
		list.add_child(row)
