extends Node

## Detects active input device and notifies UI (PC / touch / Steam Deck).
## Switch on first concrete event from the other family — not mouse motion alone.

signal input_method_changed(using_controller: bool)

@export var is_using_controller: bool = false

## Ignore tiny stick noise so handheld drift does not flip modes.
const JOY_MOTION_DEADZONE: float = 0.25


func _input(event: InputEvent) -> void:
	if _is_controller_event(event):
		if not is_using_controller:
			is_using_controller = true
			print("Switched to Controller")
			input_method_changed.emit(true)
		return

	if _is_pointer_or_keyboard_event(event):
		if is_using_controller:
			is_using_controller = false
			print("Switched to Mouse/Touch")
			input_method_changed.emit(false)


func _is_controller_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return true
	if event is InputEventJoypadMotion:
		var motion: InputEventJoypadMotion = event
		return absf(motion.axis_value) >= JOY_MOTION_DEADZONE
	return false


func _is_pointer_or_keyboard_event(event: InputEvent) -> bool:
	return (
		event is InputEventKey
		or event is InputEventMouseButton
		or event is InputEventScreenTouch
	)
