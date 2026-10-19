extends RefCounted

## Contracts at the new seams: state ownership, save isolation and window reuse.
static func run(view: Control) -> Array:
	var errors: Array = []
	var state = preload("res://scripts/RunState.gd").new()
	var requests = preload("res://scripts/RequestController.gd").new(state)
	requests.done["probe"] = true
	if !state.request_done.has("probe"):
		errors.append("requests must share RunState")
	state.flags["revisited"] = true
	state.record_decision({"official": {"id": "student-1"}}, "revise", true)
	var saved: Dictionary = state.day_snapshot()
	state.flags["revisited"] = false
	state.decisions[0]["verdict"] = "pass"
	if !saved.flags.revisited or saved.decisions[0].verdict != "revise":
		errors.append("save snapshot aliases live state")
	state.reset()
	state.restore_day(saved, 7)
	if !state.flags.revisited or state.decisions[0].verdict != "revise" or !state.request_done.is_empty():
		errors.append("state restore/reset contract")
	var user_path: String = preload("res://scripts/UserData.gd").root()
	if user_path.begins_with("user://") or !user_path.contains("build"):
		errors.append("test runner must isolate user data")
	var manager = preload("res://scripts/DesktopWindowManager.gd").new()
	var scene = preload("res://scenes/ui/DocumentWindow.tscn")
	var a = scene.instantiate()
	var b = scene.instantiate()
	view.layer_loose.add_child(a)
	view.layer_loose.add_child(b)
	a.configure(false)
	b.configure(true, true)
	manager.register("a", a, Vector2(60, 100))
	manager.register("b", b, Vector2(60, 100))
	if manager.at_point(Vector2(100, 150)) != b:
		errors.append("hit testing must choose topmost window")
	manager.next_z = 1000
	manager.bring_front(a)
	if manager.at_point(Vector2(100, 150)) != a or a.z_index >= 1000:
		errors.append("window stacking must renumber safely")
	manager.set_pinned("a", true)
	manager.move_window(a, Vector2(200, 200))
	if a.position != Vector2(60, 100):
		errors.append("pinned window moved")
	manager.set_pinned("a", false)
	manager.move_window(a, Vector2(-50, -50))
	if a.position != manager.bounds.position:
		errors.append("window moved outside desktop")
	if !manager.arrange_pair("a", "b") or a.get_rect().intersects(b.get_rect()):
		errors.append("side-by-side arrangement overlaps")
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(100, 1000)
	a.body.add_child(tall)
	await view.get_tree().process_frame
	await view.get_tree().process_frame
	a.body.scroll_vertical = 75
	var position: Vector2 = a.position
	manager.close("a", false)
	await view.get_tree().process_frame
	var reopened = scene.instantiate()
	view.layer_loose.add_child(reopened)
	reopened.configure(false)
	var tall_again := Control.new()
	tall_again.custom_minimum_size = Vector2(100, 1000)
	reopened.body.add_child(tall_again)
	manager.register("a", reopened, Vector2(800, 300))
	await view.get_tree().process_frame
	await view.get_tree().process_frame
	if reopened.position != position or reopened.scroll_value() != 75:
		errors.append("reopened window lost position/scroll")
	var archives: Array = []
	manager.archive_requested.connect(func(id): archives.append(id))
	reopened.get_node("Header/Archive").pressed.emit()
	if archives != ["a"]:
		errors.append("scene archive intent must reach manager")
	manager.clear()
	if !manager.windows.is_empty() or !manager.positions.is_empty():
		errors.append("clear must reset per-case window state")
	return errors
