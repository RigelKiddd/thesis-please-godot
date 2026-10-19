extends "res://scripts/FlowController.gd"

## THESIS, PLEASE — 论文审批处
## A faithful Godot 4 port of the original single-file HTML game.


const AnnotationCtl := preload("res://scripts/AnnotationController.gd")
const ChatCtl := preload("res://scripts/ChatController.gd")
const PaperWindowCtl := preload("res://scripts/ui/PaperWindow.gd")
const NightCtl := preload("res://scripts/NightController.gd")
const InputRouter := preload("res://scripts/InputRouter.gd")
const Smoke := preload("res://scripts/SmokeCheck.gd")
const RequestDataCtl := preload("res://scripts/RequestData.gd")
const RequestCtl := preload("res://scripts/RequestController.gd")
const MetricsCtl := preload("res://scripts/SessionMetrics.gd")
const MaterialIconCtl := preload("res://scripts/MaterialIcon.gd")
const AllocCtl := preload("res://scripts/AllocationModel.gd")
const CollegeCtl := preload("res://scripts/CollegeModel.gd")
const AllocationViewScene := preload("res://scripts/AllocationView.gd")

var muted := false
# --- between-days allocation (v1.14) ---
var alloc_view: Control
var alloc_active := false
var alloc_visitors: Array = []
var alloc_visitor_index := 0
var alloc_choice := -1
var alloc_option: Dictionary = {}
var visitor_item := ""
var stamp_counts: Dictionary:
	get:
		return run_state.stamp_counts
	set(value):
		run_state.stamp_counts = value
var current: Dictionary:
	get:
		return run_state.current
	set(value):
		run_state.current = value

# --- v1.8 after-hours story ---
var story_scene: Dictionary:
	get:
		return run_state.story_scene
	set(value):
		run_state.story_scene = value
var story_doc: int:
	get:
		return run_state.story_doc
	set(value):
		run_state.story_doc = value
var story_choice: int:
	get:
		return run_state.story_choice
	set(value):
		run_state.story_choice = value
var story_result: Dictionary:
	get:
		return run_state.story_result
	set(value):
		run_state.story_result = value
var story_viewed: Dictionary:
	get:
		return run_state.story_viewed
	set(value):
		run_state.story_viewed = value
var night_log: Array:
	get:
		return run_state.night_log
	set(value):
		run_state.night_log = value
var favor: Dictionary:
	get:
		return run_state.favor
	set(value):
		run_state.favor = value
var college_favor: Dictionary:
	get:
		return run_state.college_favor
	set(value):
		run_state.college_favor = value


func _ready() -> void:
	desktop.archive_requested.connect(func(id: String): close_loose(id, true))
	Ui.init()
	GameData.load_all()
	SettingsStore.load_settings()
	muted = SettingsStore.muted
	ann = AnnotationCtl.new()
	chat = ChatCtl.new()
	RequestDataCtl.load_all()
	requests = RequestCtl.new(run_state)
	metrics = MetricsCtl.new()
	_setup_cursors()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_build_layers()
	_build_hud()
	_build_rules()
	_build_booth()
	_build_desk()
	_build_fx()
	_build_toast()
	_build_modal()
	_build_allocation()
	_build_ghost()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.muted = muted
	sound_btn.modulate = Color(1, 1, 1, 0.45) if muted else Color.WHITE
	SettingsStore.apply_window(get_window())

	panel_home[official_card] = official_card.position
	panel_home[folder_panel] = folder_panel.position
	panel_home[rail_panel] = rail_panel.position
	get_window().focus_exited.connect(_cancel_drag)

	day = 0
	stu = 0
	phase = "title"
	update_hud()
	render_rules()
	render_queue()
	render_tabs()
	load_student(true)
	_show_title()
	_apply_cmdline()

# ============================================================
# RENDERERS
# ============================================================
func update_hud() -> void:
	var d := GameData.day(day)
	var total := GameData.student_count(day)
	var progress: int = total if stu >= total else stu + 1
	hud_day.text = "%02d" % (day + 1)
	hud_weekday.text = str(d.get("weekday", ""))
	hud_date.text = str(d.get("date", ""))
	hud_progress.text = "%d / %d" % [min(progress, total), total]
	hud_perf.text = "¥ %s" % Ui.fmt_money(perf)
	hud_clock.text = _format_clock(clock)
	for i in range(rep_pips.size()):
		var pip: PixelPanel = rep_pips[i]
		pip.bg_color = Color("#c14b39") if rep > 0 else Color("#353b30")
		pip.border_color = Color("#5b1f19") if rep > 0 else Color("#555b4b")
		pip.inner_highlight = Color("#e9a28f") if rep > 0 else Color("#4b5142")
		pip.queue_redraw()
	if rep_value != null:
		rep_value.text = "%d/5" % rep
		rep_value.add_theme_color_override("font_color", Color("#e58a74") if rep <= 2 else Color("#f0e2c0"))
	if rep != last_rep and !rep_pips.is_empty() and is_instance_valid(rep_pips[0]):
		var seal: PixelPanel = rep_pips[0]
		seal.pivot_offset = seal.size * 0.5
		seal.scale = Vector2(1.12, 1.12)
		var tw := create_tween()
		tw.tween_property(seal, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	last_rep = rep
	get_window().title = "论文审批处 · 第 %d 天 · %s" % [day + 1, str(d.get("weekday", ""))]
	_update_request_tray()

func _format_clock(minutes: int) -> String:
	var m := ((minutes % 1440) + 1440) % 1440
	return "%02d:%02d" % [int(m / 60), m % 60]

func render_queue() -> void:
	for c in queue_root.get_children():
		c.queue_free()
	var d := GameData.day(day)
	var students: Array = d.get("students", [])
	if sticky_count_label != null:
		sticky_count_label.text = str(students.size())
	var ys := [391.0, 422.0, 453.0, 484.0]
	var rots := [-0.5, 0.45, -0.2, 0.65]
	for i in range(students.size()):
		var s: Dictionary = students[i]
		var state := ""
		if i < stu:
			state = "done"
		elif i == stu:
			state = "active"
		var bg := Color("#d8c79f")
		if state == "active":
			bg = Color("#f0e2b9")
		elif state == "done":
			bg = Color("#b7a67e")
		var p := _box(queue_root, 21, ys[i] if i < ys.size() else 391 + i * 31, 134, 28, bg, null, 2, Color("#241b10"), Vector2(2, 2))
		p.rotation = 0.0
		if state == "done":
			p.modulate.a = 0.55
		if state == "active":
			Ui.hline(p, 0, 0, 3, Ui.RED, 28)
		_pix(p, "%02d" % (i + 1), 9, 8, 10, 9, 7.5, Color("#78684a"))
		var pending_here: bool = requests.has_pending_for_student(i) if (requests != null and state != "done") else false
		_pix(p, str(s.get("name", "")), 19, 7, 86, 12, 9.5, Color("#3d3222"))
		if pending_here:
			var tag := _box(p, 101, 8, 18, 12, Color("#a83a2f"), null, 1, Color("#5e1f18"))
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_pix(tag, "待", 0, 0, 18, 12, 7, Color("#f4e3c3"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
		var dot := _box(p, 124, 9, 6, 6, Color(0, 0, 0, 0), null, 1, Color("#54462f"))
		if state == "active":
			dot.bg_color = Ui.RED
			dot.border_color = Color("#5e1f18")
		elif state == "done":
			dot.bg_color = Color("#4e6d4f")
			dot.border_color = Color("#253d26")

func render_tabs() -> void:
	if story_active:
		_render_story_tabs()
		return
	for c in tabs_root.get_children():
		c.queue_free()
	var widths := [50.0, 52.0, 52.0, 70.0, 70.0, 82.0]
	var xs := [2.0, 54.0, 108.0, 162.0, 234.0, 306.0]
	for i in range(GameData.tabs.size()):
		var t: Dictionary = GameData.tabs[i]
		var active := str(t.get("id", "")) == tab
		var y := 0.0 if active else 2.0
		var h := 23.0 if active else 21.0
		var label_h := 23.0 if active else 21.0
		var p := _box(tabs_root, xs[i], y, widths[i], h, Ui.PAPER_HI if active else Color("#c1ad80"), null, 2, Color("#2a2013"))
		p.border_widths = Vector4i(2, 2, 2, 0)
		p.pivot_offset = Vector2(widths[i] * 0.5, label_h * 0.5)
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_hover_fill(p, Ui.PAPER_HI if active else Color("#c1ad80"), Ui.PAPER_HI if active else Color("#d7c696"))
		p.set_meta("tab_id", str(t.get("id", "")))
		_pix(p, str(t.get("no", "")), 8, 4.0 if active else 3.0, 12, label_h, 7.5, Color("#856f49"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
		_pix(p, str(t.get("label", "")), 20, 0.0 if active else -1.0, widths[i] - 22, label_h, 10.5, Color("#251f15") if active else Color("#4f4129"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
		if active:
			var strip := ColorRect.new()
			strip.color = Ui.PAPER_HI
			strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tabs_root.add_child(strip)
			Ui.place(strip, xs[i], 23, widths[i], 5)
			p.scale = Vector2(1.0, 1.045)
			p.pivot_offset = Vector2(widths[i] * 0.5, h)
			var tw := create_tween()
			tw.tween_property(p, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _material_icon(parent: Control, x: float, y: float, w: float, h: float, doc: Dictionary, color: Color) -> Control:
	var icon := MaterialIconCtl.new()
	parent.add_child(icon)
	Ui.place(icon, x, y, w, h)
	icon.configure(MaterialIconCtl.key_for_doc(doc), color)
	return icon

func render_materials() -> void:
	if story_active:
		_render_story_rail()
		return
	for c in materials_box.get_children():
		materials_box.remove_child(c)
		c.queue_free()
	if rail_title != null:
		rail_title.text = "其他材料"
	var face: Dictionary = shown_face_task() if (phase == "review" or phase == "verdict") else {}
	var face_docs: Array = face.get("documents", []) if !face.is_empty() else []
	var unlocked: Array = []
	for m in GameData.materials:
		if GameData.is_material_unlocked(m, day):
			unlocked.append(m)
	var total := face_docs.size() + unlocked.size()
	material_count.text = "%d 份" % total
	if total == 0:
		materials_box.alignment = BoxContainer.ALIGNMENT_CENTER
		rail_foot_left.text = "暂无附件"
		rail_foot_right.text = ""
		var empty := _box(materials_box, 2, 120, 191, 73, Color(0, 0, 0, 0.13), null, 1, Color("#5b6952"))
		empty.custom_minimum_size = Vector2(191, 73)
		_pix(empty, "锁", 0, 14, 191, 20, 18, Color("#69775e"), HORIZONTAL_ALIGNMENT_CENTER)
		_pix(empty, "暂无附件", 0, 38, 191, 10, 8, Color("#b5bea8"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	materials_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	if !face.is_empty():
		if rail_kicker != null:
			rail_kicker.text = "ON THE SPOT / 当面提交"
		rail_foot_left.text = "当面 %d 份" % face_docs.size()
		rail_foot_right.text = "办结后归档"
		_face_group_header(face, face_docs.size())
		for i in range(face_docs.size()):
			_face_doc_card(face, face_docs[i], i)
		if !unlocked.is_empty():
			var sep := _box(materials_box, 0, 0, 198, 24, Color(0, 0, 0, 0.16), null, 1, Color("#5b6952"))
			sep.custom_minimum_size = Vector2(198, 24)
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_pix(sep, "常备附件 / STOCK", 5, 3, 188, 11, 7, Color("#b6c2a8"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
			_pix(sep, "%d 份" % unlocked.size(), 5, 13, 188, 8, 6, Color("#87977b"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
	else:
		if rail_kicker != null:
			rail_kicker.text = "SUPPLEMENTARY / 附加材料"
		rail_foot_left.text = "附加材料" if !unlocked.is_empty() else "暂无附件"
		rail_foot_right.text = ""

	for m in unlocked:
		var id := str(m.get("id", ""))
		var open := loose_files.has(id)
		var hint := ""
		match id:
			"opening": hint = "选题 · 进度"
			"advisor": hint = "评语 · 签字"
			"ethics": hint = "涉及人体" if current.get("form", {}).get("human", false) else "不适用"
			"records": hint = "学分 · 缴费"
			_: hint = str(m.get("hint", ""))
		if open:
			hint = "已展开"
		var card = MaterialCardScene.instantiate()
		materials_box.add_child(card)
		card.configure_stock(m, open, hint)

func _face_group_header(task: Dictionary, count: int = 0) -> void:
	var who := _box(materials_box, 0, 0, 198, 18, Color(0, 0, 0, 0.18), null, 1, Color("#5b6952"))
	who.custom_minimum_size = Vector2(198, 18)
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pix(who, "%s · 当面提交 · %d 份" % [str(task.get("applicant", "学生")), count], 6, 3, 186, 12, 8, Color("#e8d7b1"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
	# No drag instructions in the rail: the card itself is the affordance.

func _face_doc_card(task: Dictionary, doc: Dictionary, index: int) -> void:
	var task_id := str(task.get("id", ""))
	var doc_id := str(doc.get("id", ""))
	var cid := "req:%s:%s" % [task_id, doc_id]
	var open := loose_files.has(cid)
	var card = MaterialCardScene.instantiate()
	materials_box.add_child(card)
	card.configure_request(task, doc, index, open)

func render_stamps() -> void:
	var ids := ["pass", "revise", "reject"]
	for i in range(chip_panels.size()):
		var p: Control = chip_panels[i]
		var f: PixelPanel = chip_faces[i]
		var mark: ColorRect = chip_marks[i]
		var sel: bool = selected == str(ids[i])
		p.position.y = 2.0 if sel else 4.0
		p.rotation = 0.0 if sel else float(chip_rots[i])
		f.border_color = Color("#d9c18f") if sel else Color("#1a120c")
		f.inner_highlight = Color("#8b6a43") if sel else Color(1, 1, 1, 0.14)
		f.bg_color = chip_bgs[i]
		mark.visible = sel
		f.queue_redraw()
	if selected != "":
		var oc := Color("#456c49") if selected == "pass" else (Color("#a56a22") if selected == "revise" else Color("#9e3329"))
		var tc := Color("#3b5e40") if selected == "pass" else (Color("#8a5b21") if selected == "revise" else Color("#8b3128"))
		stamp_target.border_color = oc
		stamp_target.inner_highlight = Color(tc.r, tc.g, tc.b, 0.25)
		stamp_target_text.text = "盖「%s」" % GameData.outcome(selected).get("stamp", "")
		stamp_target_sub.text = ""

		stamp_target_text.add_theme_color_override("font_color", tc)
		Ui.set_font(stamp_target_sub, int(round(9)))
		stamp_target_sub.add_theme_color_override("font_color", Color(tc.r, tc.g, tc.b, 0.7))
	else:
		stamp_target.border_color = Color("#8c4b3c")
		stamp_target.inner_highlight = Color(0, 0, 0, 0)
		stamp_target_text.text = "拖入印章"
		stamp_target_sub.text = ""
		stamp_target_text.add_theme_color_override("font_color", Color("#7b4b3c"))
		Ui.set_font(stamp_target_sub, int(round(9)))
		stamp_target_sub.add_theme_color_override("font_color", Color("#7b4b3c"))
	stamp_target.queue_redraw()

func load_student(instant: bool = false) -> void:
	var s := GameData.student(day, stu)
	if s.is_empty():
		return
	current = s
	metrics.begin_student(day, stu, s)
	selected = ""
	stamp_selected = ""
	clear_annotations()
	chat.reset_student()
	chat_reply = -1
	_reset_stamp_target()
	clear_loose()
	tab = "cover"
	clock = 540 + stu * 105
	var o: Dictionary = s.get("official", {})
	official_name.text = str(o.get("name", ""))
	official_id.text = str(o.get("id", ""))
	official_major.text = str(o.get("major", ""))
	official_class.text = str(o.get("clazz", ""))
	official_college.text = str(o.get("college", ""))
	official_advisor.text = "%s　%s" % [str(o.get("advisor", "——")), str(o.get("advisorTitle", ""))]
	official_director.text = "%s　%s" % [str(o.get("director", "——")), str(o.get("directorTitle", ""))]
	plate_name.text = str(s.get("name", ""))
	var sid := str(s.get("id", ""))
	plate_no.text = "NO. " + sid.substr(max(0, sid.length() - 4))
	talk_meta.text = "主件6 · 附件4"
	talk_ticket.text = "A-%03d" % (day * 4 + stu + 1)
	file_no.text = "MD-2026-%04d" % (day * 4 + stu + 1)
	file_major.text = str(o.get("major", ""))
	_set_dialogue(str(s.get("line", "")), instant)
	_load_portrait()
	render_tabs()
	render_doc()
	render_materials()
	render_queue()
	render_stamps()
	update_hud()
	_start_chat()
	if phase == "review" and !story_active:
		present_for_current_student()

func _load_portrait() -> void:
	var key := "d%ds%d" % [day + 1, stu + 1]
	portrait_normal = load("res://assets/portraits/%s.png" % key)
	portrait_blink = load("res://assets/portraits/%s-blink.png" % key)
	portrait.texture = portrait_normal
	if portrait_shadow != null:
		portrait_shadow.texture = portrait_normal
	_start_blink()

func _start_blink() -> void:
	blink_gen += 1
	_blink_loop(blink_gen)

func _blink_loop(gen: int) -> void:
	while gen == blink_gen and is_inside_tree():
		await get_tree().create_timer(randf_range(4.3, 6.2)).timeout
		if gen != blink_gen or portrait == null or portrait_blink == null:
			return
		portrait.texture = portrait_blink
		if portrait_shadow != null:
			portrait_shadow.texture = portrait_blink
		await get_tree().create_timer(0.13).timeout
		if gen != blink_gen:
			return
		if portrait_normal != null:
			portrait.texture = portrait_normal
			if portrait_shadow != null:
				portrait_shadow.texture = portrait_normal

func _set_dialogue(text: String, instant: bool = false) -> void:
	type_full = text
	type_index = 0
	type_accum = 0.0
	talk_text.text = text
	talk_text.visible_characters = -1
	typing = false
	if instant:
		return
	talk_text.visible_characters = 0
	typing = true

func _chat_wait(seconds: float, gen: int) -> bool:
	var left := seconds
	while left > 0.0:
		if gen != chat_gen or chat_panel == null or !chat_panel.visible:
			return false
		if modal_open:
			await get_tree().create_timer(0.05).timeout
			continue
		left -= 0.05
		await get_tree().create_timer(0.05).timeout
	return gen == chat_gen

func _start_chat() -> void:
	chat_gen += 1
	var gen := chat_gen
	chat_reply = -1
	chat_dialogue_active = false
	chat_dialogue = {}
	chat_dialogue_choices = []
	chat_dialogue_node = ""
	for c in chat_box.get_children():
		c.queue_free()
	for b in chat_reply_btns:
		b.visible = false
		b.disabled = false
	if chat_auto_note != null:
		chat_auto_note.visible = false
	if current.is_empty():
		return
	chat_panel.visible = true
	chat_avatar.text = str(current.get("name", "生")).substr(0, 1)
	chat_status.text = "正在输入…"
	var script := ChatScript.build(current, day)
	if script.has("dialogue"):
		chat_dialogue_active = true
		chat_dialogue = script.get("dialogue", {})
		await _play_dialogue_node(str(chat_dialogue.get("start", "")), gen)
		return
	var events: Array = script.get("events", [])
	var needs_reply := bool(script.get("needs_reply", false))
	for ev in events:
		if !await _chat_wait(float(ev.get("delay", 0.5)), gen):
			return
		if str(ev.get("kind", "")) == "auto":
			chat_status.text = "自动回复…"
			_add_chat_bubble(str(ev.get("text", "")), true, true)
			chat_status.text = "正在输入…"
		else:
			_add_chat_bubble(str(ev.get("text", "")), false)
	if needs_reply:
		chat_status.text = "只能回复一次 · 提示仅一次"
		if chat_auto_note != null:
			chat_auto_note.visible = false
		var defaults := ["按清单核对", "最担心哪项？", "先放桌上"]
		_layout_chat_buttons(3)
		for i in range(chat_reply_btns.size()):
			var b: Button = chat_reply_btns[i]
			b.visible = i < 3
			if i < 3:
				b.text = defaults[i]
				b.tooltip_text = "仅一次：让学生说出最担心的一项" if i == 1 else ""
	else:
		chat_status.text = "已自动回复"
		if chat_auto_note != null:
			chat_auto_note.visible = true
			chat_auto_note.text = "已自动回复"

func _layout_chat_buttons(count: int) -> void:
	var compact := count > 3
	var w := 100 if compact else 132
	var gap := 5 if compact else 8
	for i in range(chat_reply_btns.size()):
		var b: Button = chat_reply_btns[i]
		b.position = Vector2(8 + i * (w + gap), 174)
		b.size = Vector2(w, 26)
		b.add_theme_font_size_override("font_size", 8 if compact else 9)

func _dialogue_node(node_id: String) -> Dictionary:
	for node in chat_dialogue.get("nodes", []):
		if node is Dictionary and str(node.get("id", "")) == node_id:
			return node
	return {}

func _play_dialogue_node(node_id: String, gen: int) -> void:
	var guard := 0
	while !node_id.is_empty():
		if gen != chat_gen or chat_panel == null or !chat_panel.visible:
			return
		guard += 1
		if guard > 60:
			push_warning("dialogue loop guard: " + node_id)
			_finish_dialogue()
			return
		var node := _dialogue_node(node_id)
		if node.is_empty():
			_finish_dialogue()
			return
		chat_dialogue_node = node_id
		if !await _chat_wait(float(node.get("delay", 0.55)), gen):
			return
		var speaker := str(node.get("speaker", "student"))
		var text := str(node.get("text", ""))
		if !text.is_empty():
			if speaker == "system":
				_add_chat_system(text)
			elif speaker == "player" or speaker == "me" or speaker == "teacher":
				_add_chat_bubble(text, true, false)
			elif speaker == "auto":
				_add_chat_bubble(text, true, true)
			else:
				_add_chat_bubble(text, false)
		var choices: Array = node.get("choices", [])
		if choices is Array and !choices.is_empty():
			_show_dialogue_choices(choices)
			return
		node_id = str(node.get("next", ""))
	_finish_dialogue()

func _show_dialogue_choices(choices: Array) -> void:
	chat_dialogue_choices = choices.duplicate(true)
	chat_reply = -1
	chat_status.text = "请选择回复"
	if chat_auto_note != null:
		chat_auto_note.visible = false
	var count := mini(4, chat_dialogue_choices.size())
	_layout_chat_buttons(count)
	for i in range(chat_reply_btns.size()):
		var b: Button = chat_reply_btns[i]
		b.visible = i < count
		b.disabled = false
		if i < count:
			var choice: Dictionary = chat_dialogue_choices[i]
			b.text = str(choice.get("label", "回复"))
			b.tooltip_text = str(choice.get("tooltip", ""))

func _add_chat_system(text: String) -> void:
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

func _finish_dialogue() -> void:
	chat_dialogue_choices = []
	chat_status.text = ""
	if chat_auto_note != null:
		chat_auto_note.visible = false
	for b in chat_reply_btns:
		b.visible = false

func _add_chat_bubble(text: String, mine: bool, auto: bool = false) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var keep_bottom := true
	if chat_scroll != null:
		var bar := chat_scroll.get_v_scroll_bar()
		keep_bottom = chat_scroll.scroll_vertical + chat_scroll.size.y >= bar.max_value - 26.0
	var av := _box(row, 0, 0, 20, 20, Color("#8a5b22") if mine else Color("#4e6d4f"), null, 1, Color("#1a1f18"))
	av.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_pix(av, "我" if mine else chat_avatar.text, 0, 0, 20, 20, 8, Color("#f0e6ce"), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)
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
	if auto:
		bubble.tooltip_text = "自动回复"
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", Ui.F_DOC)
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color("#2b2418"))
	l.add_theme_constant_override("line_spacing", Ui.line_gap(10, 15.0, Ui.F_DOC))
	l.custom_minimum_size.x = 262
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_child(l)
	if mine:
		row.add_child(bubble)
		row.move_child(av, 1)
	else:
		row.add_child(bubble)
	row.modulate.a = 0.0
	chat_box.add_child(row)
	var tw := create_tween()
	tw.tween_property(row, "modulate:a", 1.0, 0.16)
	await get_tree().process_frame
	if chat_scroll != null and keep_bottom:
		chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)

func _on_chat_reply(index: int) -> void:
	if chat_dialogue_active:
		_on_dialogue_choice(index)
		return
	if chat_reply != -1:
		return
	var audit := GameData.audit(current, day)
	var defects: Array = audit.get("defects", [])
	var res: Dictionary = chat.choose(index, defects)
	if res.is_empty():
		return
	chat_reply = index
	day_chat_replies.append(index)
	_click_fx(get_global_mouse_position())
	_play("select")
	for b in chat_reply_btns:
		b.visible = false
	if chat_auto_note != null:
		chat_auto_note.visible = false
	_add_chat_bubble(chat.button_label(index), true)
	chat_status.text = "已回复"
	var gen := chat_gen
	await get_tree().create_timer(0.42).timeout
	if gen != chat_gen:
		return
	_add_chat_bubble(str(res.get("line", "")), false)
	if int(res.get("time_saved", 0)) > 0:
		time_saved_total += int(res.get("time_saved", 0))
	var fmap := {}
	match str(chat.style):
		"checklist":
			fmap = {"director": 1}
		"concern":
			fmap = {"student": 1}
	var favor_bits := _favor_changes(fmap, "微信回复")
	var toast_text := str(res.get("toast", ""))
	if favor_bits != "":
		toast_text += " · 人情 " + favor_bits
	if toast_text != "":
		show_toast(toast_text, "warn" if str(res.get("tone", "")) == "warn" else "good")
	chat_status.text = "已回复"

func _on_dialogue_choice(index: int) -> void:
	if index < 0 or index >= chat_dialogue_choices.size():
		return
	if chat_reply != -1:
		return
	var choice: Dictionary = chat_dialogue_choices[index]
	var label := str(choice.get("label", "回复"))
	chat_reply = index
	day_chat_replies.append(index)
	_click_fx(get_global_mouse_position())
	_play("select")
	for b in chat_reply_btns:
		b.visible = false
	if chat_auto_note != null:
		chat_auto_note.visible = false
	_add_chat_bubble(label, true)
	chat.record_custom(label, str(choice.get("style", "")), int(choice.get("timeSaved", 0)))
	if int(choice.get("timeSaved", 0)) > 0:
		time_saved_total += int(choice.get("timeSaved", 0))
	var fmap := {}
	match str(choice.get("style", "")):
		"checklist":
			fmap = {"director": 1}
		"concern":
			fmap = {"student": 1}
	var favor_bits := _favor_changes(fmap, "微信回复")
	var toast_text := str(choice.get("toast", ""))
	if favor_bits != "":
		toast_text += " · 人情 " + favor_bits
	if toast_text != "":
		show_toast(toast_text, "warn" if str(choice.get("tone", "")) == "warn" else "good")
	chat_status.text = "已回复"
	var next := str(choice.get("next", ""))
	var gen := chat_gen
	await get_tree().create_timer(0.36).timeout
	if gen != chat_gen:
		return
	chat_dialogue_choices = []
	if !next.is_empty():
		await _play_dialogue_node(next, gen)
	else:
		_finish_dialogue()

func _first_defect() -> Dictionary:
	var au := GameData.audit(current, day)
	var ds: Array = au.get("defects", [])
	return ChatScript.primary(ds)

func _stop_chat() -> void:
	chat_gen += 1
	chat_reply = -1
	chat_dialogue_active = false
	chat_dialogue_choices = []
	for b in chat_reply_btns:
		b.visible = false
	if chat_auto_note != null:
		chat_auto_note.visible = false
	if chat_status != null:
		chat_status.text = "已记录"
	if chat_box != null and chat_box.get_child_count() == 0 and chat_panel != null:
		chat_panel.visible = false

func _process(dt: float) -> void:
	if typing:
		type_accum += dt
		while type_accum >= 0.024 and type_index < type_full.length():
			type_accum -= 0.024
			type_index += 1
			talk_text.visible_characters = type_index
		if type_index >= type_full.length():
			typing = false
			talk_text.visible_characters = -1

func render_doc() -> void:
	if story_active:
		_render_story_doc()
		return
	if current.is_empty():
		return
	for c in doc_box.get_children():
		c.queue_free()
	var view := Docs.render(tab, current, 696)
	doc_box.add_child(view)
	_animate_doc(view)
	if doc_scroll != null:
		doc_scroll.scroll_vertical = 0
	_sync_annotation_offset()
	_restore_annotations(tab)

func switch_tab(id: String) -> void:
	if phase != "review" and phase != "verdict":
		return
	if tab == id:
		return
	tab = id
	render_tabs()
	render_doc()
	_paper_flash()
	_play("tab")

# ============================================================
# FLOW
# ============================================================

func _present_modal(card: Control) -> void:
	modal_root.visible = true
	modal_open = true
	modal_root.modulate.a = 0.0
	card.modulate.a = 1.0
	card.scale = Vector2(0.96, 0.96)
	card.pivot_offset = card.custom_minimum_size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(modal_root, "modulate:a", 1.0, 0.14)
	tw.tween_property(card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_focus_modal_button(card)

func _show_modal(card: Control, paper_id: String = "") -> void:
	_cancel_drag()
	for c in modal_center.get_children():
		c.queue_free()
	if modal_loose != null:
		for c in modal_loose.get_children():
			c.queue_free()
	if modal_top != null:
		for c in modal_top.get_children():
			c.queue_free()
	if card.get_parent() != null:
		card.reparent(modal_center)
	else:
		modal_center.add_child(card)
	if paper_id == "":
		paper_id = str(card.get_meta("paper_id", "modal"))
	var pw := PaperWindowCtl.attach(card, modal_loose, paper_id)
	modal_is_help = false
	_present_modal(card)
	_apply_modal_memory.call_deferred(card, pw)

func _apply_modal_memory(card: Control, pw) -> void:
	if is_instance_valid(card) and is_instance_valid(pw) and modal_open:
		pw.apply_memory()
		pw.sync_grip()

## Visitor paperwork sits on the left so the WeChat panel and the visitor
## portrait on the right stay readable while the player fills the form.
func _show_modal_left(card: Control) -> void:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(W, H)
	wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	wrap.add_child(card)
	card.reset_size()
	if card.size.y > 620.0:
		card.size.y = 620.0
	card.position = Vector2(-12, 78)
	_show_modal(wrap)

func _focus_modal_button(card: Control) -> void:
	if card == null:
		return
	for n in card.find_children("*", "Button", true, false):
		var b := n as Button
		if b != null and b.visible and !b.disabled:
			b.grab_focus()
			return
func _hide_modal() -> void:
	InputRouter.release_focus(self)
	modal_root.visible = false
	modal_open = false
	modal_is_help = false
	modal_closable = false
	settings_modal = false
	for c in modal_center.get_children():
		c.queue_free()
	if modal_loose != null:
		for c in modal_loose.get_children():
			c.queue_free()
	if modal_top != null:
		for c in modal_top.get_children():
			c.queue_free()
	if alloc_active and alloc_view != null:
		alloc_view.visible = true

func _show_title() -> void:
	phase = "title"
	settings_modal = false
	var save_day := -1
	var save_data := GameState.read()
	var has := !save_data.is_empty()
	if has:
		save_day = int(save_data.get("day", 0))
	_show_modal(Modals.title(Callable(self, "_on_modal_action"), has, save_day), "title")

func _on_modal_action(action: String) -> void:
	_click_fx(get_global_mouse_position())
	_play("click")
	match action:
		"start":
			GameState.clear()
			_hide_modal()
			_reset_state()
			_show_day_intro()
		"continue":
			_continue_from_save()
		"begin-day":
			_begin_day()
		"close-help":
			_hide_modal()
		"favor-close":
			_hide_modal()
		"college-close":
			_hide_modal()
		"college-open":
			_hide_modal()
			_show_college_ledger()
		"open-settings":
			_open_settings()
		"settings-close":
			if phase == "title":
				_show_title()
			else:
				_hide_modal()
		"settings-scale", "settings-motion", "settings-speed", "settings-sound":
			_apply_settings_action(action)
		"ack-wrong":
			_hide_modal()
			_reset_floating_panels()
			if rep <= 0:
				_show_game_over()
			else:
				_next_student()
		"duty-close":
			_hide_modal()
		"next-day":
			_hide_modal()
			_start_night_story()
		"restart":
			GameState.clear()
			_reset_game()

func _continue_from_save() -> void:
	var d := GameState.read()
	if d.is_empty():
		show_toast("没有可用的存档", "warn")
		_show_title()
		return
	_hide_modal()
	_reset_state()
	if !GameState.apply(run_state, d):
		show_toast("存档损坏，从第一天开始", "warn")
		_show_day_intro()
		return
	show_toast("继续值班 · 第 %d 天" % (day + 1))
	_show_day_intro()

func _open_settings() -> void:
	if modal_open and !settings_modal and phase != "title":
		return
	if modal_open:
		_hide_modal()
	_show_modal(Modals.settings(_settings_state(), Callable(self, "_on_modal_action")), "settings")
	settings_modal = true
	modal_closable = true

func _settings_state() -> Dictionary:
	return {
		"scale": SettingsStore.scale_percent(),
		"text_scale": SettingsStore.text_scale_percent(),
		"portrait_shader": SettingsStore.portrait_shader,
		"reduce_motion": SettingsStore.reduce_motion,
		"text_speed": SettingsStore.speed_label(),
		"muted": muted,
		"metrics_enabled": SettingsStore.metrics_enabled,
	}

func _apply_settings_action(action: String) -> void:
	match action:
		"settings-scale":
			SettingsStore.cycle_scale(self)
			show_toast("界面缩放：%s" % SettingsStore.scale_percent())
		"settings-text":
			SettingsStore.cycle_text_scale()
			Ui.apply_text_scale(self)
			show_toast("字号：%s" % SettingsStore.text_scale_percent())
		"settings-portrait":
			var on := SettingsStore.toggle_portrait_shader()
			portrait.material = portrait_shader_mat if on else null
			show_toast("立绘 shader：%s" % ("开" if on else "关"))
		"settings-motion":
			SettingsStore.toggle_motion()
			show_toast("减少震动/闪光：%s" % ("开启" if SettingsStore.reduce_motion else "关闭"))
		"settings-speed":
			SettingsStore.cycle_text_speed()
			show_toast("文字速度：%s" % SettingsStore.speed_label())
		"settings-metrics":
			var on := SettingsStore.toggle_metrics()
			if !on:
				metrics.reset()
			show_toast("本地记录：%s" % ("开启" if on else "关闭"))
		"settings-sound":
			muted = !muted
			SettingsStore.muted = muted
			SettingsStore.save_settings()
			if sfx != null:
				sfx.muted = muted
			sound_btn.modulate = Color(1, 1, 1, 0.45) if muted else Color.WHITE
			show_toast("音效：%s" % ("关" if muted else "开"))
	_open_settings()

func _reset_state() -> void:
	_close_request_paper()
	_abort_allocation()
	run_state.reset()
	selected = ""
	ann.reset()
	chat.reset_student()
	requests.reset()
	request_resume_end = false
	_set_story_visual(false)
	clear_loose()
	_reset_stamp_target()
	update_hud()
	render_rules()
	render_queue()
	render_tabs()
	load_student(true)

func _reset_game() -> void:
	_hide_modal()
	metrics.record_restart()
	metrics.reset()
	_reset_state()
	_show_title()

func _abort_allocation() -> void:
	if alloc_view != null:
		alloc_view.close()
	set_allocation_chrome(false)
	alloc_active = false
	alloc_visitors = []
	alloc_visitor_index = 0
	alloc_choice = -1
	alloc_option = {}
	if phase == "allocate":
		run_state.energy = 0
		run_state.money = 0
		run_state.alloc_placed.clear()
		run_state.alloc_offer = {}

func _on_help_btn() -> void:
	_click_fx(get_global_mouse_position())
	_play("click")
	_show_help()


func _build_allocation() -> void:
	alloc_view = AllocationViewScene.new()
	layer_alloc.add_child(alloc_view)
	Ui.place(alloc_view, 0, 0, W, H)
	alloc_view.configure(run_state, Callable(self, "_play"), Callable(self, "show_toast"))
	alloc_view.finish_requested.connect(_finish_allocation)
	alloc_view.ledger_requested.connect(_show_favor_ledger)
	alloc_view.college_requested.connect(_show_college_ledger)
	alloc_view.visitor_option_chosen.connect(func(index: int): _on_visitor_action("visitor:%d" % index))
	alloc_view.visitor_item_attached.connect(_on_visitor_item_attached)
	alloc_view.visitor_item_cleared.connect(_on_visitor_item_cleared)
	alloc_view.visitor_next_requested.connect(func(): _on_visitor_action("visitor-next"))
	alloc_view.duty_log_requested.connect(_open_duty_log)
	alloc_view.visible = false

func _open_duty_log() -> void:
	if modal_open and !settings_modal and !modal_is_help:
		return
	if modal_open:
		_hide_modal()
	if alloc_active and alloc_view != null:
		alloc_view.visible = false
	for c in modal_top.get_children():
		c.queue_free()
	var card := Modals.duty_log(_state_dict(), run_state.duty_log, Callable(self, "_on_modal_action"))
	card.position = Vector2((W - card.custom_minimum_size.x) * 0.5, (H - card.custom_minimum_size.y) * 0.5)
	modal_top.add_child(card)
	PaperWindowCtl.attach(card, modal_top, "duty")
	card.pivot_offset = card.custom_minimum_size * 0.5
	card.modulate.a = 0.0
	card.scale = Vector2(0.985, 0.985)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.14)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	modal_root.visible = true
	modal_root.modulate.a = 1.0
	modal_open = true
	modal_is_help = false
	modal_closable = true
	settings_modal = false
	_play("tab")

func _show_help() -> void:
	if modal_open or (phase != "review" and phase != "verdict" and phase != "story" and phase != "allocate"):
		return
	_show_modal(Modals.help(Callable(self, "_on_modal_action")), "help")
	modal_is_help = true

func _state_dict() -> Dictionary:
	return {
		"day": day,
		"stu": stu,
		"perf": perf,
		"rep": rep,
		"daily_correct": daily_correct,
		"daily_wrong": daily_wrong,
		"total_correct": total_correct,
		"total_wrong": total_wrong,
		"perfect_days": perfect_days,
		"day_start_perf": day_start_perf,
		"clock": clock,
		"stamp_counts": stamp_counts.duplicate(),
		"night_log": night_log.duplicate(true),
		"story_active": story_active,
		"annotation_count": day_annotation_count,
		"chat_replies": day_chat_replies.duplicate(),
		"annotations": ann.attempt_log(),
		"chat_style": chat.style,
		"chat_line": chat.summary_line(),
		"time_saved": time_saved_total,
		"annotation_hits": annotation_hits,
		"annotation_wrong": annotation_wrong,
		"annotation_missed": annotation_missed,
		"request_pending": requests.pending_count() if requests != null else 0,
		"request_total": requests.total_count() if requests != null else 0,
		"request_done": requests.done_count() if requests != null else 0,
		"face_task": str(face_task().get("title", "")) if !story_active else "",
		"face_pending": face_pending() if !story_active else false,
		"favor": favor.duplicate(true),
		"favor_total": AllocCtl.favor_total(favor),
		"favor_line": AllocCtl.favor_line(favor),
		"favor_note": _favor_note(),
		"favor_today": _favor_today(),
		"energy": int(run_state.energy),
		"money": int(run_state.money),
		"alloc_log": run_state.alloc_log.duplicate(true),
		"duty_log": run_state.duty_log.duplicate(true),
		"week_line": _week_line(),
		"college_favor": run_state.college_favor.duplicate(true),
		"college_line": CollegeCtl.summary(run_state.college_favor),
		"college_note": _college_note(),
		"college_log": run_state.college_log.duplicate(true),
	}

func _week_line() -> String:
	var bits: Array = []
	for d in range(7):
		var visits := 0
		var day_perf := 0
		var tags: Array = []
		for e in run_state.duty_log:
			if int(e.get("day", -1)) != d:
				continue
			if str(e.get("kind", "")) == "visitor":
				visits += 1
				var tag := str(e.get("tag", ""))
				if tag != "" and !tags.has(tag):
					tags.append(tag)
			elif str(e.get("kind", "")) == "projects":
				day_perf += int(e.get("perf", 0))
		if visits == 0 and day_perf == 0:
			continue
		var bit := "第%d天 来访%d" % [d + 1, visits]
		if day_perf != 0:
			bit += " · 排班¥%s" % Ui.fmt_money(day_perf)
		if !tags.is_empty():
			bit += " · " + "".join(PackedStringArray(tags))
		bits.append(bit)
	return " ｜ ".join(PackedStringArray(bits))

func stamp_decision() -> void:
	if phase != "review":
		return
	if face_pending():
		show_toast(face_block_message(), "warn")
		_shake()
		_open_request()
		return
	if _loose_over_rect(stamp_target.get_global_rect()):
		show_toast("材料压住印章台，先收起再盖章", "warn")
		_shake()
		return
	_stop_chat()
	_set_annotation_mode(false)
	if selected == "":
		show_toast("先选印章", "warn")
		_shake()
		_play("click")
		return
	if current.is_empty():
		return
	var audit := GameData.audit(current, day)
	var chosen := selected
	var expected := str(audit.get("expected", "pass"))
	var correct := chosen == expected
	run_state.record_decision(current, chosen, correct)
	var hits_before := annotation_hits
	var wrong_before := annotation_wrong
	var missed_before := annotation_missed
	_record_annotation_stats()
	var empty_circles := 0
	for a in ann.attempts:
		if !bool(a.get("hit", false)):
			empty_circles += 1
	metrics.finish_student(correct, annotation_hits - hits_before, annotation_wrong - wrong_before,
		annotation_missed - missed_before, empty_circles, chat.asked, chat.style)
	phase = "verdict"
	last_audit = audit
	last_outcome = chosen
	stamp_counts[chosen] = int(stamp_counts.get(chosen, 0)) + 1
	var stamp_color := Color("#3f6b45") if chosen == "pass" else (Color("#9a641e") if chosen == "revise" else Color("#9b3127"))
	_stamp_burst(stamp_target.get_global_rect().get_center(), stamp_color)
	_show_stamp_mark(chosen)
	_flash()
	_shake()
	_play("stamp")
	if correct:
		perf += 120
		daily_correct += 1
		total_correct += 1
		update_hud()
		var favor_bits := _favor_changes({"student": 1}, "审查")
		var college_bits := ""
		if chosen == "pass":
			college_bits = _college_pass(current, true)
		var txt := ""
		if chosen == "pass":
			txt = "通过 +¥120"
		elif chosen == "revise":
			txt = "退回修改 +¥120"
		else:
			txt = "不通过 +¥120"
		if favor_bits != "":
			txt += " · 人情 " + favor_bits
		if college_bits != "":
			txt += " · " + college_bits
		show_toast(txt, "good")
		_play("correct")
		_after_stamp(true, audit, chosen)
	else:
		perf -= 80
		daily_wrong += 1
		total_wrong += 1
		rep = max(0, rep - 1)
		update_hud()
		var favor_bits := _favor_changes({"student": -2, "director": -1}, "误判投诉")
		var college_bits := ""
		if chosen == "pass":
			college_bits = _college_pass(current, false)
		var bad := "误判"
		if favor_bits != "":
			bad += "：人情 " + favor_bits
		if college_bits != "":
			bad += " · " + college_bits
		show_toast(bad, "warn")
		_play("wrong")
		metrics.record_complaint()
		_after_stamp(false, audit, chosen)

func _record_annotation_stats() -> void:
	var au := GameData.audit(current, day)
	var defects: Array = au.get("defects", [])
	var keys := {}
	for d in defects:
		keys[AnnotationCtl.key_for(d)] = true
	var hits := 0
	var wrong := 0
	for m in ann.all_marks():
		if keys.has(AnnotationCtl.key_for(m)):
			hits += 1
		else:
			wrong += 1
	annotation_hits += hits
	annotation_wrong += wrong
	annotation_missed += maxi(0, defects.size() - hits)

func _after_stamp(correct: bool, audit: Dictionary, chosen: String) -> void:
	await get_tree().create_timer(1.55 if correct else 0.64).timeout
	if phase != "verdict":
		return
	if correct:
		_next_student()
	else:
		phase = "wrong"
		_show_modal(Modals.complaint(current, audit, chosen, _state_dict(), Callable(self, "_on_modal_action")), "complaint")

func _show_stamp_mark(chosen: String) -> void:
	Ui.clear(stamp_mark_holder)
	stamp_target_text.visible = false
	if stamp_target_sub != null:
		stamp_target_sub.visible = false
	var oc := Color("#3f6b45") if chosen == "pass" else (Color("#9a641e") if chosen == "revise" else Color("#9b3127"))
	stamp_target.border_color = oc
	var halo := PixelPanel.new()
	halo.bg_color = Color(0, 0, 0, 0)
	halo.border_width = 3
	halo.border_color = Color(oc.r, oc.g, oc.b, 0.18)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp_mark_holder.add_child(halo)
	Ui.place(halo, 59, 11, 180, 46)
	halo.rotation = deg_to_rad(-2.5)
	var p := PixelPanel.new()
	p.bg_color = Color(0, 0, 0, 0)
	p.border_width = 4
	p.border_color = oc
	p.pivot_offset = Vector2(90, 23)
	p.scale = Vector2(1.18, 1.18)
	p.inner_highlight = Color(oc.r, oc.g, oc.b, 0.2)
	stamp_mark_holder.add_child(p)
	Ui.place(p, 56, 8, 180, 46)
	p.rotation = deg_to_rad(-5)
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var inner := PixelPanel.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.border_width = 1
	inner.border_color = oc
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(inner)
	Ui.place(inner, 4, 4, 172, 38)
	var out := GameData.outcome(chosen)
	Ui.label(p, str(out.get("stamp", "")), 1, 2, 180, 27, 25, Color(oc.r, oc.g, oc.b, 0.3), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	Ui.label(p, str(out.get("stamp", "")), 0, 1, 180, 27, 25, oc, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	Ui.label(p, str(out.get("sub", "")), 0, 27, 180, 9, 7, oc, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	Ui.label(p, "教务处 · 2026.05.11", 0, 36, 180, 8, 6, Color(oc.r, oc.g, oc.b, 0.78), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP, false)
	# a little dry-ink speckle on the frame
	var specks := [Vector2(17, 20), Vector2(161, 16), Vector2(30, 39), Vector2(147, 37), Vector2(92, 3), Vector2(96, 43), Vector2(8, 31), Vector2(171, 30)]
	for s in specks:
		var dot := ColorRect.new()
		dot.color = Color(oc.r, oc.g, oc.b, 0.28)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(dot)
		Ui.place(dot, s.x, s.y, 2, 2)
	stamp_target.queue_redraw()

func _reset_stamp_target() -> void:
	if stamp_mark_holder != null:
		Ui.clear(stamp_mark_holder)
	if stamp_target_text != null:
		stamp_target_text.visible = true
		stamp_target_text.text = "拖入印章"
		stamp_target_text.add_theme_color_override("font_color", Color("#7b4b3c"))
	if stamp_target_sub != null:
		stamp_target_sub.visible = true
		stamp_target_sub.text = ""
		Ui.set_font(stamp_target_sub, int(round(9)))
		stamp_target_sub.add_theme_color_override("font_color", Color("#7b4b3c"))
	if stamp_target != null:
		stamp_target.border_color = Color("#8c4b3c")
		stamp_target.inner_highlight = Color(0, 0, 0, 0)
		stamp_target.queue_redraw()


# ============================================================
# AFTER HOURS / NIGHT STORY (v1.8)
# ============================================================
func _night_scene() -> Dictionary:
	if day >= 0 and day < GameData.night_scenes.size():
		return GameData.night_scenes[day]
	return {}

func _story_tokens() -> Dictionary:
	var s := GameData.student(day, GameData.student_count(day) - 1)
	var o: Dictionary = s.get("official", {})
	var out := GameData.outcome(last_outcome)
	var d := GameData.day(day)
	return {
		"student": str(s.get("name", "一位学生")),
		"studentId": str(s.get("id", "")),
		"major": str(o.get("major", "")),
		"verdict": str(out.get("stamp", "—")),
		"verdictLabel": str(out.get("label", "—")),
		"date": str(d.get("date", "")),
		"shortDate": str(d.get("shortDate", "")),
		"weekday": str(d.get("weekday", "")),
		"day": str(day + 1),
	}

func _story_fill(value: Variant) -> String:
	return StoryDocs.fill(value, _story_tokens())

func _story_docs() -> Array:
	var docs: Array = StoryDocs.docs(story_scene, {})
	var sender := chat_student if !chat_student.is_empty() else _last_student()
	var extra := NightCtl.extra_docs(chat, sender, _story_tokens())
	docs.append_array(extra)
	docs.append_array(NightCtl.college_letters(run_state.night_letters, run_state.college_favor, _story_tokens()))
	if !story_result.is_empty():
		docs.append(story_result)
	return docs

func _last_student() -> Dictionary:
	return GameData.student(day, GameData.student_count(day) - 1)

func _start_night_story() -> void:
	var scene := _night_scene()
	if scene.is_empty():
		return
	_hide_modal()
	clear_loose()
	_close_request_paper()
	phase = "story"
	stu = GameData.student_count(day)
	selected = ""
	stamp_selected = ""
	clock = 17 * 60 + 20 + day * 30
	story_active = true
	story_scene = scene
	story_doc = 0
	story_choice = -1
	story_result = {}
	run_state.night_letters = run_state.college_letters.duplicate()
	run_state.college_letters.clear()
	story_viewed = {0: true}
	_set_story_visual(true)
	update_hud()
	_update_request_tray()
	render_queue()
	render_tabs()
	render_doc()
	render_materials()
	_render_story_console()
	show_toast(_story_fill(scene.get("intro", "")), "")
	_play("page")

func _set_story_visual(on: bool) -> void:
	if story_console == null:
		return
	story_console.visible = on
	if night_label != null:
		night_label.visible = on
	if verdict_dock != null:
		verdict_dock.visible = !on
	if stamp_target != null:
		stamp_target.visible = !on
	if stamp_mark_holder != null:
		stamp_mark_holder.visible = !on
	if annotate_plate != null:
		annotate_plate.visible = !on
	if annotate_btn != null:
		annotate_btn.visible = !on
	if annotation_guard != null:
		annotation_guard.visible = false
	_set_annotation_mode(false)
	if on:
		clear_annotations()
	if chat_panel != null:
		chat_panel.visible = !on
	if talk_bubble != null:
		talk_bubble.visible = on
	if talk_label != null:
		talk_label.visible = on
	if on:
		chat_gen += 1
		for b in chat_reply_btns:
			b.visible = false
	if on:
		layer_rules.modulate = Color(0.72, 0.72, 0.72, 0.62)
		official_card.modulate = Color(0.75, 0.75, 0.75, 0.52)
		booth_sign.modulate = Color(0.75, 0.75, 0.75, 0.52)
		talk_bubble.modulate = Color(0.9, 0.9, 0.9, 0.75)
		talk_label.modulate = Color(0.85, 0.85, 0.85, 0.72)
		if desk_left != null:
			desk_left.modulate = Color(0.68, 0.68, 0.68, 0.46)
		rail_kicker.text = "AFTER HOURS / 夜班"
		rail_title.text = "桌上文件"
		talk_label.text = "夜班记录"
		talk_text.text = _story_fill(story_scene.get("intro", ""))
		talk_text.visible_characters = -1
		typing = false
		talk_meta.text = "第 %d 夜 · %s" % [day + 1, str(GameData.day(day).get("weekday", ""))]
		talk_ticket.text = "大"
		file_no.text = "NT-2026-%02d" % (day + 1)
		file_major.text = "夜班文件"
	else:
		layer_rules.modulate = Color.WHITE
		official_card.modulate = Color.WHITE
		booth_sign.modulate = Color.WHITE
		talk_bubble.modulate = Color.WHITE
		talk_label.modulate = Color.WHITE
		if desk_left != null:
			desk_left.modulate = Color.WHITE
		rail_kicker.text = "SUPPLEMENTARY / 附加材料"
		rail_title.text = "其他材料"

func _clear_story_mode() -> void:
	story_active = false
	story_choice = -1
	story_result = {}
	story_scene = {}
	story_doc = 0
	story_viewed = {}
	run_state.night_letters.clear()
	_set_story_visual(false)
	_update_request_tray()
	phase = "dayend"

func _on_story_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_open_story_doc(index)
			get_viewport().set_input_as_handled()

func _open_story_doc(index: int) -> void:
	if !story_active:
		return
	var docs := _story_docs()
	if index < 0 or index >= docs.size():
		return
	story_doc = index
	story_viewed[index] = true
	_render_story_tabs()
	_render_story_doc()
	_render_story_rail()
	_render_story_console()
	_paper_flash()
	_play("tab")

func _on_story_choice(index: int) -> void:
	if !story_active or story_choice != -1:
		return
	_click_fx(get_global_mouse_position())
	var options: Array = story_scene.get("choice", {}).get("options", [])
	if index < 0 or index >= options.size():
		return
	var opt: Dictionary = options[index]
	story_choice = index
	perf += int(opt.get("perf", 0))
	rep = clampi(rep + int(opt.get("rep", 0)), 0, 5)
	night_log.append(NightCtl.log_entry(day, _story_fill(opt.get("label", "")), str(opt.get("tone", ""))))
	story_result = {
		"id": "n%d-result" % (day + 1),
		"tab": "批示",
		"icon": "批",
		"badge": "夜间批示",
		"kind": "result",
		"kicker": "03号窗口 / NIGHT DECISION",
		"officeLeft": "教务处 · 夜间值班",
		"officeRight": "{{date}}",
		"title": "夜间批示记录",
		"subtitle": "NIGHT DECISION / FILED",
		"meta": [
			{"k": "日期", "v": "{{date}}"},
			{"k": "批示", "v": str(opt.get("label", ""))},
			{"k": "经办", "v": "周明远"},
			{"k": "状态", "v": "已归档"},
		],
		"result": str(opt.get("result", "")),
		"choiceLabel": str(opt.get("label", "")),
		"signature": "周明远",
		"seal": "已阅",
		"sealSub": "归档",
		"stamp": "已签阅",
		"note": "本记录随当日材料一并归档。",
	}
	story_doc = _story_docs().size() - 1
	story_viewed[story_doc] = true
	update_hud()
	_render_story_tabs()
	_render_story_doc()
	_render_story_rail()
	_render_story_console()
	var favor_bits := _favor_changes(opt.get("favor", {}), "夜班批示")
	show_toast("夜间批示：%s%s" % [_story_fill(opt.get("label", "")), (" · 人情 " + favor_bits) if favor_bits != "" else ""], "warn" if str(opt.get("tone", "")) == "warn" else "good")
	_play("stamp")

func _finish_night_story() -> void:
	if !story_active or story_choice == -1:
		return
	_click_fx(get_global_mouse_position())
	var final := day >= GameData.days.size() - 1
	if rep <= 0:
		_show_game_over()
		return
	if final:
		_show_ending()
		return
	_clear_story_mode()
	_start_allocation()
	_play("day")

# ============================================================
# BETWEEN DAYS / ALLOCATION (v1.14)
# ============================================================
func _alloc_tokens() -> Dictionary:
	var d := GameData.day(day)
	var last := GameData.student(day, GameData.student_count(day) - 1)
	return {
		"lastStudent": str(last.get("name", "学生")),
		"day": str(day + 1),
		"nextDay": str(day + 2),
		"date": str(d.get("date", "")),
		"weekday": str(d.get("weekday", "")),
	}

func _filled_visitor(v: Dictionary) -> Dictionary:
	var out := v.duplicate(true)
	var tokens := _alloc_tokens()
	out["name"] = AllocCtl.fill(str(out.get("name", "")), tokens)
	out["title"] = AllocCtl.fill(str(out.get("title", "")), tokens)
	out["ask"] = AllocCtl.fill(str(out.get("ask", "")), tokens)
	var story: Array = []
	for para in out.get("story", []):
		story.append(AllocCtl.fill(str(para), tokens))
	var hist: Dictionary = run_state.visitor_history.get(str(out.get("role", "")), {})
	if !hist.is_empty() and int(hist.get("day", -1)) < day:
		var tag := str(hist.get("tag", "批"))
		var prior := str(hist.get("label", ""))
		if prior == "":
			prior = tag
		story.insert(0, "上次（第 %d 天）你%s了「%s」。这次他先把上次的回执放在桌角。" % [
			int(hist.get("day", 0)) + 1, tag, prior])
	out["story"] = story
	var options: Array = []
	for opt in out.get("options", []):
		var row: Dictionary = opt.duplicate(true)
		row["label"] = AllocCtl.fill(str(row.get("label", "")), tokens)
		row["result"] = AllocCtl.fill(str(row.get("result", "")), tokens)
		options.append(row)
	out["options"] = options
	return out

func _visitor_display_name(v: Dictionary) -> String:
	var name := str(v.get("name", ""))
	if name.strip_edges() == "":
		name = str(AllocCtl.role(str(v.get("role", ""))).get("name", "来人"))
	return name

func _alloc_state() -> Dictionary:
	return {
		"energy": int(run_state.energy),
		"money": int(run_state.money),
		"favor": run_state.favor,
		"day": day,
		"clock": clock,
		"date": str(GameData.day(day).get("date", "")),
	}

func _start_allocation() -> void:
	if alloc_active:
		return
	if day >= GameData.days.size() - 1:
		_show_ending()
		return
	if AllocCtl.projects().is_empty() or AllocCtl.roles().is_empty():
		# Content build failed or an old data.json is loaded; never trap the player.
		day += 1
		_show_day_intro()
		return
	_hide_modal()
	clear_loose()
	_close_request_paper()
	alloc_active = true
	alloc_visitors = AllocCtl.requested_visitors(day)
	alloc_visitor_index = 0
	alloc_choice = -1
	alloc_option = {}
	visitor_item = ""
	phase = "allocate"
	clock = 21 * 60 + 10 + day * 5
	AllocCtl.begin(run_state, day)
	alloc_view.open(day, GameData.day(day))
	update_hud()
	_update_request_tray()
	render_queue()
	set_allocation_chrome(true)
	if alloc_visitors.is_empty():
		if alloc_view != null:
			alloc_view.clear_visitor("今晚没人来")
		show_toast("今晚没人来。")
	else:
		_show_visitor(0)

func _on_visitor_item_attached(id: String) -> void:
	if !alloc_active or alloc_choice != -1:
		return
	visitor_item = id


func _on_visitor_item_cleared() -> void:
	if !alloc_active or alloc_choice != -1:
		return
	visitor_item = ""


func _show_visitor(index: int, keep_item: bool = false) -> void:
	if index < 0 or index >= alloc_visitors.size():
		return
	alloc_visitor_index = index
	alloc_choice = -1
	alloc_option = {}
	if !keep_item:
		visitor_item = ""
	var v := _filled_visitor(alloc_visitors[index])
	var role := AllocCtl.role(str(v.get("role", "")))
	var display := _visitor_display_name(v)
	if alloc_view != null:
		alloc_view.show_visitor(v, role, display, index + 1, alloc_visitors.size(),
			_alloc_state(), run_state.items, visitor_item)

func _on_visitor_action(action: String) -> void:
	if action.begins_with("visitor-item:"):
		if alloc_choice != -1:
			return
		visitor_item = action.substr(13)
		_show_visitor(alloc_visitor_index, true)
		return
	if action.begins_with("visitor:"):
		if alloc_choice != -1:
			return
		if alloc_visitor_index < 0 or alloc_visitor_index >= alloc_visitors.size():
			return
		var v := _filled_visitor(alloc_visitors[alloc_visitor_index])
		var options: Array = v.get("options", [])
		var idx := int(action.substr(8))
		if idx < 0 or idx >= options.size():
			return
		var opt: Dictionary = options[idx]
		if !AllocCtl.can_afford(opt, int(run_state.energy), int(run_state.money)):
			show_toast("精力或金钱不够，换一种批法", "warn")
			return
		var effective := _visitor_opt_with_item(opt, v)
		alloc_choice = idx
		alloc_option = effective
		_click_fx(get_global_mouse_position())
		_play("select")
		_apply_effect(effective, "来访 · " + str(v.get("title", "")))
		if str(opt.get("tag", "")) == "缓":
			run_state.add_item({
				"id": "pass_%d_%d" % [day, alloc_visitor_index],
				"kind": "pass",
				"title": "临时通行条",
				"sub": "PASS",
				"style": "carbonless",
				"icon": "ticket",
				"stock": "CARBONLESS",
				"stock_cn": "无碳",
				"day": day,
				"consumable": true,
				"submit_favor": 1,
				"submit_perf": 20,
			})
		var submitted: Dictionary = effective.get("submitted", {})
		if !submitted.is_empty() and bool(submitted.get("consumable", false)):
			run_state.remove_item(str(submitted.get("id", "")))
		var vtag := str(effective.get("tag", "批"))
		run_state.log_duty({
			"kind": "visitor",
			"who": _visitor_display_name(v),
			"role": str(v.get("role", "")),
			"title": str(v.get("title", "")),
			"tag": vtag,
			"label": str(effective.get("label", "")),
			"result": str(effective.get("result", "")),
			"perf": int(effective.get("perf", 0)),
			"favor": effective.get("favor", {}).duplicate(true),
			"item": str(submitted.get("title", "")),
		})
		run_state.visitor_history[str(v.get("role", ""))] = {
			"day": day,
			"tag": vtag,
			"label": str(effective.get("label", "")),
			"result": str(effective.get("result", "")),
			"visitor": str(v.get("id", "")),
			"note": str(submitted.get("note", "")),
		}
		visitor_item = ""
		alloc_view.refresh()
		update_hud()
		var is_last := alloc_visitor_index >= alloc_visitors.size() - 1
		var role := AllocCtl.role(str(v.get("role", "")))
		if alloc_view != null:
			alloc_view.show_visitor_result(v, role, _visitor_display_name(v), effective,
				alloc_visitor_index + 1, alloc_visitors.size(), is_last, _alloc_state())
		return
	if action == "visitor-next":
		visitor_item = ""
		var next_index := alloc_visitor_index + 1
		if next_index < alloc_visitors.size():
			_show_visitor(next_index)
		else:
			alloc_visitors = []
			alloc_visitor_index = 0
			if alloc_view != null:
				alloc_view.clear_visitor("来访结束")
			show_toast("来访结束。")
		return

func _visitor_opt_with_item(opt: Dictionary, v: Dictionary) -> Dictionary:
	var merged := opt.duplicate(true)
	if visitor_item == "":
		return merged
	var item := run_state.item_of(visitor_item)
	if item.is_empty():
		visitor_item = ""
		return merged
	var rid := str(v.get("role", ""))
	var fav: Dictionary = merged.get("favor", {}).duplicate(true)
	fav[rid] = clampi(int(fav.get(rid, 0)) + int(item.get("submit_favor", 1)), -10, 10)
	merged["favor"] = fav
	merged["perf"] = int(merged.get("perf", 0)) + int(item.get("submit_perf", 20))
	merged["submitted"] = item.duplicate(true)
	return merged

func _finish_allocation() -> void:
	if !alloc_active:
		return
	if !alloc_visitors.is_empty() and alloc_visitor_index < alloc_visitors.size():
		_show_visitor(alloc_visitor_index)
		return
	if AllocCtl.remaining(run_state) > 0:
		show_toast("还有硬币没放完", "warn")
		return
	var effects := AllocCtl.project_effects(run_state.alloc_placed)
	var favor_bits := _favor_changes(effects.get("favor", {}), "排班")
	var flat := AllocCtl.flat_perf(favor)
	perf += int(effects.get("perf", 0)) + flat
	rep = clampi(rep + int(effects.get("rep", 0)), 0, 5)
	run_state.alloc_log.append({
		"day": day,
		"projects": effects.get("counts", {}).duplicate(true),
		"favor": effects.get("favor", {}).duplicate(true),
		"perf": int(effects.get("perf", 0)) + flat,
		"rep": int(effects.get("rep", 0)),
	})
	run_state.log_duty({
		"kind": "projects",
		"who": "排班",
		"title": "明日安排",
		"tag": "排",
		"label": "排班完成",
		"perf": int(effects.get("perf", 0)) + flat,
		"rep": int(effects.get("rep", 0)),
		"counts": effects.get("counts", {}).duplicate(true),
	})
	var fav_total := 0
	for k in run_state.favor:
		fav_total += int(run_state.favor[k])
	var college_total := 0
	for k in run_state.college_favor:
		var ce = run_state.college_favor[k]
		if typeof(ce) == TYPE_DICTIONARY:
			college_total += int(ce.get("advisor", 0)) + int(ce.get("director", 0))
		else:
			college_total += int(ce)
	if fav_total >= 4 and absi(fav_total - college_total) >= 5:
		run_state.log_duty({
			"kind": "audit",
			"who": "对账",
			"title": "账本核对",
			"tag": "疑",
			"label": "人情簿 %d / 院系账本 %d，两边对不上" % [fav_total, college_total],
			"perf": 0,
		})
		show_toast("对账：人情簿与院系账本对不上。", "warn")
	alloc_active = false
	alloc_visitors = []
	alloc_visitor_index = 0
	alloc_choice = -1
	alloc_option = {}
	alloc_view.close()
	set_allocation_chrome(false)
	_hide_modal()
	update_hud()
	_play("day")
	var summary := "排班完成：绩效 +¥%s" % Ui.fmt_money(int(effects.get("perf", 0)) + flat)
	if favor_bits != "":
		summary += " · " + favor_bits
	if int(effects.get("rep", 0)) != 0:
		summary += " · 声誉 +%d" % int(effects.get("rep", 0))
	show_toast(summary, "good")
	if rep <= 0:
		_show_game_over()
		return
	day += 1
	update_hud()
	_show_day_intro()

func _alloc_ready() -> bool:
	return alloc_active and AllocCtl.remaining(run_state) == 0

func _show_favor_ledger() -> void:
	if modal_open:
		return
	if phase != "review" and phase != "verdict" and phase != "allocate":
		return
	_click_fx(get_global_mouse_position())
	_play("page")
	if alloc_active:
		alloc_view.open_item("favor")
		return
	_show_modal(Modals.favor_ledger(AllocCtl.roles(), favor, run_state.favor_log, Callable(self, "_on_modal_action")), "favor")
	modal_closable = true

func _favor_changes(delta_map: Dictionary, reason: String) -> String:
	var parts: Array = []
	for key in delta_map:
		var id := str(key)
		var delta := int(delta_map[key])
		if delta == 0:
			continue
		var before := int(favor.get(id, 0))
		var after := clampi(before + delta, 0, 10)
		if after == before:
			continue
		favor[id] = after
		run_state.favor_log.append({"day": day, "id": id, "delta": after - before, "reason": reason})
		var role := AllocCtl.role(id)
		parts.append("%s %s%d" % [str(role.get("name", id)), "+" if after > before else "−", absi(after - before)])
	return " · ".join(PackedStringArray(parts))

func _favor_toast(delta_map: Dictionary, reason: String) -> void:
	var text := _favor_changes(delta_map, reason)
	if text != "":
		show_toast("人情：%s" % text, "good")

func _apply_effect(effects: Dictionary, reason: String) -> String:
	var bits: Array = []
	var favor_bits := _favor_changes(effects.get("favor", {}), reason)
	if favor_bits != "":
		bits.append(favor_bits)
	var perf_delta := int(effects.get("perf", 0))
	if perf_delta != 0:
		perf += perf_delta
		bits.append("绩效 %s¥%s" % ["+" if perf_delta > 0 else "−", Ui.fmt_money(absi(perf_delta))])
	var energy_delta := int(effects.get("energy", 0))
	if energy_delta != 0:
		run_state.energy = clampi(int(run_state.energy) + energy_delta, 0, int(AllocCtl.caps().get("energy", 99)))
		bits.append("精力 %s%d" % ["+" if energy_delta > 0 else "−", absi(energy_delta)])
	var money_delta := int(effects.get("money", 0))
	if money_delta != 0:
		run_state.money = clampi(int(run_state.money) + money_delta, 0, int(AllocCtl.caps().get("money", 99)))
		bits.append("金钱 %s%d" % ["+" if money_delta > 0 else "−", absi(money_delta)])
	var rep_delta := int(effects.get("rep", 0))
	if rep_delta != 0:
		rep = clampi(rep + rep_delta, 0, 5)
		bits.append("声誉 %s%d" % ["+" if rep_delta > 0 else "−", absi(rep_delta)])
	update_hud()
	return " · ".join(PackedStringArray(bits))

func _favor_today() -> Array:
	var agg: Dictionary = {}
	for entry in run_state.favor_log:
		if int(entry.get("day", -1)) != day:
			continue
		var id := str(entry.get("id", ""))
		agg[id] = int(agg.get(id, 0)) + int(entry.get("delta", 0))
	var rows: Array = []
	for id in agg:
		if int(agg[id]) == 0:
			continue
		rows.append({"id": id, "name": AllocCtl.role(str(id)).get("name", str(id)), "delta": int(agg[id])})
	return rows

func _favor_note() -> String:
	var top_name := ""
	var top_value := 0
	for role in AllocCtl.roles():
		var value := int(favor.get(str(role.get("id", "")), 0))
		if value > top_value:
			top_value = value
			top_name = str(role.get("name", ""))
	var total := AllocCtl.favor_total(favor)
	if top_value >= 9:
		return "%s在你的簿子上写到了「过命」。这一周，你欠下的人情和被人欠下的一样多。" % top_name
	if top_value >= 7:
		return "%s记得你替他说过的话。临走时，他在门口停了一下。" % top_name
	if total >= 18:
		return "簿子上密密麻麻。你把公事办成了人情，也有人把人情办成了公事。"
	if total <= 4:
		return "簿子很干净。走廊里没有人等你，窗口也照常开着。"
	return "不算深，也不算浅。下周的排班表上，会有人替你多留一格。"

# ============================================================
# COLLEGE RELATIONS (v1.15)
# ============================================================
func _college_entry(id: String) -> Dictionary:
	return CollegeCtl.entry(run_state.college_favor, id)

func _group_for_student(student: Dictionary) -> Dictionary:
	return CollegeCtl.group_for_college(str(student.get("official", {}).get("college", "")))

func _college_pass(student: Dictionary, correct: bool) -> String:
	var group := _group_for_student(student)
	if group.is_empty():
		return ""
	var gid := str(group.get("id", ""))
	var row := _college_entry(gid)
	var cap := CollegeCtl.favor_cap()
	var a0 := int(row.get("advisor", 0))
	var d0 := int(row.get("director", 0))
	row["advisor"] = mini(cap, a0 + 1)
	row["director"] = mini(cap, d0 + 1)
	row["lastStudent"] = str(student.get("name", "学生"))
	var bits: Array = []
	if int(row["advisor"]) > a0:
		bits.append("%s +%d" % [CollegeCtl.advisor_name(group), int(row["advisor"]) - a0])
	if int(row["director"]) > d0:
		bits.append("%s +%d" % [CollegeCtl.director_name(group), int(row["director"]) - d0])
	if bits.is_empty():
		bits.append("人情已满")
	var perf_gain := 0
	var passed := false
	var milestone := false
	if correct:
		row["passes"] = int(row.get("passes", 0)) + 1
		passed = true
		var gain := CollegeCtl.pass_perf(group)
		if gain > 0:
			perf += gain
			perf_gain += gain
			bits.append("学院回礼 +¥%s" % Ui.fmt_money(gain))
		if int(row["passes"]) >= CollegeCtl.milestone_at() and !bool(row.get("milestone", false)):
			row["milestone"] = true
			milestone = true
			var mgain := CollegeCtl.milestone_perf(group)
			if mgain > 0:
				perf += mgain
				perf_gain += mgain
				bits.append("感谢函 +¥%s" % Ui.fmt_money(mgain))
			else:
				bits.append("感谢函")
			run_state.college_letters.append(gid)
			run_state.add_item({
				"id": "letter_%s_%d" % [gid, day],
				"kind": "letter",
				"title": "感谢函 · " + str(group.get("short", group.get("label", gid))),
				"sub": "THANK YOU",
				"style": "sealed",
				"icon": "envelope",
				"stock": "SEALED",
				"stock_cn": "封函",
				"group": gid,
				"day": day,
				"student": str(row.get("lastStudent", "")),
				"consumable": true,
				"submit_favor": 2,
				"submit_perf": 40,
			})
	run_state.college_log.append({
		"day": day,
		"group": gid,
		"college": str(student.get("official", {}).get("college", "")),
		"student": str(row.get("lastStudent", "")),
		"advisor": int(row["advisor"]) - a0,
		"director": int(row["director"]) - d0,
		"pass": passed,
		"milestone": milestone,
		"perf": perf_gain,
	})
	update_hud()
	return "%s：%s" % [str(student.get("official", {}).get("college", "")), " · ".join(PackedStringArray(bits))]

func _college_note() -> String:
	var group := CollegeCtl.top_group(run_state.college_favor)
	if group.is_empty():
		return ""
	var row := _college_entry(str(group.get("id", "")))
	return "%s的%s与%s，都记得你替他们办过的事。" % [
		str(group.get("label", "")),
		CollegeCtl.advisor_name(group),
		CollegeCtl.director_name(group),
	]

func _show_college_ledger() -> void:
	if modal_open:
		return
	if phase != "review" and phase != "verdict" and phase != "allocate":
		return
	_click_fx(get_global_mouse_position())
	_play("page")
	if alloc_active:
		alloc_view.open_item("college")
		return
	_show_modal(Modals.college_ledger(CollegeCtl.groups(), run_state.college_favor, run_state.college_log, Callable(self, "_on_modal_action")), "college")
	modal_closable = true



func _render_story_tabs() -> void:
	if !story_active:
		return
	for c in tabs_root.get_children():
		c.queue_free()
	var docs := _story_docs()
	var x := 2.0
	for i in range(docs.size()):
		var doc: Dictionary = docs[i]
		var active := i == story_doc
		var y := 0.0 if active else 2.0
		var h := 23.0 if active else 21.0
		var label_h := 23.0 if active else 21.0
		var p := _box(tabs_root, x, y, 72, h, Ui.PAPER_HI if active else Color("#c1ad80"), null, 2, Color("#2a2013"))
		p.border_widths = Vector4i(2, 2, 2, 0)
		p.set_meta("story_tab", i)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		p.gui_input.connect(_on_story_gui_input.bind(i))
		_hover_fill(p, Ui.PAPER_HI if active else Color("#c1ad80"), Ui.PAPER_HI if active else Color("#d7c696"))
		_pix(p, "%02d" % (i + 1), 7, 4.0 if active else 3.0, 14, label_h, 7.5, Color("#856f49"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
		_pix(p, str(doc.get("tab", "")), 22, 0.0 if active else -1.0, 48, label_h, 10, Color("#251f15") if active else Color("#4f4129"), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)
		if active:
			var strip := ColorRect.new()
			strip.color = Ui.PAPER_HI
			strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tabs_root.add_child(strip)
			Ui.place(strip, x, 23, 72, 5)
			p.scale = Vector2(1.0, 1.045)
			p.pivot_offset = Vector2(36, h)
			var tw := create_tween()
			tw.tween_property(p, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		x += 76.0

func _render_story_doc() -> void:
	if !story_active:
		return
	var docs := _story_docs()
	if story_doc < 0 or story_doc >= docs.size():
		story_doc = 0
	for c in doc_box.get_children():
		c.queue_free()
	doc_box.add_child(StoryDocs.render(docs[story_doc], _story_tokens()))
	_animate_doc(doc_box.get_child(doc_box.get_child_count() - 1))
	if doc_scroll != null:
		doc_scroll.scroll_vertical = 0

func _render_story_rail() -> void:
	if !story_active:
		return
	for c in materials_box.get_children():
		c.queue_free()
	var docs := _story_docs()
	materials_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	material_count.text = "%02d" % docs.size()
	rail_foot_left.text = "翻阅"
	rail_foot_right.text = "待批示" if story_choice == -1 else "已阅"
	for i in range(docs.size()):
		var doc: Dictionary = docs[i]
		var active := i == story_doc
		var card := _box(materials_box, 0, 0, 198, 43, Color("#f1e3bc") if active else Color("#d8c8a2"), null, 2, Color("#17130d"), Vector2(2, 2))
		card.custom_minimum_size = Vector2(198, 43)
		card.set_meta("story_doc", i)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(_on_story_gui_input.bind(i))
		_hover_fill(card, Color("#f1e3bc") if active else Color("#d8c8a2"), Color("#f1e3bc") if active else Color("#e9dbb6"))
		if active:
			Ui.hline(card, 0, 0, 3, Ui.RED, 43)
		var icon := _box(card, 5, 7, 27, 29, Color("#9c392d") if active else Color("#c1ab7c"), null, 1, Color("#5c1e17") if active else Color("#6a5739"))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_material_icon(icon, 1, 1, 25, 27, doc, Color("#f3e2bd") if active else Color("#5d472a"))
		_pix(card, str(doc.get("tab", "")), 38, 9, 130, 15, 11, Color("#322a1c"))
		_pix(card, str(doc.get("badge", "")), 38, 23, 140, 12, 8, Color("#776545"))
		_pix(card, "●" if active else "›", 172, 13, 14, 16, 12, Color("#8a3b2f"), HORIZONTAL_ALIGNMENT_CENTER)

func _render_story_console() -> void:
	if !story_active:
		return
	for c in story_actions.get_children():
		c.queue_free()
	for c in story_dots.get_children():
		c.queue_free()
	story_choice_btns.clear()
	story_finish_btn = null
	var docs := _story_docs()
	var n := docs.size()
	story_kicker.text = _story_fill(story_scene.get("subtitle", ""))
	story_title.text = _story_fill(story_scene.get("title", ""))
	story_count.text = "%02d / %02d" % [story_viewed.size(), n]
	var active_i := clampi(story_doc, 0, max(0, n - 1))
	var start_x := (78.0 - n * 10.0) * 0.5
	for i in range(n):
		var dot := _box(story_dots, start_x + i * 10.0, 0, 6, 4, Color("#d7c79f") if i == active_i else Color("#52604a"), null, 1, Color("#171d15"))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if story_choice == -1:
		story_sub.text = _story_fill(story_scene.get("choice", {}).get("prompt", ""))
		var options: Array = story_scene.get("choice", {}).get("options", [])
		for i in range(options.size()):
			var b := _story_button(_story_fill(options[i].get("label", "")), 0, 3 + i * 28, 92, 26)
			Ui.set_font(b, int(round(9.5)))
			b.pressed.connect(_on_story_choice.bind(i))
			story_choice_btns.append(b)
	else:
		story_sub.text = "已签阅"
		var final := day >= GameData.days.size() - 1
		story_finish_btn = _story_button("结束" if final else "下班", 0, 20, 92, 30)
		story_finish_btn.pressed.connect(_finish_night_story)

func _shake() -> void:
	if SettingsStore.reduce_motion:
		return
	var tw := create_tween()
	var base := position
	tw.tween_property(self, "position", base + Vector2(-4, 1), 0.04)
	tw.tween_property(self, "position", base + Vector2(4, -1), 0.04)
	tw.tween_property(self, "position", base + Vector2(-3, 2), 0.04)
	tw.tween_property(self, "position", base + Vector2(3, -2), 0.04)
	tw.tween_property(self, "position", base + Vector2(-1, 1), 0.04)
	tw.tween_property(self, "position", base, 0.04)

func _flash() -> void:
	if SettingsStore.reduce_motion:
		return
	var r := ColorRect.new()
	r.color = Color(1, 0.945, 0.8, 0.16)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_fx.add_child(r)
	Ui.place(r, 5, 5, 1370, 850)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.22)
	tw.tween_callback(r.queue_free)

func _play(name: String) -> void:
	if sfx != null:
		sfx.play(name)

func _fx_layer() -> Control:
	if modal_open and modal_fx_layer != null:
		return modal_fx_layer
	return layer_fx

func _click_fx(pos: Vector2, color: Color = Color("#d9c18f")) -> void:
	var layer := _fx_layer()
	var ring := PixelPanel.new()
	ring.bg_color = Color(0, 0, 0, 0)
	ring.border_width = 2
	ring.border_color = color
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 50
	layer.add_child(ring)
	Ui.place(ring, pos.x - 10, pos.y - 10, 20, 20)
	ring.pivot_offset = Vector2(10, 10)
	ring.scale = Vector2(0.55, 0.55)
	ring.modulate.a = 0.9
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(1.9, 1.9), 0.22)
	tw.tween_property(ring, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(ring.queue_free)
	for i in range(4):
		var s := ColorRect.new()
		s.color = color
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.z_index = 49
		layer.add_child(s)
		Ui.place(s, pos.x - 1.5, pos.y - 1.5, 3, 3)
		var ang := float(i) * TAU / 4.0 + randf_range(-0.35, 0.35)
		var st := create_tween()
		st.set_parallel(true)
		st.tween_property(s, "position", pos + Vector2(cos(ang), sin(ang)) * randf_range(10.0, 17.0), 0.2)
		st.tween_property(s, "modulate:a", 0.0, 0.2)
		st.chain().tween_callback(s.queue_free)
	var dot := ColorRect.new()
	dot.color = Color("#a83a2f")
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.z_index = 51
	layer.add_child(dot)
	Ui.place(dot, pos.x - 2, pos.y - 2, 4, 4)
	dot.pivot_offset = Vector2(2, 2)
	var dt := create_tween()
	dt.set_parallel(true)
	dt.tween_property(dot, "scale", Vector2(2.2, 2.2), 0.18)
	dt.tween_property(dot, "modulate:a", 0.0, 0.18)
	dt.chain().tween_callback(dot.queue_free)

func _paper_flash(color: Color = Color(1, 0.96, 0.83, 0.1)) -> void:
	var f := ColorRect.new()
	f.color = color
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.z_index = 48
	layer_fx.add_child(f)
	Ui.place(f, 276, 421, 744, 342)
	var tw := create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.16)
	tw.tween_callback(f.queue_free)

func _animate_doc(view: Control) -> void:
	if view == null:
		return
	view.modulate.a = 0.0
	view.scale = Vector2(0.986, 1.0)
	view.pivot_offset = Vector2(348, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(view, "modulate:a", 1.0, 0.16)
	tw.tween_property(view, "scale", Vector2.ONE, 0.16)

func _stamp_burst(center: Vector2, color: Color) -> void:
	# Stamp particles belong to the desk, under loose material sheets. Using
	# layer_fx (above loose files) made them look stamped onto the wrong layer.
	var ring := PixelPanel.new()
	ring.bg_color = Color(0, 0, 0, 0)
	ring.border_width = 3
	ring.border_color = color
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 55
	layer_desk.add_child(ring)
	Ui.place(ring, center.x - 18, center.y - 18, 36, 36)
	ring.pivot_offset = Vector2(18, 18)
	ring.scale = Vector2(0.5, 0.5)
	ring.modulate.a = 0.85
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(2.6, 2.6), 0.28)
	tw.tween_property(ring, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(ring.queue_free)
	for i in range(9):
		var s := ColorRect.new()
		s.color = color
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.z_index = 54
		layer_desk.add_child(s)
		Ui.place(s, center.x - 2, center.y - 2, 4, 4)
		var ang := randf() * TAU
		var dist := randf_range(18.0, 46.0)
		var st := create_tween()
		st.set_parallel(true)
		st.tween_property(s, "position", center + Vector2(cos(ang), sin(ang)) * dist, 0.32)
		st.tween_property(s, "modulate:a", 0.0, 0.32)
		st.chain().tween_callback(s.queue_free)

func _begin_drag_fx(node: Control) -> void:
	if node == null:
		return
	if drag_outline != null and is_instance_valid(drag_outline):
		drag_outline.queue_free()
	drag_outline = PixelPanel.new()
	drag_outline.bg_color = Color(0, 0, 0, 0)
	drag_outline.border_width = 2
	drag_outline.border_color = Color(0.85, 0.75, 0.53, 0.75)
	drag_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_outline.z_index = 300
	layer_ghost.add_child(drag_outline)
	drag_outline.position = node.position - Vector2(3, 3)
	drag_outline.size = node.size + Vector2(6, 6)
	drag_outline.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(drag_outline, "modulate:a", 0.8, 0.1)

func _update_drag_outline(node: Control) -> void:
	if drag_outline != null and is_instance_valid(drag_outline) and node != null:
		drag_outline.position = node.position - Vector2(3, 3)
		drag_outline.size = node.size + Vector2(6, 6)

func _end_drag_fx() -> void:
	if drag_outline != null and is_instance_valid(drag_outline):
		var o := drag_outline
		var tw := create_tween()
		tw.tween_property(o, "modulate:a", 0.0, 0.1)
		tw.tween_callback(o.queue_free)
	drag_outline = null

func _rail_glow(on: bool) -> void:
	if rail_panel == null:
		return
	rail_panel.border_color = Color("#d9c18f") if on else Color("#141912")
	rail_panel.queue_redraw()

func _toggle_sound() -> void:
	_click_fx(get_global_mouse_position())
	muted = !muted
	SettingsStore.muted = muted
	SettingsStore.save_settings()
	if sfx != null:
		sfx.muted = muted
	sound_btn.modulate = Color(1, 1, 1, 0.45) if muted else Color.WHITE
	if !muted:
		_play("click")
		show_toast("音效已开启")
	else:
		show_toast("音效已关闭")

func show_toast(text: String, kind: String = "") -> void:
	if toast_panel == null:
		return
	toast_gen += 1
	var gen := toast_gen
	toast_label.text = text
	if toast_accent != null:
		match kind:
			"good": toast_accent.color = Color("#4f7652")
			"warn": toast_accent.color = Color("#b77b2e")
			"bad": toast_accent.color = Color("#a83a2f")
			_: toast_accent.color = Color(0, 0, 0, 0)
	var font := Ui.F_UI
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var w: float = clampf(tw + 30.0, 120.0, 560.0)
	toast_panel.size.x = w
	toast_panel.position.x = (W - w) * 0.5
	toast_label.size.x = w - 28
	toast_panel.visible = true
	if toast_tween != null:
		toast_tween.kill()
	toast_panel.modulate.a = 0.0
	toast_panel.position.y = 63
	toast_panel.pivot_offset = Vector2(w * 0.5, 16.5)
	toast_panel.scale = Vector2(0.97, 0.97)
	toast_tween = create_tween()
	toast_tween.set_parallel(true)
	toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.12)
	toast_tween.tween_property(toast_panel, "position:y", 71.0, 0.12)
	toast_tween.tween_property(toast_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func clear_loose() -> void:
	desktop.clear()
	request_paper = null
	request_task = {}
	request_main_doc_id = ""
	request_resolving = false

func _select_stamp(id: String) -> void:
	if phase != "review":
		return
	if !GameData.outcomes.has(id):
		return
	selected = id
	render_stamps()
	_play("select")

func _paper_rect() -> Rect2:
	return Rect2(folder_panel.position + Vector2(11, 49), Vector2(738, 336))

func _sync_annotation_offset() -> void:
	if annotation_content != null and doc_scroll != null:
		annotation_content.position = Vector2(15, 15.0 - float(doc_scroll.scroll_vertical))

func _paper_to_content(pos: Vector2) -> Vector2:
	var p := pos - folder_panel.position - Vector2(11, 49)
	p -= Vector2(15, 15)
	p.y += float(doc_scroll.scroll_vertical)
	return p

func _toggle_annotation() -> void:
	if phase != "review" or story_active:
		return
	_cancel_drag()
	_set_annotation_mode(!annotating)

func _update_annotate_visual() -> void:
	if annotate_plate == null:
		return
	var on := annotating
	annotate_plate.border_color = Color("#e0b96b") if on else Color("#8c6a3c")
	annotate_plate.inner_highlight = Color("#8b6a43") if on else Color("#5b432b")
	annotate_plate.queue_redraw()
	if annotate_btn != null:
		annotate_btn.modulate = Color(1.0, 0.78, 0.68) if on else Color.WHITE
	if annotate_mark != null:
		annotate_mark.visible = on

func _set_annotation_mode(on: bool) -> void:
	annotating = on
	_update_annotate_visual()
	if annotation_guard != null:
		annotation_guard.visible = on
	if !on and annot_drawing:
		_free_ink()
	annot_drawing = false

func _free_ink() -> void:
	if annot_ring != null and is_instance_valid(annot_ring):
		annot_ring.queue_free()
	annot_ring = null
	if annot_box != null and is_instance_valid(annot_box):
		annot_box.queue_free()
	annot_box = null

func _begin_annotation(pos: Vector2) -> void:
	annot_start = _paper_to_content(pos)
	annot_end = annot_start
	annot_seed = float((day * 7 + stu) % 11) * 0.7
	annot_drawing = true
	_free_ink()
	if annotation_guard != null:
		annotation_guard.visible = true
	annot_box = _box(annotation_content, annot_start.x, annot_start.y, 1, 1, Color(0, 0, 0, 0), null, 1, Color("#c08a35"))
	annot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	annot_box.z_index = 59
	annot_box.dashed = true
	annot_box.dash_length = 4
	annot_ring = InkRing.new()
	annotation_content.add_child(annot_ring)
	annot_ring.configure(Rect2(annot_start, Vector2(1, 1)), annot_seed)
	_play("pick")

func _update_annotation(pos: Vector2) -> void:
	if !annot_drawing or annot_ring == null or !is_instance_valid(annot_ring):
		return
	var p := _paper_to_content(pos)
	p.x = clampf(p.x, 0, 696)
	p.y = clampf(p.y, 0, 1000)
	annot_end = p
	var r := Rect2(Vector2(minf(annot_start.x, p.x), minf(annot_start.y, p.y)), Vector2(absf(p.x - annot_start.x), absf(p.y - annot_start.y)))
	if annot_box != null and is_instance_valid(annot_box):
		annot_box.position = r.position
		annot_box.size = r.size
	annot_ring.configure(r, annot_seed)

func _release_box() -> void:
	if annot_box != null and is_instance_valid(annot_box):
		annot_box.queue_free()
	annot_box = null

func _fade_ring() -> void:
	var ring := annot_ring
	annot_ring = null
	if ring == null or !is_instance_valid(ring):
		return
	var tw := ring.create_tween()
	tw.tween_property(ring, "modulate:a", 0.0, 0.7)
	tw.tween_callback(ring.queue_free)

func _finish_annotation(pos: Vector2) -> void:
	if !annot_drawing or annot_ring == null or !is_instance_valid(annot_ring):
		return
	_update_annotation(pos)
	annot_drawing = false
	_release_box()
	var bbox := annot_ring.inner_rect
	if bbox.size.x < 30.0 or bbox.size.y < 22.0:
		_free_ink()
		if annotation_guard != null:
			annotation_guard.visible = false
		show_toast("圈得太小，画大一点", "warn")
		return
	var center := bbox.get_center()
	var audit := GameData.audit(current, day)
	var defects: Array = audit.get("defects", [])
	var defect := AnnotationCtl.hit_test(center, tab, defects, doc_box, annotation_content, ann.found)
	if defect.is_empty():
		annot_ring.modulate = Color(0.62, 0.55, 0.45)
		if annotation_guard != null:
			annotation_guard.visible = false
		ann.record_attempt(tab, center, {}, "", false)
		var near := AnnotationCtl.near_miss(center, tab, defects, doc_box, annotation_content, ann.found)
		if !near.is_empty():
			var nd: Dictionary = near.get("defect", {})
			var dir := _near_dir(center, str(nd.get("anchor", "")))
			show_toast("差一点：往%s再圈一点——%s" % [dir, _defect_label(nd)], "warn")
		elif defects.is_empty():
			show_toast("这份材料没有查出问题", "warn")
		else:
			show_toast("这处没有问题，换个位置再圈", "warn")
		_fade_ring()
		return
	var label := _defect_label(defect)
	var lw: float = maxf(104.0, Ui.F_UI_BOLD.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 12.0)
	var lx := clampf(bbox.position.x + bbox.size.x * 0.55, 4.0, 696.0 - lw)
	var ly := clampf(bbox.position.y + bbox.size.y + 8.0, 4.0, 1000.0 - 24.0)
	var tag := _box(annotation_content, lx, ly, lw, 20, Color("#f4e9c9"), null, 2, Color("#8c3a2f"))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.z_index = 62
	_pix(tag, label, 5, 2, lw - 10, 16, 8, Color("#6e241d"))
	tag.pivot_offset = Vector2(lw * 0.5, 10)
	tag.scale = Vector2(0.9, 0.9)
	var tag_tw := create_tween()
	tag_tw.tween_property(tag, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ann.add_mark(tab, defect, bbox, annot_seed, lx, ly, lw, label)
	day_annotation_count += 1
	perf += AnnotationCtl.AWARD
	annot_ring = null
	if annotation_guard != null:
		annotation_guard.visible = false
	update_hud()
	_play("select")
	show_toast("圈出问题：%s  +¥%d" % [label, AnnotationCtl.AWARD], "good")

func _defect_label(d: Dictionary) -> String:
	if d.is_empty():
		return ""
	var label := str(d.get("label", ""))
	if label != "":
		return label
	return _annot_label(str(d.get("group", "")))

func _near_dir(center: Vector2, anchor: String) -> String:
	var r := AnnotationCtl.rect_for(anchor, tab, doc_box, annotation_content)
	if r.size.x <= 0.0:
		return "问题附近"
	var delta := r.get_center() - center
	var dir := ""
	if delta.y < -10.0:
		dir += "中"
	elif delta.y > 10.0:
		dir += "中"
	if delta.x < -10.0:
		dir += "已"
	elif delta.x > 10.0:
		dir += "叶"
	return dir if dir != "" else "问题附近"

func _defect_for_circle(center: Vector2) -> Dictionary:
	var au := GameData.audit(current, day)
	return AnnotationCtl.hit_test(center, tab, au.get("defects", []), doc_box, annotation_content, ann.found)

func _add_mark_visual(mark: Dictionary) -> void:
	var ring := InkRing.new()
	annotation_content.add_child(ring)
	ring.configure(mark.get("rect", Rect2(0, 0, 1, 1)), float(mark.get("seed", 0.0)))
	var lw := float(mark.get("tag_w", 104.0))
	var tag := _box(annotation_content, float(mark.get("tag_x", 4.0)), float(mark.get("tag_y", 4.0)), lw, 20, Color("#f4e9c9"), null, 2, Color("#8c3a2f"))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.z_index = 62
	_pix(tag, str(mark.get("label", "")), 5, 2, lw - 10, 16, 8, Color("#6e241d"))

func _clear_annotation_display() -> void:
	if annotation_content == null:
		return
	for c in annotation_content.get_children():
		c.queue_free()
	annot_ring = null
	annot_box = null
	annotation_debug = null

func _toggle_anchor_debug() -> void:
	if phase != "review" or story_active:
		return
	if annotation_debug != null and is_instance_valid(annotation_debug):
		annotation_debug.queue_free()
		annotation_debug = null
		return
	annotation_debug = Control.new()
	annotation_debug.mouse_filter = Control.MOUSE_FILTER_IGNORE
	annotation_debug.z_index = 100
	annotation_content.add_child(annotation_debug)
	var regions := _current_anchor_rects()
	for anchor in regions.keys():
		var r: Rect2 = regions[anchor]
		if r.size.x <= 0.0:
			continue
		var b := _box(annotation_debug, r.position.x, r.position.y, r.size.x, r.size.y, Color(1, 0.72, 0.2, 0.04), null, 1, Color("#c08a35"))
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pix(b, str(anchor), 3, 1, maxf(60, r.size.x - 6), 12, 7, Color("#7a4d1f"))
	show_toast("显示当前页圈注区域（%d 个）" % regions.size(), "warn")

## Static table plus every anchor that the current student's defects resolve to.
func _current_anchor_rects() -> Dictionary:
	var out: Dictionary = AuditRegions.all_for_tab(tab).duplicate()
	var au := GameData.audit(current, day)
	for d in au.get("defects", []):
		var anchor := str(d.get("anchor", ""))
		var r := AnnotationCtl.rect_for(anchor, tab, doc_box, annotation_content)
		if r.size.x > 0.0:
			out[anchor] = r
		elif !out.has(anchor):
			out[anchor] = Rect2()
	return out

func _restore_annotations(tab_id: String) -> void:
	_clear_annotation_display()
	if !ann.marks.has(tab_id):
		return
	for mark in ann.marks[tab_id]:
		_add_mark_visual(mark)

func _clear_tab_annotations(tab_id: String, refund: bool = true) -> void:
	if !ann.marks.has(tab_id):
		_restore_annotations(tab_id)
		return
	var n: int = ann.marks[tab_id].size()
	var refund_amt: int = int(ann.clear_tab(tab_id))
	day_annotation_count = maxi(0, day_annotation_count - n)
	if refund:
		perf = maxi(0, perf - refund_amt)
	_restore_annotations(tab_id)
	update_hud()

func _undo_annotation() -> void:
	if !ann.marks.has(tab) or ann.marks[tab].is_empty():
		show_toast("当前页没有可撤销的圈注", "warn")
		return
	var mark: Dictionary = ann.undo(tab)
	if mark.is_empty():
		return
	day_annotation_count = maxi(0, day_annotation_count - 1)
	if bool(mark.get("awarded", false)):
		perf = maxi(0, perf - AnnotationCtl.AWARD)
	_restore_annotations(tab)
	update_hud()
	show_toast("已撤销：%s" % str(mark.get("label", "圈注")), "warn")

func clear_annotations(refund: bool = false) -> void:
	var held: int = ann.awarded
	if refund:
		perf = maxi(0, perf - held)
	ann.reset()
	annot_drawing = false
	annot_ring = null
	annot_box = null
	_clear_annotation_display()
	_set_annotation_mode(false)

func _annot_label(group: String) -> String:
	match group:
		"identity":
			return "身份 / 题目不一致"
		"summary":
			return "摘要规格不符"
		"dup":
			return "查重报告有问题"
		"refs":
			return "参考文献不达标"
		"body":
			return "正文 / 页码不达标"
		"form":
			return "签字 / 伦理缺失"
		"admin":
			return "学分 / 学费问题"
	return "条例问题"

func _input(event: InputEvent) -> void:
	InputRouter.handle_mouse(self, event)

func _try_double(pos: Vector2) -> bool:
	if official_card != null and official_card.get_global_rect().has_point(pos):
		official_card.position = panel_home.get(official_card, Vector2(389, 96))
		official_card.z_index = 0
		return true
	if folder_panel != null and folder_panel.get_global_rect().has_point(pos):
		folder_panel.position = panel_home.get(folder_panel, Vector2(268, 375))
		folder_panel.z_index = 0
		return true
	if rail_panel != null and rail_panel.get_global_rect().has_point(pos):
		rail_panel.position = panel_home.get(rail_panel, Vector2(1038, 375))
		rail_panel.z_index = 0
		return true
	return false

func _try_press(pos: Vector2) -> bool:
	if modal_open or (phase != "review" and phase != "verdict" and phase != "story"):
		return false
	if !drag_state.is_empty():
		_cancel_drag()
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered is Button:
		return false
	# story tabs / story rail cards take priority while the night desk is open
	if story_active:
		for child in tabs_root.get_children():
			if child is Control and child.has_meta("story_tab") and child.get_global_rect().has_point(pos):
				_open_story_doc(int(child.get_meta("story_tab", 0)))
				return true
		for card in materials_box.get_children():
			if card is Control and card.has_meta("story_doc") and card.get_global_rect().has_point(pos):
				_open_story_doc(int(card.get_meta("story_doc", 0)))
				return true
		if official_card != null and official_card.get_global_rect().has_point(pos):
			drag_state = {"kind": "panel", "node": official_card, "start": pos, "start_pos": official_card.position, "moved": false, "base_z": official_card.z_index}
			official_card.z_index = 25
			return true
		if folder_panel != null:
			var story_handle := Rect2(folder_panel.position + Vector2(8, 3), Vector2(744, 20))
			if story_handle.has_point(pos):
				drag_state = {"kind": "panel", "node": folder_panel, "start": pos, "start_pos": folder_panel.position, "moved": false, "base_z": folder_panel.z_index}
				folder_panel.z_index = 25
				return true
		if rail_panel != null and rail_panel.get_global_rect().has_point(pos) and pos.y < rail_panel.position.y + 47:
			drag_state = {"kind": "panel", "node": rail_panel, "start": pos, "start_pos": rail_panel.position, "moved": false, "base_z": rail_panel.z_index}
			rail_panel.z_index = 25
			return true
		return false
	# loose attachment windows (topmost first)
	var loose_nodes: Array = loose_files.values()
	loose_nodes.sort_custom(func(a, b): return a.z_index > b.z_index)
	for w in loose_nodes:
		if !is_instance_valid(w):
			continue
		var r: Rect2 = w.get_global_rect()
		if r.has_point(pos):
			if pos.y <= r.position.y + 32 and pos.x < r.end.x - 48:
				drag_state = {"kind": "loose", "node": w, "id": w.get_meta("loose_id", ""), "start": pos, "start_pos": w.position, "moved": false}
				desktop.bring_front(w)
				return true
			return false
	# stamp chips
	var ids := ["pass", "revise", "reject"]
	for i in range(chip_panels.size()):
		var chip: Control = chip_panels[i]
		var face: PixelPanel = chip_faces[i]
		var face_hit: bool = face.get_global_rect().has_point(pos)
		var handle_hit: bool = Rect2(chip.get_global_position() + Vector2(42, 0), Vector2(26, 12)).has_point(pos)
		if face_hit or handle_hit:
			if phase != "review":
				return false
			_select_stamp(ids[i])
			drag_state = {"kind": "stamp", "type": ids[i], "start": pos, "moved": false, "ghost": null}
			return true
	# verdict target
	if stamp_target != null and stamp_target.get_global_rect().has_point(pos):
		if phase == "review":
			stamp_decision()
			return true
	# draggable panels
	if official_card != null and official_card.get_global_rect().has_point(pos):
		drag_state = {"kind": "panel", "node": official_card, "start": pos, "start_pos": official_card.position, "moved": false, "base_z": official_card.z_index}
		official_card.z_index = 25
		return true
	if folder_panel != null:
		var handle := Rect2(folder_panel.position + Vector2(8, 3), Vector2(744, 20))
		if handle.has_point(pos):
			drag_state = {"kind": "panel", "node": folder_panel, "start": pos, "start_pos": folder_panel.position, "moved": false, "base_z": folder_panel.z_index}
			folder_panel.z_index = 25
			return true
	if rail_panel != null and rail_panel.get_global_rect().has_point(pos) and pos.y < rail_panel.position.y + 47:
		drag_state = {"kind": "panel", "node": rail_panel, "start": pos, "start_pos": rail_panel.position, "moved": false, "base_z": rail_panel.z_index}
		rail_panel.z_index = 25
		return true
	# tabs
	for child in tabs_root.get_children():
		if child is Control and child.get_global_rect().has_point(pos):
			var id := str(child.get_meta("tab_id", ""))
			if id != "":
				switch_tab(id)
				return true
	# materials
	for card in materials_box.get_children():
		if card is Control and card.has_meta("material_id") and card.get_global_rect().has_point(pos):
			if phase != "review":
				return false
			drag_state = {"kind": "material", "card": card, "id": str(card.get_meta("material_id", "")), "start": pos, "moved": false}
			return true
	return false

func _move_drag(pos: Vector2) -> void:
	if drag_state.is_empty():
		return
	var kind := str(drag_state.get("kind", ""))
	var start: Vector2 = drag_state.get("start", pos)
	var delta: Vector2 = pos - start
	if kind == "panel":
		var node: Control = drag_state.get("node")
		if node == null:
			return
		if !bool(drag_state.get("moved", false)) and delta.length() <= 3.0:
			return
		if !bool(drag_state.get("moved", false)):
			drag_state["moved"] = true
			_play("pick")
			_begin_drag_fx(node)
			var pp := node as PixelPanel
			if pp != null:
				drag_state["base_shadow"] = pp.shadow_offset
				pp.shadow_offset += Vector2(5, 6)
		var base_pos: Vector2 = drag_state.get("start_pos", node.position)
		var target: Vector2 = base_pos + delta
		target.x = clampf(target.x, 6, W - node.size.x - 6)
		target.y = clampf(target.y, 64, H - node.size.y - 6)
		node.position = target
		_update_drag_outline(node)
	elif kind == "stamp":
		if !bool(drag_state.get("moved", false)):
			if delta.length() < 7.0:
				return
			drag_state["moved"] = true
			_play("pick")
			drag_state["ghost"] = _make_ghost(str(drag_state.get("type", "")))
		var g: Control = drag_state.get("ghost")
		if g != null:
			g.position = pos - Vector2(43, 39)
	elif kind == "material":
		if !bool(drag_state.get("moved", false)):
			if delta.length() < 7.0:
				return
			drag_state["moved"] = true
			_play("pick")
			var c_ref: Variant = drag_state.get("card")
			if c_ref != null and is_instance_valid(c_ref):
				var c: Control = c_ref
				c.modulate.a = 0.45
			drag_state["ghost"] = _make_material_ghost(str(drag_state.get("id", "")))
		_rail_glow(_over_rail(pos))
		var mg: Control = drag_state.get("ghost")
		if mg != null and is_instance_valid(mg):
			mg.position = pos - Vector2(99, 21)
	elif kind == "loose":
		if !bool(drag_state.get("moved", false)):
			if delta.length() <= 2.0:
				return
			drag_state["moved"] = true
			_play("pick")
			var lw: Control = drag_state.get("node")
			_begin_drag_fx(lw)
			var lp := lw as PixelPanel
			if lp != null:
				drag_state["base_shadow"] = lp.shadow_offset
				lp.shadow_offset += Vector2(5, 6)
		var node2: Control = drag_state.get("node")
		if node2 == null:
			return
		var base2: Vector2 = drag_state.get("start_pos", node2.position)
		var p: Vector2 = base2 + delta
		p.x = clampf(p.x, 8, W - node2.size.x - 8)
		p.y = clampf(p.y, 64, H - node2.size.y - 8)
		desktop.move_window(node2, p)
		node2.modulate.a = 0.58 if _over_rail(pos) else 1.0
		_rail_glow(_over_rail(pos))
		_update_drag_outline(node2)

func _end_drag(pos: Vector2) -> void:
	var kind := str(drag_state.get("kind", ""))
	var moved := bool(drag_state.get("moved", false))
	if kind == "stamp":
		if drag_state.get("ghost") != null:
			var g: Control = drag_state.get("ghost")
			if is_instance_valid(g):
				g.queue_free()
		if moved:
			var zone := ""
			if stamp_target.get_global_rect().has_point(pos):
				zone = "target"
			elif Rect2(276, 421, 744, 342).has_point(pos):
				zone = "paper"
			# A material window is physically above the thesis/target. Do not
			# stamp through it: the ink would either hide under the sheet or
			# appear on top of the wrong layer.
			if _loose_at(pos) != null:
				_play("drop")
				show_toast("材料文件在上面，先收起再盖章", "warn")
			elif _loose_over_rect(stamp_target.get_global_rect()):
				_play("drop")
				show_toast("材料压住印章台，先收起再盖章", "warn")
			elif zone != "":
				stamp_decision()
			else:
				_play("drop")
				var miss_label := str(GameData.outcome(str(drag_state.get("type", ""))).get("stamp", ""))
				show_toast("「%s」未盖下：拖到结论栏再松手" % miss_label, "warn")
		else:
			var pick_label := str(GameData.outcome(str(drag_state.get("type", ""))).get("stamp", ""))
			show_toast("已选「%s」：点结论栏，或把印章拖到论文上" % pick_label)
	elif kind == "material":
		var card_ref: Variant = drag_state.get("card")
		if card_ref != null and is_instance_valid(card_ref):
			var card: Control = card_ref
			card.modulate.a = 1.0
		var mg: Variant = drag_state.get("ghost")
		if mg != null and is_instance_valid(mg):
			mg.queue_free()
		_rail_glow(false)
		var id := str(drag_state.get("id", ""))
		if moved:
			_play("drop")
			if _over_desk(pos) and !_over_rail(pos):
				open_loose(id, pos)
		else:
			open_loose(id)
	elif kind == "loose":
		var node: Control = drag_state.get("node")
		if node != null and is_instance_valid(node):
			node.modulate.a = 1.0
			if _over_rail(pos):
				close_loose(str(drag_state.get("id", "")), true)
		_rail_glow(false)
		if moved:
			if is_instance_valid(node):
				desktop.snap_window(node)
			_play("drop")
	elif kind == "panel":
		var node3: Control = drag_state.get("node")
		if node3 != null and is_instance_valid(node3) and !moved:
			node3.z_index = int(drag_state.get("base_z", 0))
		if moved and node3 != null and is_instance_valid(node3):
			_play("drop")
			node3.pivot_offset = node3.size * 0.5
			node3.scale = Vector2(1.006, 1.006)
			var tw := create_tween()
			tw.tween_property(node3, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if drag_state.has("base_shadow"):
		var pp := drag_state.get("node") as PixelPanel
		if pp != null:
			pp.shadow_offset = drag_state.get("base_shadow", Vector2.ZERO)
	if kind == "panel" or kind == "loose":
		_end_drag_fx()
	drag_state = {}

func _cancel_drag() -> void:
	if drag_state.is_empty():
		return
	var kind := str(drag_state.get("kind", ""))
	var ghost_node: Variant = drag_state.get("ghost")
	if ghost_node != null and is_instance_valid(ghost_node):
		ghost_node.queue_free()
	if kind == "panel":
		var node: Control = drag_state.get("node")
		if node != null and is_instance_valid(node) and !bool(drag_state.get("moved", false)):
			node.z_index = int(drag_state.get("base_z", 0))
	elif kind == "material":
		var card_ref: Variant = drag_state.get("card")
		if card_ref != null and is_instance_valid(card_ref):
			var card: Control = card_ref
			card.modulate.a = 1.0
		var mg: Variant = drag_state.get("ghost")
		if mg != null and is_instance_valid(mg):
			mg.queue_free()
	elif kind == "loose":
		var win: Control = drag_state.get("node")
		if win != null and is_instance_valid(win):
			win.modulate.a = 1.0
	if drag_state.has("base_shadow"):
		var pp := drag_state.get("node") as PixelPanel
		if pp != null:
			pp.shadow_offset = drag_state.get("base_shadow", Vector2.ZERO)
	_rail_glow(false)
	_end_drag_fx()
	drag_state = {}

func _make_material_ghost(id: String) -> Control:
	var g := Control.new()
	g.size = Vector2(198, 43)
	g.mouse_filter = Control.MOUSE_FILTER_STOP
	g.mouse_default_cursor_shape = Control.CURSOR_DRAG
	g.rotation = deg_to_rad(1.2)
	layer_ghost.add_child(g)
	var p := PixelPanel.new()
	p.bg_color = Color("#efe1b8")
	p.border_width = 2
	p.border_color = Color("#17130d")
	p.shadow_offset = Vector2(4, 5)
	p.shadow_color = Color(0, 0, 0, 0.35)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(p)
	Ui.place(p, 0, 0, 198, 43)
	var icon := PixelPanel.new()
	icon.bg_color = Color("#9c392d")
	icon.border_width = 1
	icon.border_color = Color("#5c1e17")
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(icon)
	Ui.place(icon, 5, 7, 27, 29)
	var label := ""
	var icon_doc: Dictionary = {}
	if id.begins_with("req:"):
		var parts := id.split(":")
		if parts.size() >= 3 and requests != null:
			var task: Dictionary = requests.get_request(parts[1])
			for d in task.get("documents", []):
				if str(d.get("id", "")) == parts[2]:
					label = str(d.get("tab", "学生材料"))
					icon_doc = d
					break
			if label == "":
				label = str(task.get("title", "学生材料"))
	else:
		for m in GameData.materials:
			if str(m.get("id", "")) == id:
				label = str(m.get("label", ""))
				icon_doc = m
				break
	var draw := MaterialIconCtl.new()
	icon.add_child(draw)
	Ui.place(draw, 1, 1, 25, 27)
	draw.configure(MaterialIconCtl.key_for_doc(icon_doc), Color("#f3e2bd"))
	Ui.label(p, label, 38, 13, 130, 15, 11, Color("#322a1c"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	return g

func _make_ghost(id: String) -> Control:
	var g := Control.new()
	g.size = Vector2(96, 94)
	g.mouse_filter = Control.MOUSE_FILTER_STOP
	g.mouse_default_cursor_shape = Control.CURSOR_DRAG
	layer_ghost.add_child(g)
	var out := GameData.outcome(id)
	var bg := Color("#3f6045") if id == "pass" else (Color("#8a5b22") if id == "revise" else Color("#7f2d26"))
	var handle := PixelPanel.new()
	handle.bg_color = Color("#6b4a2c")
	handle.border_width = 3
	handle.border_color = Color("#100c08")
	handle.stripe_width = 3
	handle.stripe_color = Color(0, 0, 0, 0.18)
	handle.inner_highlight = Color("#9a6b3f")
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(handle)
	Ui.place(handle, 33, 0, 30, 22)
	var brass := PixelPanel.new()
	brass.bg_color = Color("#b08a4a")
	brass.border_width = 1
	brass.border_color = Color("#4e341c")
	brass.inner_highlight = Color("#e0c07c")
	brass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(brass)
	Ui.place(brass, 31, 21, 34, 6)
	var base := PixelPanel.new()
	base.bg_color = Color("#2a2118")
	base.border_width = 2
	base.border_color = Color("#0d0906")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(base)
	Ui.place(base, 5, 27, 86, 9)
	# faint impression offset behind the stamp, so it feels like wet ink
	var ghost := PixelPanel.new()
	ghost.bg_color = Color(bg.r, bg.g, bg.b, 0.16)
	ghost.border_width = 3
	ghost.border_color = Color(bg.r, bg.g, bg.b, 0.22)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(ghost)
	Ui.place(ghost, 7, 42, 86, 42)
	ghost.rotation = deg_to_rad(-4)
	var face := PixelPanel.new()
	face.bg_color = bg
	face.border_width = 4
	face.border_color = Color("#1a120c")
	face.shadow_offset = Vector2(7, 9)
	face.shadow_color = Color(0, 0, 0, 0.36)
	face.inner_highlight = Color(1, 1, 1, 0.2)
	face.bottom_edge = Color(0, 0, 0, 0.28)
	face.bottom_edge_height = 3
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(face)
	Ui.place(face, 0, 36, 90, 46)
	Ui.label(face, str(out.get("stamp", "")), 1, 2, 90, 32, 20, Color(0, 0, 0, 0.32), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	Ui.label(face, str(out.get("stamp", "")), 0, 0, 90, 32, 20, Color("#f7ead0"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	Ui.label(face, str(out.get("sub", "")), 0, 30, 90, 11, 7, Color(1, 1, 1, 0.62), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.24)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(shadow)
	Ui.place(shadow, 12, 86, 72, 5)
	g.rotation = deg_to_rad(-7)
	g.pivot_offset = Vector2(48, 47)
	g.scale = Vector2(0.88, 0.88)
	g.position = get_global_mouse_position() - Vector2(48, 47)
	var tw := create_tween()
	tw.tween_property(g, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return g

func _loose_at(pos: Vector2) -> Control:
	return desktop.at_point(pos)

func _loose_over_rect(rect: Rect2) -> bool:
	return desktop.overlaps(rect)

func _over_rail(pos: Vector2) -> bool:
	return Rect2(1038, 375, 220, 396).has_point(pos)

func _over_desk(pos: Vector2) -> bool:
	# Loose papers may be dropped anywhere on the upper desk, not only below
	# the folder. The rail has its own drop target and is excluded by callers.
	return Rect2(5, 61, 1370, 799).has_point(pos)

func _reset_floating_panels() -> void:
	for node in panel_home.keys():
		if is_instance_valid(node):
			node.position = panel_home[node]
			node.z_index = 0

func _reset_all_layout() -> void:
	_click_fx(get_global_mouse_position())
	_play("click")
	if drag_state.has("base_shadow"):
		var pp := drag_state.get("node") as PixelPanel
		if pp != null:
			pp.shadow_offset = drag_state.get("base_shadow", Vector2.ZERO)
	_end_drag_fx()
	_rail_glow(false)
	for node in panel_home.keys():
		if is_instance_valid(node):
			node.position = panel_home[node]
			node.z_index = 0
	if drag_state.get("ghost") != null and is_instance_valid(drag_state.get("ghost")):
		drag_state.get("ghost").queue_free()
	drag_state = {}
	for c in layer_loose.get_children():
		c.modulate.a = 1.0
	show_toast("已归位")

# ============================================================
# LOOSE ATTACHMENTS
# ============================================================
func open_loose(id: String, at: Vector2 = Vector2(-1, -1)) -> void:
	if id.begins_with("req:"):
		var req_parts := id.split(":")
		if req_parts.size() >= 3:
			open_request_doc_file(req_parts[1], req_parts[2], at)
		return
	if current.is_empty():
		return
	var item: Dictionary = {}
	for m in GameData.materials:
		if str(m.get("id", "")) == id:
			item = m
			break
	if item.is_empty() or !GameData.is_material_unlocked(item, day):
		return
	if loose_files.has(id):
		var existing: Control = loose_files[id]
		if is_instance_valid(existing):
			desktop.bring_front(existing)
		return
	var win = DocumentWindowScene.instantiate()
	layer_loose.add_child(win)
	win.configure(false)
	var head: PixelPanel = win.header
	var tab := PixelPanel.new()
	tab.bg_color = Color("#d8c69d")
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.border_width = 1
	tab.border_color = Color("#1b160f")
	head.add_child(tab)
	Ui.place(tab, 7, 7, 18, 18)
	var tab_icon := MaterialIconCtl.new()
	tab.add_child(tab_icon)
	Ui.place(tab_icon, 1, 1, 16, 16)
	tab_icon.configure(MaterialIconCtl.key_for_doc(item), Color("#5d482d"))
	Ui.label(head, str(item.get("type", "")), 30, 11, 0, 10, 6, Color("#c2b28e"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, false)
	Ui.label(head, str(item.get("label", "")), 96, 8, 280, 16, 11, Color("#f2e5c5"), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, false)
	var body: ScrollContainer = win.body
	var mc := Ui.margin(body, 11, 14, 10, 14)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var doc := Docs.render(id, current, 430)
	mc.add_child(doc)
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	var count := loose_files.size()
	var left := 1038.0 - 460.0 - 16.0 - count * 16.0
	var top := 381.0 + count * 18.0
	if at.x >= 0.0:
		left = at.x - 28.0
		top = at.y - 18.0
	left = clampf(left, 8, W - 468)
	top = clampf(top, 64, H - 358)
	win.position = Vector2(left, top)
	desktop.register(id, win, win.position)
	win.modulate.a = 0.0
	win.scale = Vector2(0.94, 0.94)
	win.pivot_offset = Vector2(230, 175)
	var target_pos: Vector2 = win.position
	win.position = target_pos + Vector2(0, 8)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(win, "modulate:a", 1.0, 0.16)
	tw.tween_property(win, "scale", Vector2.ONE, 0.18)
	tw.tween_property(win, "position", target_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_play("page")
	render_materials()

func close_loose(id: String, archived: bool = false) -> void:
	if !loose_files.has(id):
		return
	note_request_window_closed(id)
	desktop.close(id)
	_play("drop")
	if archived:
		_click_fx(get_global_mouse_position())
	if !drag_state.is_empty() and str(drag_state.get("kind", "")) == "loose" and str(drag_state.get("id", "")) == id:
		drag_state = {}
	render_materials()
	if archived:
		var label := id
		if id.begins_with("req:"):
			var parts := id.split(":")
			if parts.size() >= 3 and requests != null:
				var task: Dictionary = requests.get_request(parts[1])
				for d in task.get("documents", []):
					if str(d.get("id", "")) == parts[2]:
						label = str(d.get("tab", "学生材料"))
						break
		else:
			for m in GameData.materials:
				if str(m.get("id", "")) == id:
					label = str(m.get("label", id))
					break
		show_toast("归档：%s" % label)

# ============================================================
# KEYBOARD
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	InputRouter.handle_unhandled(self, event)

func _tab_index() -> int:
	for i in range(GameData.tabs.size()):
		if str(GameData.tabs[i].get("id", "")) == tab:
			return i
	return 0

# ============================================================
# COMMAND LINE
# ============================================================
# Dev states, screenshots and contract tests live in tests/TestMain.gd,
# which is excluded from the Windows export. The shipped game keeps only the
# tiny smoke check used by tools/smoke_export.ps1.
func _apply_cmdline() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--state=smoke":
			Smoke.run(self)
