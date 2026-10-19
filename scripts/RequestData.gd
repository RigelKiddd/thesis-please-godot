extends RefCounted

## Administrative desk requests (scholarship / honors thesis / leave slip).
## Data lives in assets/requests.json so the original data.json stays untouched.
## Requests are authored as packets: a list of documents plus the criteria the
## player should check before approving or returning the packet.

const PATH := "res://assets/requests.json"

static var requests: Array = []
static var loaded := false

static func load_all() -> void:
	if loaded:
		return
	loaded = true
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_warning("RequestData: missing %s" % PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("RequestData: bad JSON")
		return
	var d: Dictionary = parsed
	var arr: Array = d.get("requests", [])
	for r in arr:
		if typeof(r) != TYPE_DICTIONARY:
			continue
		if str(r.get("id", "")) == "" or int(r.get("day", 0)) < 1:
			continue
		requests.append(r)

static func reload() -> void:
	requests.clear()
	loaded = false
	load_all()

static func for_day(day_index: int) -> Array:
	load_all()
	var out: Array = []
	for r in requests:
		if int(r.get("day", 0)) != day_index + 1:
			continue
		var row: Dictionary = r.duplicate(true)
		var idx := _resolve_student_index(row, day_index)
		var s: Dictionary = {}
		if idx >= 0:
			s = GameData.student(day_index, idx)
		row["queueIndex"] = idx
		row["applicantIndex"] = idx
		if !s.is_empty():
			var o: Dictionary = s.get("official", {})
			row["applicant"] = str(s.get("name", ""))
			row["studentId"] = str(o.get("id", ""))
			row["major"] = str(o.get("major", ""))
			row["college"] = str(o.get("college", ""))
			row["clazz"] = str(o.get("clazz", ""))
			row["advisor"] = str(o.get("advisor", ""))
		row["dayDate"] = str(GameData.day(day_index).get("date", ""))
		row = _fill_value(row, s, day_index) as Dictionary
		out.append(row)
	return out

## Stable identity first; legacy content only has applicantIndex.
static func _resolve_student_index(row: Dictionary, day_index: int) -> int:
	var applicant_id := str(row.get("applicantId", ""))
	if applicant_id != "":
		for i in range(GameData.student_count(day_index)):
			var s := GameData.student(day_index, i)
			if str(s.get("id", "")) == applicant_id:
				return i
	var legacy := int(row.get("applicantIndex", -1))
	if legacy >= 0 and legacy < GameData.student_count(day_index):
		return legacy
	return -1

static func _fill_value(value: Variant, s: Dictionary, day_index: int) -> Variant:
	match typeof(value):
		TYPE_STRING:
			return _fill(str(value), s, day_index)
		TYPE_ARRAY:
			var arr: Array = []
			for item in value:
				arr.append(_fill_value(item, s, day_index))
			return arr
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key in value.keys():
				out[key] = _fill_value(value[key], s, day_index)
			return out
	return value

static func _fill(text: String, s: Dictionary, day_index: int) -> String:
	var date := str(GameData.day(day_index).get("date", ""))
	if s.is_empty():
		return text.replace("{{cover_title}}", "—").replace("{{dup_rate}}", "—").replace("{{form_rate}}", "—") \
			.replace("{{name}}", "—").replace("{{studentId}}", "—").replace("{{major}}", "—") \
			.replace("{{clazz}}", "—").replace("{{college}}", "—").replace("{{advisor}}", "—") \
			.replace("{{dayDate}}", date)
	var dup: Dictionary = s.get("dup", {})
	var official: Dictionary = s.get("official", {})
	var rate := float(dup.get("rate", 0.0))
	var form_rate := snappedf(rate + 5.6, 0.1)
	return text.replace("{{cover_title}}", str(s.get("cover", {}).get("title", ""))) \
		.replace("{{dup_rate}}", "%.1f" % rate) \
		.replace("{{form_rate}}", "%.1f" % form_rate) \
		.replace("{{name}}", str(s.get("name", ""))) \
		.replace("{{studentId}}", str(official.get("id", ""))) \
		.replace("{{major}}", str(official.get("major", ""))) \
		.replace("{{clazz}}", str(official.get("clazz", ""))) \
		.replace("{{college}}", str(official.get("college", ""))) \
		.replace("{{advisor}}", str(official.get("advisor", ""))) \
		.replace("{{dayDate}}", date)

static func count() -> int:
	load_all()
	return requests.size()
