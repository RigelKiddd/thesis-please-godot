class_name CollegeModel
extends RefCounted

## Per-college advisors and directors (v1.15).
##
## The groups are authored in content/world.json -> collegeGroups and compiled
## into assets/data.json -> COLLEGE_GROUPS.  Every character carries the
## denormalised advisor/director names for documents and the dossier; this
## module maps a college back to its group and describes the reward state.

static func data() -> Dictionary:
	return GameData.college_groups


static func groups() -> Array:
	var rows: Array = data().get("groups", [])
	return rows


static func group(id: String) -> Dictionary:
	for row in groups():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func group_for_college(college: String) -> Dictionary:
	for row in groups():
		var colleges: Array = row.get("colleges", [])
		if college in colleges:
			return row
	return {}


static func group_label(id: String) -> String:
	return str(group(id).get("label", id))


static func default_entry() -> Dictionary:
	return {
		"advisor": 0,
		"director": 0,
		"passes": 0,
		"milestone": false,
		"lastStudent": "",
	}


static func entry(favor: Dictionary, id: String) -> Dictionary:
	if !favor.has(id) or typeof(favor[id]) != TYPE_DICTIONARY:
		favor[id] = default_entry()
	var row: Dictionary = favor[id]
	for key in default_entry():
		if !row.has(key):
			row[key] = default_entry()[key]
	return row


static func favor_cap() -> int:
	return int(data().get("favorCap", 10))


static func milestone_at() -> int:
	return int(data().get("milestoneAt", 2))


static func favor_label(value: int) -> String:
	return AllocationModel.favor_label(value)


static func advisor_name(group_row: Dictionary) -> String:
	return str(group_row.get("advisor", {}).get("name", "导师"))


static func advisor_title(group_row: Dictionary) -> String:
	return str(group_row.get("advisor", {}).get("title", ""))


static func director_name(group_row: Dictionary) -> String:
	return str(group_row.get("director", {}).get("name", "主任"))


static func director_title(group_row: Dictionary) -> String:
	return str(group_row.get("director", {}).get("title", ""))


static func pass_perf(group_row: Dictionary) -> int:
	return int(group_row.get("passPerf", 0))


static func milestone_perf(group_row: Dictionary) -> int:
	return int(group_row.get("milestonePerf", 0))


static func next_reward_text(group_row: Dictionary, row: Dictionary) -> String:
	if bool(row.get("milestone", false)):
		return "学院回礼已结清"
	var need := maxi(0, milestone_at() - int(row.get("passes", 0)))
	if need <= 0:
		return "学院回礼待结算"
	return "再 %d 位规范通过：+¥%s 与感谢函" % [need, Ui.fmt_money(milestone_perf(group_row))]


static func summary(favor: Dictionary) -> String:
	var parts: Array = []
	for row in groups():
		var id := str(row.get("id", ""))
		if !favor.has(id):
			continue
		var e: Dictionary = favor[id]
		if int(e.get("advisor", 0)) == 0 and int(e.get("director", 0)) == 0 and int(e.get("passes", 0)) == 0:
			continue
		parts.append("%s %d/%d" % [str(row.get("label", id)), int(e.get("advisor", 0)), int(e.get("director", 0))])
	return " · ".join(PackedStringArray(parts))


static func top_group(favor: Dictionary) -> Dictionary:
	var best := {}
	var best_score := -1
	for row in groups():
		var e: Dictionary = favor.get(str(row.get("id", "")), {})
		var score := int(e.get("advisor", 0)) + int(e.get("director", 0))
		if score > best_score:
			best_score = score
			best = row
	return best if best_score > 0 else {}
