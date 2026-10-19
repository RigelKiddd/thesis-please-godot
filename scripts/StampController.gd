extends RefCounted

## Stamp judgement + ending note.
##
## The conclusion is deterministic. This controller only evaluates the chosen
## stamp and turns the run's annotation accuracy into a short ending comment.
## The case-file / evidence-chain layer was removed in v1.11.

static func evaluate(current: Dictionary, day_index: int, chosen: String) -> Dictionary:
	var audit := GameData.audit(current, day_index)
	var expected := str(audit.get("expected", "pass"))
	return {
		"audit": audit,
		"expected": expected,
		"correct": chosen == expected,
		"defects": audit.get("defects", []),
		"critical": bool(audit.get("critical", false)),
	}

static func ending_note(stats: Dictionary) -> String:
	var hits := int(stats.get("annotation_hits", 0))
	var wrong := int(stats.get("annotation_wrong", 0))
	var missed := int(stats.get("annotation_missed", 0))
	var total := hits + wrong + missed
	if total == 0:
		return "这一周你没有在论文上落过笔，红笔始终没出鞘。"
	var acc := int(round(float(hits) / float(total) * 100.0))
	if acc >= 75:
		return "你圈出的每一处，学生基本都认。红笔比章更有分量。"
	if acc >= 40:
		return "圈注命中了一半上下，学生开始学会先问清楚再来。"
	return "你的红笔比条例更急，纸面上留下不少圈空的痕迹。"
