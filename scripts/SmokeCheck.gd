extends RefCounted

## Shipped smoke check for exported builds.
##
## This is intentionally tiny and contains no test-only dependencies: it builds
## every document page, validates audit labels/anchors, and checks the chat
## branch. Run it with:
##   THESIS_PLEASE.exe --headless -- --state=smoke
## The full contract suite lives in tests/TestMain.gd and is excluded from export.

static func run(main) -> void:
	var errors: Array = []
	var rendered := 0
	for di in range(GameData.days.size()):
		for si in range(GameData.student_count(di)):
			var s := GameData.student(di, si)
			var au := GameData.audit(s, di)
			for d in au.get("defects", []):
				if str(d.get("label", "")) == "":
					errors.append("missing label D%d S%d" % [di + 1, si + 1])
				if !AuditRegions.supports(str(d.get("anchor", ""))):
					errors.append("missing anchor %s" % str(d.get("anchor", "")))
			for tab_id in ["cover", "abstract", "body", "refs", "dup", "form"]:
				var holder := Control.new()
				main.add_child(holder)
				holder.add_child(Docs.render(tab_id, s, 696))
				holder.queue_free()
				rendered += 1
			var need: bool = au.get("defects", []).size() > 0
			var scripted: bool = bool(ChatScript.build(s, di).get("needs_reply", false))
			if scripted != need:
				errors.append("chat branch D%d S%d" % [di + 1, si + 1])
	if errors.is_empty():
		print("SMOKE ok docs=%d students=%d" % [rendered, 28])
		main.get_tree().quit(0)
	else:
		for e in errors:
			push_error("SMOKE " + str(e))
		print("SMOKE failed errors=%d" % errors.size())
		main.get_tree().quit(1)
