class_name OverworldPlayer2D
extends CharacterBody2D

## Top-down overworld avatar. Distance-based invisible random encounters (GDD).

@export var walk_speed: float = GameConstants.OVERWORLD_WALK_SPEED
@export var encounter_threshold: float = GameConstants.ENCOUNTER_DISTANCE_PX
@export var enable_encounters: bool = true

var distance_walked: float = 0.0


func _ready() -> void:
	add_to_group("overworld_player")
	collision_layer = 1
	collision_mask = 1
	if GameManager.has_pending_player_position:
		global_position = GameManager.pending_player_position
		GameManager.has_pending_player_position = false
	_ensure_visual()
	_ensure_collision()


func _physics_process(delta: float) -> void:
	if not GameManager.is_exploring() and not GameManager.is_in_guildhall():
		velocity = Vector2.ZERO
		return

	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1.0
	if input_dir.length_squared() > 0.0:
		velocity = input_dir.normalized() * walk_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if enable_encounters and GameManager.is_exploring() and velocity.length() > 0.0:
		distance_walked += velocity.length() * delta
		if distance_walked >= encounter_threshold:
			distance_walked = 0.0
			velocity = Vector2.ZERO
			EventBus.random_encounter_triggered.emit()


func _ensure_visual() -> void:
	if get_node_or_null("Body") != null:
		return
	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(12, 16)
	body.position = Vector2(-6, -10)
	body.color = Color(0.35, 0.85, 1.0, 1.0)
	add_child(body)


func _ensure_collision() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 5.0
	capsule.height = 14.0
	shape_node.shape = capsule
	add_child(shape_node)
