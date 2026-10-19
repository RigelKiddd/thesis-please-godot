extends RefCounted

const UserDataCtl := preload("res://scripts/UserData.gd")

## Run state + per-day autosave.
##
## RunState owns live gameplay values and the day-boundary snapshot contract.
## This module handles storage, backup and schema migrations. Transient UI
## remains outside the snapshot; loading returns to the beginning of the day.

static var PATH := UserDataCtl.file("save.json")
static var TMP_PATH := UserDataCtl.file("save.tmp")
static var BAK_PATH := UserDataCtl.file("save.bak")
const VERSION := 5

static func has_save() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(BAK_PATH)

static func clear() -> void:
	for path in [PATH, TMP_PATH, BAK_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## Atomic-ish write: serialise to save.tmp, keep the previous save as save.bak,
## then replace save.json. A crash between the steps leaves either the old save
## or the backup readable.
static func write(data: Dictionary) -> bool:
	var payload := data.duplicate(true)
	payload["version"] = VERSION
	payload["saved_at"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("GameState: cannot write %s" % TMP_PATH)
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.flush()
	f.close()

	if FileAccess.file_exists(PATH):
		if !_copy(PATH, BAK_PATH):
			push_warning("GameState: cannot refresh %s" % BAK_PATH)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TMP_PATH),
		ProjectSettings.globalize_path(PATH))
	if err != OK:
		# Rename can fail on platforms/filesystems that refuse to replace;
		# fall back to a copy so the new state is still saved.
		if !_copy(TMP_PATH, PATH):
			push_warning("GameState: cannot move %s to %s" % [TMP_PATH, PATH])
			return false
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))
	return true

static func read() -> Dictionary:
	for path in [PATH, BAK_PATH]:
		var d := _read_one(path)
		if !d.is_empty():
			return migrate(d)
	return {}

static func _read_one(path: String) -> Dictionary:
	if !FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parser := JSON.new()
	var error := parser.parse(f.get_as_text())
	f.close()
	if error != OK:
		return {}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	var v := int(d.get("version", 1))
	if v < 1 or v > VERSION:
		return {}
	return d

## Future schema changes go here. Unknown/older keys are left in place and
## missing keys fall back to the defaults in apply().
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	if v < 2:
		d["annotation_hits"] = int(d.get("annotation_hits", 0))
		d["annotation_wrong"] = int(d.get("annotation_wrong", 0))
		d["annotation_missed"] = int(d.get("annotation_missed", 0))
	if v < 3:
		d["decisions"] = d.get("decisions", [])
		d["request_decisions"] = d.get("request_decisions", {})
		d["flags"] = d.get("flags", {})
	if v < 4:
		d["favor"] = d.get("favor", {})
		d["favor_log"] = d.get("favor_log", [])
		d["alloc_log"] = d.get("alloc_log", [])
	if v < 5:
		d["college_favor"] = d.get("college_favor", {})
		d["college_log"] = d.get("college_log", [])
	d["version"] = VERSION
	return d

static func _copy(from_path: String, to_path: String) -> bool:
	var src := FileAccess.open(from_path, FileAccess.READ)
	if src == null:
		return false
	var bytes := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(to_path, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_buffer(bytes)
	dst.flush()
	dst.close()
	return true

## Snapshot the run state that survives a day boundary.
static func _state(source):
	# Compatibility for existing integration fixtures; production passes RunState.
	return source.run_state if source is Control else source

static func snapshot(source) -> Dictionary:
	return _state(source).day_snapshot()

static func apply(source, data: Dictionary) -> bool:
	return _state(source).restore_day(data, GameData.days.size())
