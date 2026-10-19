extends RefCounted

## Per-day administrative request state. Main owns the perf/UI side effects.

const RequestDataCtl := preload("res://scripts/RequestData.gd")

var today: Array = []
const RunStateCtl := preload("res://scripts/RunState.gd")
var run_state: RefCounted
var done: Dictionary:
	get:
		return run_state.request_done
	set(value):
		run_state.request_done = value

func _init(state: RefCounted = null) -> void:
	run_state = state if state != null else RunStateCtl.new()

var current_id := ""

func begin_day(day_index: int) -> void:
	today = RequestDataCtl.for_day(day_index)
	done.clear()
	current_id = ""

func reset() -> void:
	today.clear()
	done.clear()
	current_id = ""

func pending() -> Array:
	var out: Array = []
	for r in today:
		if !done.has(str(r.get("id", ""))):
			out.append(r)
	return out

## All of today's packets attached to one queue slot, done or not.
func for_student(index: int) -> Array:
	var out: Array = []
	for r in today:
		if int(r.get("queueIndex", -1)) == index:
			out.append(r)
	return out

func pending_for_student(index: int) -> Array:
	var out: Array = []
	for r in today:
		if int(r.get("queueIndex", -1)) == index and !done.has(str(r.get("id", ""))):
			out.append(r)
	return out

func active_for_student(index: int) -> Dictionary:
	var rows := pending_for_student(index)
	return rows[0] if rows.size() > 0 else {}

func has_pending_for_student(index: int) -> bool:
	return !pending_for_student(index).is_empty()

func is_done(id: String) -> bool:
	return done.has(id)

func pending_count() -> int:
	return pending().size()

func total_count() -> int:
	return today.size()

func done_count() -> int:
	return done.size()

func get_request(id: String) -> Dictionary:
	for r in today:
		if str(r.get("id", "")) == id:
			return r
	return {}

func first_pending() -> Dictionary:
	var p := pending()
	if p.is_empty():
		return {}
	current_id = str(p[0].get("id", ""))
	return p[0]

func decide(id: String, approve: bool) -> Dictionary:
	var r := get_request(id)
	if r.is_empty() or done.has(id):
		return {}
	var expected := str(r.get("expected", "return"))
	var correct := (approve and expected == "approve") or (!approve and expected == "return")
	done[id] = true
	run_state.request_decisions[id] = {"approved": approve, "correct": correct}
	var text_key := "approveText" if approve else "returnText"
	return {
		"id": id,
		"correct": correct,
		"perf": 40 if correct else -40,
		"text": str(r.get(text_key, "")),
		"expected": expected,
		"approved": approve,
	}

## Used by the scripted autoday/autoweek runs. Returns the perf delta.
func resolve_all_correct() -> int:
	var delta := 0
	for r in pending():
		var id := str(r.get("id", ""))
		var want_approve := str(r.get("expected", "return")) == "approve"
		var res := decide(id, want_approve)
		delta += int(res.get("perf", 0))
	return delta
