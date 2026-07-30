class_name OverworldPlayer3D
extends CharacterBody3D

## HD-2D / voxel hybrid overworld avatar (Octopath-style isometric).
## Combat stays 2D; this node handles zone traversal and distance-based
## invisible random encounters (GDD § World & Exploration).

## Camera is yawed ~45°; rotate stick/keyboard input by the same angle so
## "Up" reads as screen-up (world +X/−Z diagonal), not world −Z.
const ISOMETRIC_YAW: float = PI / 4.0

@export var walk_speed: float = 8.0
@export var encounter_threshold: float = 25.0

var distance_walked: float = 0.0


func _ready() -> void:
	add_to_group("overworld_player")
	if GameManager.has_pending_player_position:
		global_position = GameManager.pending_player_position
		GameManager.has_pending_player_position = false


func _physics_process(delta: float) -> void:
	if not GameManager.is_exploring():
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta

	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).rotated(
		Vector3.UP,
		ISOMETRIC_YAW,
	)
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * walk_speed
		velocity.z = move_dir.z * walk_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

	var horizontal_speed: float = Vector3(velocity.x, 0.0, velocity.z).length()
	if horizontal_speed > 0.0:
		distance_walked += horizontal_speed * delta
		if distance_walked >= encounter_threshold:
			distance_walked = 0.0
			velocity = Vector3.ZERO
			EventBus.random_encounter_triggered.emit()
