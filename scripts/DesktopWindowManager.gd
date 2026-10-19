extends RefCounted

## Owns desktop window lifetime, stacking and placement; no task/game rules.
signal archive_requested(id: String)

var windows: Dictionary = {}
var next_z := 1
var positions: Dictionary = {}
var scroll_positions: Dictionary = {}
var pinned: Dictionary = {}
var bounds := Rect2(8, 64, 1364, 788)

func register(id: String, window: Control, at: Vector2) -> void:
	windows[id] = window
	window.set_meta("loose_id", id)
	window.position = constrain(window, positions.get(id, at))
	bring_front(window)
	if window.has_signal("archive_requested"):
		window.connect("archive_requested", func(): archive_requested.emit(id))
	if scroll_positions.has(id) and window.has_method("restore_scroll"):
		window.call_deferred("restore_scroll", int(scroll_positions[id]))

func bring_front(window: Control) -> void:
	for other in windows.values():
		if is_instance_valid(other) and other != window:
			other.modulate = Color(0.74, 0.74, 0.74, 0.92)
	window.modulate = Color.WHITE
	# Renumber before reaching CanvasItem's maximum z range.
	if next_z >= 1000:
		var ordered: Array = windows.values()
		ordered.sort_custom(func(a, b): return a.z_index < b.z_index)
		next_z = 1
		for item in ordered:
			if is_instance_valid(item):
				item.z_index = next_z
				next_z += 1
	window.z_index = next_z
	next_z += 1

func constrain(window: Control, at: Vector2) -> Vector2:
	return Vector2(clampf(at.x, bounds.position.x, maxf(bounds.position.x, bounds.end.x - window.size.x)),
		clampf(at.y, bounds.position.y, maxf(bounds.position.y, bounds.end.y - window.size.y)))

func move_window(window: Control, at: Vector2) -> void:
	var id := str(window.get_meta("loose_id", ""))
	if !bool(pinned.get(id, false)):
		window.position = constrain(window, at)

func at_point(pos: Vector2) -> Control:
	var found: Control = null
	for window in windows.values():
		if is_instance_valid(window) and window.get_global_rect().has_point(pos):
			if found == null or window.z_index > found.z_index:
				found = window
	return found

func overlaps(rect: Rect2) -> bool:
	for window in windows.values():
		if is_instance_valid(window) and window.get_global_rect().intersects(rect):
			return true
	return false

func set_pinned(id: String, value: bool) -> void:
	pinned[id] = value

func arrange_pair(left_id: String, right_id: String) -> bool:
	if left_id == right_id or !windows.has(left_id) or !windows.has(right_id):
		return false
	var left: Control = windows[left_id]
	var right: Control = windows[right_id]
	if left.size.x + right.size.x + 12 > bounds.size.x:
		return false
	left.position = bounds.position
	right.position = Vector2(bounds.position.x + left.size.x + 12, bounds.position.y)
	return true

func snap_window(window: Control) -> void:
	var p := window.position
	var snap := 26.0
	if p.x < bounds.position.x + snap:
		p.x = bounds.position.x
	elif p.x + window.size.x > bounds.end.x - snap:
		p.x = bounds.end.x - window.size.x
	if p.y < bounds.position.y + snap:
		p.y = bounds.position.y
	elif p.y + window.size.y > bounds.end.y - snap:
		p.y = bounds.end.y - window.size.y
	window.position = constrain(window, p)

func close(id: String, animate: bool = true) -> void:
	if !windows.has(id):
		return
	var window: Control = windows[id]
	windows.erase(id)
	if !is_instance_valid(window):
		return
	positions[id] = window.position
	if window.has_method("scroll_value"):
		scroll_positions[id] = window.call("scroll_value")
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !animate:
		window.queue_free()
	else:
		window.pivot_offset = window.size * 0.5
		var tween := window.create_tween().set_parallel(true)
		tween.tween_property(window, "modulate:a", 0.0, 0.12)
		tween.tween_property(window, "scale", Vector2(0.95, 0.95), 0.12)
		tween.chain().tween_callback(window.queue_free)
	if !windows.is_empty():
		var top: Control = null
		for w in windows.values():
			if is_instance_valid(w) and (top == null or w.z_index > top.z_index):
				top = w
		if top != null:
			bring_front(top)

func clear() -> void:
	for id in windows.keys():
		close(str(id), false)
	positions.clear()
	scroll_positions.clear()
	pinned.clear()
	next_z = 1
