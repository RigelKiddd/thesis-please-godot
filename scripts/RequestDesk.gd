extends "res://scripts/DeskView.gd"

## RequestDesk — face-to-face administrative packets.
##
## A packet's documents live in the normal "其他材料" rail and open as ordinary
## draggable paper windows. The first document is the task file: its footer holds
## 批准 / 退回. Supporting documents are just student papers. A packet is tied to
## one queue slot and must be decided before the next student can be called.

const RequestDocsCtl := preload("res://scripts/RequestDocs.gd")
const MaterialPaperCtl := preload("res://scripts/MaterialPaper.gd")
const RequestIconCtl := preload("res://scripts/MaterialIcon.gd")

var phase: String:
	get:
		return run_state.phase
	set(value):
		run_state.phase = value
var stu: int:
	get:
		return run_state.stu
	set(value):
		run_state.stu = value
var perf: int:
	get:
		return run_state.perf
	set(value):
		run_state.perf = value
var story_active: bool:
	get:
		return run_state.story_active
	set(value):
		run_state.story_active = value
var modal_open := false

## Aliases kept for the input router and tests: the main task file window.
var request_task: Dictionary = {}
var request_main_doc_id := ""
var request_resolving := false
var face_prompted_for := -1
var face_auto_present := true

func _task_rows() -> Array:
	if requests == null:
		return []
	return requests.today

func _kind_label(kind: String) -> String:
	match kind:
		"scholarship":
			return "奖学金"
		"honors":
			return "优毕"
		"leave":
			return "请假"
	return "待办"

func _student_name(index: int) -> String:
	if index < 0 or index >= GameData.student_count(day):
		return "—"
	return str(GameData.student(day, index).get("name", "—"))

func _update_request_tray() -> void:
	# v1.13.1: there is no separate task panel. Tasks are files in the rail.
	if request_stack != null:
		request_stack.visible = false

func _request_window_id(task_id: String, doc_id: String) -> String:
	return "req:%s:%s" % [task_id, doc_id]

func _is_request_window(id: String) -> bool:
	return id.begins_with("req:")

func _doc_for(task: Dictionary, doc_id: String) -> Dictionary:
	for doc in task.get("documents", []):
		if str(doc.get("id", "")) == doc_id:
			return doc
	return {}

func _primary_doc(task: Dictionary) -> Dictionary:
	var docs: Array = task.get("documents", [])
	return docs[0] if docs.size() > 0 else {}

func face_task() -> Dictionary:
	if requests == null:
		return {}
	return requests.active_for_student(stu)

## Task whose file is currently open, falling back to the current queue slot.
func shown_face_task() -> Dictionary:
	if !request_task.is_empty() and request_paper != null and is_instance_valid(request_paper):
		return request_task
	return face_task()

func face_pending() -> bool:
	return requests != null and requests.has_pending_for_student(stu)

func face_block_message() -> String:
	var active := face_task()
	if active.is_empty():
		return ""
	return "先和 %s 当面办结「%s」" % [_student_name(stu), str(active.get("title", "待办"))]

## Called after a student reaches the window. Materials are already in the rail;
## this only draws attention to them. It does not open a blocking panel.
func present_for_current_student() -> void:
	if !face_auto_present or requests == null or story_active or modal_open:
		return
	var active: Dictionary = requests.active_for_student(stu)
	if active.is_empty():
		face_prompted_for = -1
		_update_request_tray()
		call("render_queue")
		call("render_materials")
		return
	if face_prompted_for == stu:
		return
	face_prompted_for = stu
	call("show_toast", "轮到 %s：材料已放入「其他材料」" % _student_name(stu), "warn")
	call("render_queue")
	call("render_materials")
	_update_request_tray()

## Public entry points used by the rail, the end-day gate and tests.
func _open_request(req_id: String = "", doc_id: String = "") -> void:
	open_task_file(req_id, doc_id)

func open_task_file(req_id: String = "", doc_id: String = "") -> void:
	if requests == null or story_active or modal_open or request_resolving:
		return
	var task: Dictionary = {}
	if req_id != "":
		task = requests.get_request(req_id)
	if task.is_empty():
		task = requests.active_for_student(stu)
	if task.is_empty():
		task = requests.first_pending()
	if task.is_empty():
		return
	var doc: Dictionary = {}
	if doc_id != "":
		doc = _doc_for(task, doc_id)
	if doc.is_empty():
		doc = _primary_doc(task)
	if doc.is_empty():
		return
	_open_request_doc_window(task, doc)

func open_request_doc_file(task_id: String, doc_id: String, at: Vector2 = Vector2(-1, -1)) -> void:
	var task: Dictionary = requests.get_request(task_id) if requests != null else {}
	if task.is_empty():
		return
	var doc := _doc_for(task, doc_id)
	if doc.is_empty():
		return
	_open_request_doc_window(task, doc, at)

func _open_request_doc_window(task: Dictionary, doc: Dictionary, at: Vector2 = Vector2(-1, -1)) -> void:
	var task_id := str(task.get("id", ""))
	var doc_id := str(doc.get("id", ""))
	var wid := _request_window_id(task_id, doc_id)
	if loose_files.has(wid):
		var existing: Control = loose_files[wid]
		if is_instance_valid(existing):
			desktop.bring_front(existing)
			if bool(existing.get_meta("request_main", false)):
				request_paper = existing
				request_task = task
				request_main_doc_id = doc_id
		return
	var is_main := doc_id == str(_primary_doc(task).get("id", ""))
	requests.current_id = task_id
	var win = DocumentWindowScene.instantiate()
	layer_loose.add_child(win)
	win.configure(true, is_main)
	win.set_meta("request_main", is_main)
	var head: PixelPanel = win.header
	var icon := PixelPanel.new()
	icon.bg_color = Color("#d8c69d")
	icon.border_width = 1
	icon.border_color = Color("#1b160f")
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(icon)
	Ui.place(icon, 7, 7, 20, 20)
	var draw := RequestIconCtl.new()
	icon.add_child(draw)
	Ui.place(draw, 1, 1, 18, 18)
	draw.configure(RequestIconCtl.key_for_doc(doc), Color("#5d482d"))
	var kicker := "行政待办 / TASK FILE" if is_main else "学生材料 / SUPPORTING"
	Ui.label(head, kicker, 33, 5, 300, 9, 6.5, Color("#c2b28e"), Ui.F_PIXEL)
	var title := str(task.get("title", "行政材料")) if is_main else "%s · %s" % [str(task.get("applicant", "学生")), str(doc.get("tab", "学生材料"))]
	Ui.label(head, title, 33, 15, 360, 14, 11, Color("#f2e5c5"), Ui.F_UI_BOLD)
	if is_main:
		var tag := PixelPanel.new()
		tag.bg_color = Color("#a83a2f")
		tag.border_width = 1
		tag.border_color = Color("#481611")
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(tag)
		Ui.place(tag, 398, 9, 30, 16)
		Ui.label(tag, "待办", 0, 0, 30, 16, 8, Color("#f4e3c3"), Ui.F_UI_BOLD, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	var body: ScrollContainer = win.body
	var mc := Ui.margin(body, 10, 10, 10, 12)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sheet := RequestDocsCtl.render(doc, 486.0)
	mc.add_child(sheet)
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	var foot: PixelPanel = win.footer
	if is_main:
		Ui.label(foot, "办理依据", 12, 7, 70, 10, 8, Color("#d6c39d"), Ui.F_UI_BOLD)
		var criteria: Array = []
		for c in task.get("criteria", []):
			criteria.append(str(c))
		var crit := " · ".join(criteria)
		var cl := Ui.label(foot, crit, 72, 5, 436, 30, 8.5, Color("#e2d1ab"), Ui.F_UI, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, true)
		cl.add_theme_constant_override("line_spacing", 1)
		Ui.label(foot, "办结前不能下一位。", 12, 70, 222, 12, 7, Color("#9f8a67"), Ui.F_UI)
		_action_button(foot, "批 准", "request-approve", 246, 58, 128, 44, Color("#3f6045"), Color("#f0e6c8"))
		_action_button(foot, "退 回", "request-return", 382, 58, 124, 44, Color("#8b382b"), Color("#f4e3c3"))
		Ui.label(foot, "A / R", 12, 96, 200, 8, 6, Color("#8c7858"), Ui.F_PIXEL)
	else:
		Ui.label(foot, "学生当面提交 · 可点「归档」收起", 10, 8, 500, 12, 7, Color("#6e5b3c"), Ui.F_PIXEL)

	var count := loose_files.size()
	var left := 1020.0 - 520.0 - 16.0 - count * 16.0
	var top := 390.0 + count * 18.0
	if at.x >= 0.0:
		left = at.x - 30.0
		top = at.y - 18.0
	left = clampf(left, 8, W - 528)
	top = clampf(top, 64, H - 508)
	win.position = Vector2(left, top)
	desktop.register(wid, win, win.position)
	if is_main:
		request_paper = win
		request_task = task
		request_main_doc_id = doc_id
	win.modulate.a = 0.0
	win.scale = Vector2(0.94, 0.94)
	win.pivot_offset = Vector2(260, 250)
	var target_pos: Vector2 = win.position
	win.position = target_pos + Vector2(0, 8)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(win, "modulate:a", 1.0, 0.16)
	tw.tween_property(win, "scale", Vector2.ONE, 0.18)
	tw.tween_property(win, "position", target_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	call("_play", "page")
	call("render_materials")

func _action_button(parent: Node, text: String, action: String, x: float, y: float, w: float, h: float,
		bg: Color, fg: Color) -> void:
	var font := FontVariation.new()
	font.base_font = Ui.F_DOC_BOLD
	font.spacing_glyph = 2
	var b := Ui.button(parent, x, y, w, h, text, 16, fg, bg, Color("#17130d"), font, Vector2(2, 2))
	b.custom_minimum_size = Vector2(w, h)
	b.pressed.connect(func(): _on_request_action(action))

## Called by Main.close_loose so the alias and task context stay in sync.
func note_request_window_closed(id: String) -> void:
	if !_is_request_window(id):
		return
	if request_paper != null and is_instance_valid(request_paper) and str(request_paper.get_meta("loose_id", "")) == id:
		request_paper = null
		request_task = {}
		request_main_doc_id = ""

func _close_request_paper() -> void:
	if request_paper == null or !is_instance_valid(request_paper):
		request_paper = null
		request_task = {}
		request_main_doc_id = ""
		return
	var wid := str(request_paper.get_meta("loose_id", ""))
	if wid != "":
		call("close_loose", wid, false)
	else:
		request_paper.queue_free()
		request_paper = null
		request_task = {}
		request_main_doc_id = ""

func _close_request_windows() -> void:
	request_resolving = false
	var ids: Array = loose_files.keys()
	for id in ids:
		if _is_request_window(str(id)):
			call("close_loose", str(id), false)
	request_paper = null
	request_task = {}
	request_main_doc_id = ""

func _request_stamp(win: Control, approve: bool) -> void:
	if win == null or !is_instance_valid(win):
		return
	var col := Color("#3f6b45") if approve else Color("#8b382b")
	var mark := PixelPanel.new()
	mark.bg_color = Color(0, 0, 0, 0)
	mark.border_width = 4
	mark.border_color = col
	mark.inner_highlight = Color(col.r, col.g, col.b, 0.22)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.z_index = 30
	win.add_child(mark)
	Ui.place(mark, 282, 392, 202, 62)
	mark.pivot_offset = Vector2(101, 31)
	mark.rotation = deg_to_rad(-4 if approve else 3)
	mark.scale = Vector2(1.28, 1.28)
	mark.modulate.a = 0.0
	var text := Ui.label(mark, "批 准" if approve else "退 回", 0, 5, 202, 30, 22, col, Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sub := Ui.label(mark, "教务处 · 2026.05", 0, 38, 202, 12, 7, Color(col.r, col.g, col.b, 0.8), Ui.F_PIXEL, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, false)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mark, "modulate:a", 1.0, 0.08)
	tw.tween_property(mark, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_request_action(action: String) -> void:
	if request_resolving:
		return
	if action == "request-close":
		var active := face_task()
		_close_request_paper()
		call("render_queue")
		call("render_materials")
		if !active.is_empty():
			call("show_toast", "待办未办结：%s" % str(active.get("title", "")), "warn")
		return
	if action != "request-approve" and action != "request-return":
		return
	var approve := action == "request-approve"
	var res: Dictionary = requests.decide(requests.current_id, approve)
	if res.is_empty():
		return
	var req_row: Dictionary = requests.get_request(requests.current_id)
	metrics.record_request(requests.current_id, str(req_row.get("kind", "")), bool(res.get("correct", false)))
	perf += int(res.get("perf", 0))
	var favor_map: Dictionary = req_row.get("favor", {})
	var favor_bits := str(call("_favor_changes", favor_map.get("approve" if approve else "return", {}),
		"待办 · " + str(req_row.get("title", ""))))
	call("update_hud")
	var tag := "处理正确 +¥40" if bool(res.get("correct", false)) else "处理错误 −¥40"
	if favor_bits != "":
		tag += " · 人情 " + favor_bits
	call("show_toast", "%s · %s" % [tag, str(res.get("text", ""))], "good" if bool(res.get("correct", false)) else "warn")
	# Feedback belongs inside the task file: a short, contained ink stamp on
	# the footer. The file closes after the mark has been read; nothing is
	# drawn in desk space, so it cannot leak onto another material window.
	request_resolving = true
	call("_play", "stamp")
	call("_play", "approve" if approve else "return")
	if request_paper != null and is_instance_valid(request_paper):
		_request_stamp(request_paper, approve)
	# Headless tests and the contract suite should not wait for presentation.
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.26).timeout
	_close_request_windows()
	call("render_queue")
	call("render_materials")
	_update_request_tray()
	if requests.pending_count() == 0 and request_resume_end and !story_active:
		request_resume_end = false
		call("_end_day")

func _auto_resolve_requests() -> void:
	if requests == null:
		return
	_close_request_windows()
	var delta: int = requests.resolve_all_correct()
	perf += delta
	request_resume_end = false
	face_prompted_for = -1
	_update_request_tray()
	call("render_queue")
	call("render_materials")
	call("update_hud")
