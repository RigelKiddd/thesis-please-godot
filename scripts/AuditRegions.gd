class_name AuditRegions
extends RefCounted

## Static annotation regions in document-content coordinates.
## Coordinates are calibrated against the 696px-wide Docs views at 1380x860.
## Every audit defect carries an `anchor` key that maps into this table.

static var REGIONS := {
	"cover": {
		"identity.title": Rect2(18, 50, 660, 40),
		"identity.name": Rect2(150, 142, 190, 24),
		"identity.id": Rect2(350, 142, 190, 24),
		"identity.major": Rect2(148, 118, 394, 24),
	},
	"abstract": {
		"identity.title": Rect2(16, 24, 664, 30),
		"summary.chars": Rect2(430, 0, 266, 28),
		"summary.keywords": Rect2(430, 0, 266, 28),
	},
	"dup": {
		"dup.identity": Rect2(150, 54, 500, 80),
		"dup.rate": Rect2(14, 48, 150, 92),
		"dup.seal": Rect2(18, 198, 660, 100),
	},
	"refs": {
		"refs.header": Rect2(300, 0, 396, 28),
		"refs.list": Rect2(8, 30, 680, 286),
	},
	"body": {
		"body.header": Rect2(280, 0, 416, 28),
		"body.pages": Rect2(14, 104, 668, 132),
		"body.words": Rect2(400, 0, 296, 28),
		"body.gap": Rect2(14, 104, 668, 132),
	},
	"form": {
		"form.signatures": Rect2(0, 52, 696, 66),
		"form.ethics": Rect2(446, 116, 250, 30),
		"admin.row": Rect2(0, 144, 696, 34),
		"form.sig.advisor": Rect2(84, 56, 278, 30),
		"form.sig.chair": Rect2(446, 56, 250, 30),
		"form.sig.dean": Rect2(84, 86, 278, 30),
		"admin.credits": Rect2(84, 146, 278, 30),
		"admin.tuition": Rect2(446, 146, 250, 30),
	},
}

## Per-item anchors (refs.item.N) are resolved from the rendered Docs controls.
static func is_dynamic(anchor: String) -> bool:
	return anchor.begins_with("refs.item.") or anchor.begins_with("form.sig.")

static func supports(anchor: String) -> bool:
	if is_dynamic(anchor):
		return true
	for tab_id in REGIONS.keys():
		var by_tab: Dictionary = REGIONS[tab_id]
		if by_tab.has(anchor):
			return true
	return false

static func rect(tab_id: String, anchor: String) -> Rect2:
	var by_tab: Dictionary = REGIONS.get(tab_id, {})
	if by_tab.has(anchor):
		return by_tab[anchor]
	push_warning("AuditRegions: missing anchor '%s' for tab '%s'" % [anchor, tab_id])
	return Rect2()

static func has(tab_id: String, anchor: String) -> bool:
	var by_tab: Dictionary = REGIONS.get(tab_id, {})
	return by_tab.has(anchor)

static func all_for_tab(tab_id: String) -> Dictionary:
	return REGIONS.get(tab_id, {})
