extends "res://scripts/RequestDesk.gd"

## FlowController — day, student and ending transitions.
## Main owns the concrete render/audio implementations; the empty virtual
## methods below are overridden there, so this layer can sequence the flow.

const GameState := preload("res://scripts/GameState.gd")
const StampCtl := preload("res://scripts/StampController.gd")

var tab := "cover"
var rep: int:
	get:
		return run_state.rep
	set(value):
		run_state.rep = value
var daily_correct: int:
	get:
		return run_state.daily_correct
	set(value):
		run_state.daily_correct = value
var daily_wrong: int:
	get:
		return run_state.daily_wrong
	set(value):
		run_state.daily_wrong = value
var total_correct: int:
	get:
		return run_state.total_correct
	set(value):
		run_state.total_correct = value
var total_wrong: int:
	get:
		return run_state.total_wrong
	set(value):
		run_state.total_wrong = value
var perfect_days: int:
	get:
		return run_state.perfect_days
	set(value):
		run_state.perfect_days = value
var day_start_perf: int:
	get:
		return run_state.day_start_perf
	set(value):
		run_state.day_start_perf = value
var clock: int:
	get:
		return run_state.clock
	set(value):
		run_state.clock = value
var selected := ""
var last_audit: Dictionary:
	get:
		return run_state.last_audit
	set(value):
		run_state.last_audit = value
var last_outcome: String:
	get:
		return run_state.last_outcome
	set(value):
		run_state.last_outcome = value

func update_hud() -> void:
	pass

func render_queue() -> void:
	pass

func load_student(instant: bool = false) -> void:
	pass

func _show_modal(card: Control, _paper_id: String = "") -> void:
	pass

func _hide_modal() -> void:
	pass

func _reset_floating_panels() -> void:
	pass

func _clear_story_mode() -> void:
	pass

func _reset_stamp_target() -> void:
	pass

func _abort_allocation() -> void:
	pass

func show_toast(text: String, kind: String = "") -> void:
	pass

func _play(name: String) -> void:
	pass

func _state_dict() -> Dictionary:
	return {}

func _show_day_intro() -> void:
	_reset_floating_panels()
	phase = "intro"
	stu = 0
	clock = 540
	update_hud()
	render_rules()
	render_queue()
	load_student(true)
	var new_rules: Array = []
	for g in GameData.rules:
		if int(g.get("day", 0)) == day + 1:
			new_rules.append(g)
	var new_mats: Array = []
	for m in GameData.materials:
		if int(m.get("unlockDay", 0)) == day + 1:
			new_mats.append(m)
	var d := GameData.day(day)
	_show_modal(Modals.day_intro(day, d, new_rules, new_mats, Callable(self, "_on_modal_action")), "dayintro")

func _begin_day() -> void:
	_hide_modal()
	_close_request_paper()
	_reset_floating_panels()
	_abort_allocation()
	if story_active:
		_clear_story_mode()
	phase = "review"
	stu = 0
	daily_correct = 0
	daily_wrong = 0
	day_start_perf = perf
	clock = 540
	selected = ""
	last_audit = {}
	last_outcome = ""
	day_annotation_count = 0
	day_chat_replies = []
	chat_student = {}
	requests.begin_day(day)
	face_prompted_for = -1
	request_resume_end = false
	request_resolving = false
	metrics.ensure_run(day)
	update_hud()
	render_rules()
	render_queue()
	load_student()
	var new_today: Array = []
	for m in GameData.materials:
		if int(m.get("unlockDay", 0)) == day + 1:
			new_today.append(m)
	var msg := ""
	if new_today.size() > 0:
		var names: Array = []
		for m in new_today:
			names.append(str(m.get("label", "")))
		msg = "新附件：%s" % "、".join(names)
	var rq: Array = requests.pending()
	if rq.size() > 0:
		var rt := "今日待办：%s" % str(rq[0].get("title", ""))
		msg = rt if msg == "" else msg + " · " + rt
	if msg != "":
		show_toast(msg)
	GameState.write(GameState.snapshot(run_state))
	_play("day")

func _next_student() -> void:
	if face_pending():
		show_toast(face_block_message(), "warn")
		_open_request()
		return
	if rep <= 0:
		_show_game_over()
		return
	stu += 1
	if stu >= GameData.student_count(day):
		_end_day()
		return
	phase = "review"
	selected = ""
	tab = "cover"
	_reset_stamp_target()
	load_student()


func _end_day() -> void:
	if requests != null and requests.pending_count() > 0:
		request_resume_end = true
		var rq: Dictionary = requests.first_pending()
		show_toast("还有待办：%s" % str(rq.get("title", "")), "warn")
		_open_request()
		return
	request_resume_end = false
	phase = "dayend"
	clock = 17 * 60 + 10
	stu = GameData.student_count(day)
	var perfect := daily_wrong == 0
	if perfect:
		perf += 300
		rep = min(5, rep + 1)
		perfect_days += 1
	update_hud()
	render_queue()
	_show_modal(Modals.shift(day, GameData.day(day), _state_dict(), Callable(self, "_on_modal_action")), "shift")
	_play("day")


func _show_game_over() -> void:
	phase = "gameover"
	_show_modal(Modals.game_over(_state_dict(), Callable(self, "_on_modal_action")), "gameover")

func _show_ending() -> void:
	phase = "ending"
	stu = GameData.student_count(day)
	update_hud()
	render_queue()
	var rank := _rank()
	var st := _state_dict()
	st["ending_note"] = StampCtl.ending_note(st)
	metrics.finish_run(perf, rep)
	GameState.clear()
	_show_modal(Modals.ending(st, rank, Callable(self, "_on_modal_action")), "ending")
	_play("day")

func _rank() -> Dictionary:
	var fav_total := 0
	for k in run_state.favor:
		fav_total += int(run_state.favor[k])
	var college_total := 0
	for k in run_state.college_favor:
		var e = run_state.college_favor[k]
		if typeof(e) == TYPE_DICTIONARY:
			college_total += int(e.get("advisor", 0)) + int(e.get("director", 0))
		else:
			college_total += int(e)
	if int(run_state.total_wrong) >= 8 and rep <= 2:
		return {
			"rank": "停职调查", "sub": "投诉与误判累计", "stamp": "停职",
			"story": [
				"一周的误判被整理成投诉附件。你交回印章，03 窗口暂时贴上封条。",
				"人情簿还在桌上，但已经没有下一杯茶。"
			]
		}
	if college_total <= -3:
		return {
			"rank": "学院清算", "sub": "六个学部联名", "stamp": "清算",
			"story": [
				"六个学部把账本摊在桌上。你给出去的人情，最后变成一张联名清单。",
				"窗口还在，但门牌换了名字。"
			]
		}
	if fav_total >= 12:
		return {
			"rank": "人情网", "sub": "续聘 · 非正式", "stamp": "人情",
			"story": [
				"你没有拿到最漂亮的绩效，但六个学部都记得你批过的条子。",
				"合同续了。03 窗口的灯，还是你最后一盏关。"
			]
		}
	if perf >= 4300 and rep >= 4:
		return {
			"rank": "长聘副教授", "sub": "聘期通过", "stamp": "长聘",
			"story": [
				"秋季开学，你搬进有窗的办公室。新一届学生已经在门外排队。"
			]
		}
	if perf >= 3000:
		return {
			"rank": "续聘一年", "sub": "聘期考核通过", "stamp": "续聘",
			"story": [
				"工位保留一年，03 窗口明天继续开。"
			]
		}
	if perf >= 1800:
		return {
			"rank": "讲师留用", "sub": "合同续一年", "stamp": "留用",
			"story": [
				"合同续了一年。03 窗口还在，材料也还会送来。"
			]
		}
	return {
		"rank": "不再续聘", "sub": "合同到期", "stamp": "解约",
		"story": [
			"合同到期。你交回印章，03 窗口换了人。"
		]
	}

