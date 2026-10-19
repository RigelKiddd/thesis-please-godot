extends RefCounted

const UserDataCtl := preload("res://scripts/UserData.gd")

## Local-only playtest metrics. Never sends anything over the network.
## user://session.json holds the last N runs; each run is also updated after
## every student/request so a crash does not lose the whole session.

static var DEFAULT_PATH := UserDataCtl.file("session.json")
const VERSION := 1
const MAX_SESSIONS := 30
const SettingsCtl := preload("res://scripts/SettingsStore.gd")

static var path := DEFAULT_PATH

var current: Dictionary = {}
var run_active := false
var student_ctx: Dictionary = {}
var student_started_ms := 0

func reset() -> void:
	current = {}
	run_active = false
	student_ctx = {}
	student_started_ms = 0

func begin_run(start_day: int = 0) -> void:
	current = {
		"id": "%d-%d" % [int(Time.get_unix_time_from_system()), randi() % 100000],
		"version": VERSION,
		"startedAt": Time.get_unix_time_from_system(),
		"startDay": start_day + 1,
		"students": [],
		"requests": [],
		"complaints": 0,
		"restarts": 0,
		"finished": false,
	}
	run_active = true
	student_ctx = {}
	student_started_ms = 0
	_write()

func ensure_run(day: int) -> void:
	if !run_active:
		begin_run(day)

func begin_student(day: int, stu: int, student: Dictionary) -> void:
	if !SettingsCtl.metrics_enabled:
		return
	ensure_run(day)
	student_ctx = {
		"day": day + 1,
		"stu": stu + 1,
		"name": str(student.get("name", "")),
		"startedAt": Time.get_unix_time_from_system(),
	}
	student_started_ms = Time.get_ticks_msec()

func finish_student(correct: bool, hits: int, wrong: int, missed: int,
		empty_circles: int, asked_hint: bool, chat_style: String) -> void:
	if !SettingsCtl.metrics_enabled or student_ctx.is_empty():
		return
	var row := student_ctx.duplicate(true)
	row["seconds"] = snappedf(maxf(0.0, float(Time.get_ticks_msec() - student_started_ms) / 1000.0), 0.1)
	row["correct"] = correct
	row["annotationHits"] = hits
	row["annotationWrong"] = wrong
	row["annotationMissed"] = missed
	row["emptyCircles"] = empty_circles
	row["askedHint"] = asked_hint
	row["chatStyle"] = chat_style
	var arr: Array = current.get("students", [])
	arr.append(row)
	current["students"] = arr
	student_ctx = {}
	student_started_ms = 0
	_write()

func record_request(id: String, kind: String, correct: bool) -> void:
	if !SettingsCtl.metrics_enabled or current.is_empty():
		return
	var reqs: Array = current.get("requests", [])
	reqs.append({
		"id": id,
		"kind": kind,
		"correct": correct,
		"at": Time.get_unix_time_from_system(),
	})
	current["requests"] = reqs
	_write()

func record_complaint() -> void:
	if !SettingsCtl.metrics_enabled or current.is_empty():
		return
	current["complaints"] = int(current.get("complaints", 0)) + 1
	_write()

func record_restart() -> void:
	if !SettingsCtl.metrics_enabled or current.is_empty():
		return
	current["restarts"] = int(current.get("restarts", 0)) + 1
	_write()

func finish_run(perf: int, rep: int) -> void:
	if !SettingsCtl.metrics_enabled or current.is_empty():
		return
	current["finished"] = true
	current["endedAt"] = Time.get_unix_time_from_system()
	current["perf"] = perf
	current["rep"] = rep
	current["totals"] = _totals(current)
	_write()
	run_active = false

func summary() -> Dictionary:
	return _totals(current)

func _totals(d: Dictionary) -> Dictionary:
	var hits := 0
	var wrong := 0
	var missed := 0
	var empty := 0
	var hints := 0
	for s in d.get("students", []):
		hits += int(s.get("annotationHits", 0))
		wrong += int(s.get("annotationWrong", 0))
		missed += int(s.get("annotationMissed", 0))
		empty += int(s.get("emptyCircles", 0))
		if bool(s.get("askedHint", false)):
			hints += 1
	var req_ok := 0
	var req_bad := 0
	for r in d.get("requests", []):
		if bool(r.get("correct", false)):
			req_ok += 1
		else:
			req_bad += 1
	return {
		"students": d.get("students", []).size(),
		"correct": int(d.get("students", []).size()) - int(d.get("complaints", 0)),
		"complaints": int(d.get("complaints", 0)),
		"restarts": int(d.get("restarts", 0)),
		"annotationHits": hits,
		"annotationWrong": wrong,
		"annotationMissed": missed,
		"emptyCircles": empty,
		"hintStudents": hints,
		"requestOk": req_ok,
		"requestBad": req_bad,
	}

func _write() -> void:
	if !SettingsCtl.metrics_enabled or current.is_empty():
		return
	var root: Dictionary = {"version": VERSION, "sessions": []}
	var f := FileAccess.open(path, FileAccess.READ)
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			root = parsed
			if typeof(root.get("sessions", [])) != TYPE_ARRAY:
				root["sessions"] = []
	var sessions: Array = root.get("sessions", [])
	var found := false
	for i in range(sessions.size()):
		if str(sessions[i].get("id", "")) == str(current.get("id", "")):
			sessions[i] = current.duplicate(true)
			found = true
			break
	if !found:
		sessions.append(current.duplicate(true))
	while sessions.size() > MAX_SESSIONS:
		sessions.pop_front()
	root["sessions"] = sessions
	var tmp := path + ".tmp"
	var out := FileAccess.open(tmp, FileAccess.WRITE)
	if out == null:
		return
	out.store_string(JSON.stringify(root, "\t"))
	out.flush()
	out.close()
	var dir := DirAccess.open(path.get_base_dir())
	if dir != null:
		dir.remove(path)
		dir.rename(tmp, path)
