extends RefCounted

## Single owner of gameplay state. Views retain forwarding properties during
## migration; controllers and saves share this instance, never a second copy.

var day := 0
var day_annotation_count := 0
var day_chat_replies: Array = []
var chat_student: Dictionary = {}
var annotation_hits := 0
var annotation_wrong := 0
var annotation_missed := 0
var time_saved_total := 0
var phase := "title"
var stu := 0
var perf := 0
var story_active := false
var rep := 5
var daily_correct := 0
var daily_wrong := 0
var total_correct := 0
var total_wrong := 0
var perfect_days := 0
var day_start_perf := 0
var clock := 540
var last_audit: Dictionary = {}
var last_outcome := ""
var stamp_counts := {"pass": 0, "revise": 0, "reject": 0}
var current: Dictionary = {}
var story_scene: Dictionary = {}
var story_doc := 0
var story_choice := -1
var story_result: Dictionary = {}
var story_viewed: Dictionary = {}
var night_log: Array = []
var request_done: Dictionary = {}
var request_decisions: Dictionary = {}
var decisions: Array = []
var flags: Dictionary = {}
# --- between-days allocation (v1.14) ---
var energy := 0
var money := 0
var alloc_offer: Dictionary = {}
var alloc_placed: Dictionary = {}
var alloc_log: Array = []
var favor: Dictionary = {}
var favor_log: Array = []
# --- per-college advisors/directors (v1.15) ---
var college_favor: Dictionary = {}
var college_log: Array = []
var college_letters: Array = []
var night_letters: Array = []
var duty_log: Array = []
var visitor_history: Dictionary = {}
var items: Array = []

func reset() -> void:
	day = 0
	day_annotation_count = 0
	day_chat_replies = []
	chat_student = {}
	annotation_hits = 0
	annotation_wrong = 0
	annotation_missed = 0
	time_saved_total = 0
	phase = "title"
	stu = 0
	perf = 0
	story_active = false
	rep = 5
	daily_correct = 0
	daily_wrong = 0
	total_correct = 0
	total_wrong = 0
	perfect_days = 0
	day_start_perf = 0
	clock = 540
	last_audit = {}
	last_outcome = ""
	stamp_counts = {"pass": 0, "revise": 0, "reject": 0}
	current = {}
	story_scene = {}
	story_doc = 0
	story_choice = -1
	story_result = {}
	story_viewed = {}
	night_log = []
	request_done.clear()
	request_decisions.clear()
	decisions.clear()
	flags.clear()
	energy = 0
	money = 0
	alloc_offer = {}
	alloc_placed.clear()
	alloc_log.clear()
	favor.clear()
	favor_log.clear()
	college_favor.clear()
	college_log.clear()
	college_letters.clear()
	night_letters.clear()
	duty_log.clear()
	visitor_history.clear()
	items = base_items()


static func base_items() -> Array:
	return [
		{"id": "favor", "kind": "favor", "title": "人情簿", "sub": "FAVORS", "consumable": false,
			"style": "ledger", "icon": "ledger", "stock": "LEDGER", "stock_cn": "账本"},
		{"id": "college", "kind": "college", "title": "院系账本", "sub": "COLLEGE", "consumable": false,
			"style": "sealed", "icon": "ledger", "stock": "SEALED", "stock_cn": "密封"},
		{"id": "schedule", "kind": "schedule", "title": "明日安排", "sub": "ROSTER", "consumable": false,
			"style": "cardstock", "icon": "schedule", "stock": "CARDSTOCK", "stock_cn": "卡纸"},
	]


func item_of(id: String) -> Dictionary:
	for item in items:
		if str(item.get("id", "")) == id:
			return item
	return {}


func add_item(item: Dictionary) -> void:
	var id := str(item.get("id", ""))
	if id == "" or !item_of(id).is_empty():
		return
	items.append(item.duplicate(true))


func remove_item(id: String) -> void:
	for i in range(items.size() - 1, -1, -1):
		if str(items[i].get("id", "")) == id:
			items.remove_at(i)


func ensure_base_items() -> void:
	for base in base_items():
		add_item(base)


func record_decision(student: Dictionary, verdict: String, correct: bool) -> void:
	decisions.append({"day": day, "student": str(student.get("official", {}).get("id", "")),
		"position": stu, "verdict": verdict, "correct": correct})

func log_duty(entry: Dictionary) -> void:
	var row := entry.duplicate(true)
	row["day"] = int(row.get("day", day))
	row["clock"] = int(row.get("clock", clock))
	duty_log.append(row)

func day_snapshot() -> Dictionary:
	return {
		"day": day,
		"stu": 0,
		"perf": perf,
		"rep": rep,
		"daily_correct": daily_correct,
		"daily_wrong": daily_wrong,
		"total_correct": total_correct,
		"total_wrong": total_wrong,
		"perfect_days": perfect_days,
		"day_start_perf": day_start_perf,
		"clock": 540,
		"stamp_counts": stamp_counts.duplicate(),
		"night_log": night_log.duplicate(true),
		"story_viewed": story_viewed.duplicate(),
		"annotation_hits": annotation_hits,
		"annotation_wrong": annotation_wrong,
		"annotation_missed": annotation_missed,
		"decisions": decisions.duplicate(true),
		"request_decisions": request_decisions.duplicate(true),
		"flags": flags.duplicate(true),
		"favor": favor.duplicate(true),
		"favor_log": favor_log.slice(maxi(0, favor_log.size() - 120)).duplicate(true),
		"college_favor": college_favor.duplicate(true),
		"college_log": college_log.slice(maxi(0, college_log.size() - 60)).duplicate(true),
		"alloc_log": alloc_log.slice(maxi(0, alloc_log.size() - 8)).duplicate(true),
		"items": items.duplicate(true),
		"duty_log": duty_log.slice(maxi(0, duty_log.size() - 240)).duplicate(true),
		"visitor_history": visitor_history.duplicate(true),
		"energy": 0,
		"money": 0,
	}

func restore_day(d: Dictionary, day_count: int) -> bool:
	if d.is_empty():
		return false
	day = clampi(int(d.get("day", 0)), 0, maxi(0, day_count - 1))
	stu = 0
	perf = int(d.get("perf", 0))
	rep = clampi(int(d.get("rep", 5)), 0, 5)
	daily_correct = int(d.get("daily_correct", 0))
	daily_wrong = int(d.get("daily_wrong", 0))
	total_correct = int(d.get("total_correct", 0))
	total_wrong = int(d.get("total_wrong", 0))
	perfect_days = int(d.get("perfect_days", 0))
	day_start_perf = int(d.get("day_start_perf", 0))
	clock = 540
	stamp_counts = _dict(d.get("stamp_counts", {}), {"pass": 0, "revise": 0, "reject": 0})
	night_log = _array(d.get("night_log", []))
	story_viewed = _dict(d.get("story_viewed", {}), {})
	annotation_hits = int(d.get("annotation_hits", 0))
	annotation_wrong = int(d.get("annotation_wrong", 0))
	annotation_missed = int(d.get("annotation_missed", 0))
	decisions = _array(d.get("decisions", []))
	request_decisions = _dict(d.get("request_decisions", {}), {})
	flags = _dict(d.get("flags", {}), {})
	favor = _dict(d.get("favor", {}), {})
	favor_log = _array(d.get("favor_log", []))
	college_favor = _dict(d.get("college_favor", {}), {})
	college_log = _array(d.get("college_log", []))
	college_letters.clear()
	night_letters.clear()
	duty_log = _array(d.get("duty_log", []))
	visitor_history = _dict(d.get("visitor_history", {}), {})
	items = []
	for raw in _array(d.get("items", [])):
		if typeof(raw) == TYPE_DICTIONARY:
			items.append(raw)
	ensure_base_items()
	alloc_log = _array(d.get("alloc_log", []))
	energy = 0
	money = 0
	alloc_offer = {}
	alloc_placed.clear()
	request_done.clear()
	return true

func favor_of(id: String) -> int:
	return int(favor.get(id, 0))

static func _dict(v: Variant, fallback: Dictionary) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else fallback

static func _array(v: Variant) -> Array:
	return v if typeof(v) == TYPE_ARRAY else []
