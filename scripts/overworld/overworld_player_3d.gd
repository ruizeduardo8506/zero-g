class_name OverworldPlayer3D
extends CharacterBody3D

## 3D isometric overworld avatar. Combat stays 2D; this node only handles zone traversal
## and distance-based invisible random encounters (GDD § World & Exploration).

@export var walk_speed: float = 5.0
@export var encounter_threshold: float = 20.0

var distance_walked: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta

	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = input_dir.x * walk_speed
	velocity.z = input_dir.y * walk_speed
	move_and_slide()

	if velocity.length() > 0.0:
		distance_walked += velocity.length() * delta
		if distance_walked >= encounter_threshold:
			distance_walked = 0.0
			velocity = Vector3.ZERO
			EventBus.random_encounter_triggered.emit()
