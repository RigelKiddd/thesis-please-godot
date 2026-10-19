extends RefCounted

## All persistent paths go through this boundary. Test/dev processes never use
## the player's save directory, even when TestMain is launched by hand.
static var _root := ""

static func root() -> String:
	if !_root.is_empty():
		return _root
	_root = OS.get_environment("THESIS_USER_DIR")
	if _root.is_empty():
		var testing := false
		for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
			if arg.contains("TestMain.tscn") or arg.begins_with("--state="):
				testing = true
		if testing:
			_root = OS.get_cache_dir().path_join("thesis-please-tests").path_join(str(OS.get_process_id()))
		else:
			_root = "user://"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root))
	return _root

static func file(name: String) -> String:
	return root().path_join(name)
