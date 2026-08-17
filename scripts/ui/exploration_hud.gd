extends CanvasLayer

## Minimal overworld HUD: interact prompt + party roster.


func _ready() -> void:
	EventBus.interact_prompt_changed.connect(_on_prompt)
	EventBus.party_changed.connect(_refresh_party)
	_refresh_party()
	_on_prompt("")


func _on_prompt(text: String) -> void:
	var label: Label = %PromptLabel
	label.text = text
	label.visible = not text.is_empty()


func _refresh_party() -> void:
	var names: PackedStringArray = []
	for member_id in PartyManager.recruited:
		names.append(PartyManager.display_name(member_id))
	%PartyLabel.text = "PARTY  " + " · ".join(names)
