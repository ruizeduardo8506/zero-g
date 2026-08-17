extends Node

## Named demo roster (GDD: Orphan, Brynnael, Edward, Seluc). Max party of 4.

const ORPHAN: String = "orphan"
const BRYNNAEL: String = "brynnael"
const EDWARD: String = "edward"
const SELUC: String = "seluc"

const DISPLAY_NAMES := {
	ORPHAN: "The Orphan",
	BRYNNAEL: "Brynnael",
	EDWARD: "Edward",
	SELUC: "Seluc",
}

const COMBAT_COLORS := {
	ORPHAN: Color(0.35, 0.85, 1.0, 1.0),
	BRYNNAEL: Color(0.45, 0.85, 0.55, 1.0),
	EDWARD: Color(0.55, 0.45, 0.75, 1.0),
	SELUC: Color(0.85, 0.55, 0.25, 1.0),
}

var recruited: Array[String] = [ORPHAN]


func reset() -> void:
	recruited = [ORPHAN]
	EventBus.party_changed.emit()


func is_recruited(member_id: String) -> bool:
	return recruited.has(member_id)


func recruit(member_id: String) -> bool:
	if recruited.has(member_id):
		return false
	if recruited.size() >= 4:
		return false
	if not DISPLAY_NAMES.has(member_id):
		push_warning("PartyManager: unknown member '%s'" % member_id)
		return false
	recruited.append(member_id)
	EventBus.party_changed.emit()
	EventBus.combat_log.emit("%s joins the party." % display_name(member_id))
	return true


func display_name(member_id: String) -> String:
	return str(DISPLAY_NAMES.get(member_id, member_id.capitalize()))


func body_color(member_id: String) -> Color:
	if COMBAT_COLORS.has(member_id):
		return COMBAT_COLORS[member_id] as Color
	return Color.WHITE


func to_dict() -> Dictionary:
	return {"recruited": recruited.duplicate()}


func from_dict(data: Dictionary) -> void:
	recruited.clear()
	var raw: Variant = data.get("recruited", [ORPHAN])
	if raw is Array:
		for item in raw:
			recruited.append(str(item))
	if recruited.is_empty():
		recruited.append(ORPHAN)
	EventBus.party_changed.emit()
