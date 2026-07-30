class_name HandUI
extends HBoxContainer

## Horizontal hand row driven by EventBus draw / play / discard signals.
## Assign `card_visual_scene` to a PackedScene that uses CardVisual.
## Clicks request a play; CombatController spends mana and emits card_played.

signal card_play_requested(card_data: Resource)

@export var card_visual_scene: PackedScene


func _ready() -> void:
	# Ignore empty container hits so world/entity clicks pass through.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.card_drawn.connect(_on_card_drawn)
	EventBus.card_played.connect(_on_card_played)
	EventBus.hand_discarded.connect(_on_hand_discarded)


func _on_card_drawn(card_data: Resource, _combatant_name: String = "") -> void:
	if card_visual_scene == null:
		push_error("HandUI: card_visual_scene is not assigned.")
		return
	var visual: Node = card_visual_scene.instantiate()
	if visual == null or not visual.has_method("setup"):
		push_error("HandUI: card_visual_scene must expose setup(data).")
		if visual != null:
			visual.free()
		return
	visual.call("setup", card_data)
	if visual.has_signal("card_clicked"):
		visual.connect("card_clicked", _on_card_clicked)
	add_child(visual)


func _on_card_clicked(card_data: Resource) -> void:
	print("Attempting to play card: ", _resolve_card_name(card_data))
	card_play_requested.emit(card_data)


func _on_card_played(card_data: Resource, _target: Node = null) -> void:
	for child: Node in get_children():
		if "card_data" in child and child.get("card_data") == card_data:
			child.queue_free()
			break


func _on_hand_discarded() -> void:
	for child: Node in get_children():
		child.queue_free()


func _resolve_card_name(card_data: Resource) -> String:
	if card_data == null:
		return "<null>"
	if "card_name" in card_data:
		return str(card_data.get("card_name"))
	if "display_name" in card_data:
		return str(card_data.get("display_name"))
	return card_data.resource_name
