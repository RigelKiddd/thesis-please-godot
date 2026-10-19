extends RefCounted

## Annotation bookkeeping + anchor resolution.
##
## The controller owns the marks/awards for the current student. Main.gd keeps
## the drawing and does the actual circle gesture; this object decides what the
## circle hit, how much it is worth, and what a near miss should say.
##
## Anchors are resolved from the controls rendered by Docs.gd (`meta("anchor")`).
## Anything a document cannot tag yet falls back to the static AuditRegions table.

const AWARD := 20
const NEAR_MISS_PX := 56.0

var marks := {}          # tab_id -> Array[Dictionary]
var found := {}          # defect_key -> true
var awarded := 0         # perf bonus held by this student's marks
var count := 0
var attempts := []       # every circle attempt: hit or miss, for the complaint replay

func reset() -> void:
	marks.clear()
	found.clear()
	attempts.clear()
	awarded = 0
	count = 0

func has_key(key: String) -> bool:
	return found.has(key)

func has_group(group: String) -> bool:
	for tab_id in marks.keys():
		for m in marks[tab_id]:
			if str(m.get("group", "")) == group:
				return true
	return false

func has_anchor(anchor: String) -> bool:
	for tab_id in marks.keys():
		for m in marks[tab_id]:
			if str(m.get("anchor", "")) == anchor:
				return true
	return false

func group_anchors(group: String) -> Array:
	var out: Array = []
	for tab_id in marks.keys():
		for m in marks[tab_id]:
			if str(m.get("group", "")) == group:
				out.append(str(m.get("anchor", "")))
	return out

func add_mark(tab_id: String, defect: Dictionary, bbox: Rect2, seed: float,
		tag_x: float, tag_y: float, tag_w: float, label: String) -> Dictionary:
	var key := key_for(defect)
	var mark := {
		"anchor": str(defect.get("anchor", "")),
		"group": str(defect.get("group", "")),
		"rule": str(defect.get("rule", "")),
		"label": label,
		"rect": bbox,
		"seed": seed,
		"tag_x": tag_x,
		"tag_y": tag_y,
		"tag_w": tag_w,
		"awarded": true,
	}
	if !marks.has(tab_id):
		marks[tab_id] = []
	marks[tab_id].append(mark)
	found[key] = true
	awarded += AWARD
	count += 1
	record_attempt(tab_id, bbox.get_center(), defect, label, true)
	return mark

func undo(tab_id: String) -> Dictionary:
	if !marks.has(tab_id) or marks[tab_id].is_empty():
		return {}
	var mark: Dictionary = marks[tab_id].pop_back()
	found.erase(key_for(mark))
	count = max(0, count - 1)
	if bool(mark.get("awarded", false)):
		awarded = max(0, awarded - AWARD)
	# The replay keeps the gesture even if it is undone; that is what a
	# complaint would have on file.
	return mark

func clear_tab(tab_id: String) -> int:
	if !marks.has(tab_id):
		return 0
	var refund := 0
	for mark in marks[tab_id]:
		found.erase(key_for(mark))
		count = max(0, count - 1)
		if bool(mark.get("awarded", false)):
			refund += AWARD
	marks.erase(tab_id)
	awarded = max(0, awarded - refund)
	return refund

func take_refund() -> int:
	var refund := awarded
	awarded = 0
	return refund

func all_marks() -> Array:
	var out: Array = []
	for tab_id in marks.keys():
		for m in marks[tab_id]:
			var copy: Dictionary = m.duplicate()
			copy["tab"] = tab_id
			out.append(copy)
	return out

func record_attempt(tab_id: String, center: Vector2, defect: Dictionary, label: String, hit: bool) -> void:
	attempts.append({
		"tab": tab_id,
		"anchor": str(defect.get("anchor", "")),
		"group": str(defect.get("group", "")),
		"label": label,
		"hit": hit,
		"center": center,
	})
	if attempts.size() > 24:
		attempts.pop_front()

func attempt_log() -> Array:
	return attempts.duplicate(true)

# ---------------------------------------------------------------- anchors

static func key_for(d: Dictionary) -> String:
	return "%s#%s#%s" % [str(d.get("anchor", "")), str(d.get("rule", "")), str(d.get("label", ""))]

static func find_control(node: Node, anchor: String) -> Control:
	for c in node.get_children():
		if c.is_queued_for_deletion():
			continue
		if c is Control and str(c.get_meta("anchor", "")) == anchor:
			return c
		var nested := find_control(c, anchor)
		if nested != null:
			return nested
	return null

static func rect_for(anchor: String, tab_id: String, doc_box: Node, content: Control) -> Rect2:
	if doc_box != null and content != null and content.is_inside_tree() and doc_box.is_inside_tree():
		var c := find_control(doc_box, anchor)
		if c != null:
			var gr := c.get_global_rect()
			if gr.size.x > 0.0 and gr.size.y > 0.0:
				return Rect2(gr.position - content.get_global_position(), gr.size)
	if AuditRegions.supports(anchor):
		return AuditRegions.rect(tab_id, anchor)
	return Rect2()

static func rect_distance(r: Rect2, p: Vector2) -> float:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return INF
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return sqrt(dx * dx + dy * dy)

static func hit_test(center: Vector2, tab_id: String, defects: Array,
		doc_box: Node, content: Control, found_keys: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_area := INF
	for d in defects:
		var key := key_for(d)
		if found_keys.has(key):
			continue
		var r := rect_for(str(d.get("anchor", "")), tab_id, doc_box, content)
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			continue
		if r.has_point(center):
			var area := r.size.x * r.size.y
			if area < best_area:
				best_area = area
				best = d
	return best

static func near_miss(center: Vector2, tab_id: String, defects: Array,
		doc_box: Node, content: Control, found_keys: Dictionary, max_dist: float = NEAR_MISS_PX) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := max_dist
	for d in defects:
		if found_keys.has(key_for(d)):
			continue
		var r := rect_for(str(d.get("anchor", "")), tab_id, doc_box, content)
		var dist := rect_distance(r, center)
		if dist < best_dist:
			best_dist = dist
			best = d
	if best.is_empty():
		return {}
	return {"defect": best, "distance": best_dist}
