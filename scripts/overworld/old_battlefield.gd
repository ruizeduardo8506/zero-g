@tool
class_name OldBattlefield
extends Node3D

## Procedural old-battlefield set dressing for the opening overworld.
## Scatters skeletons, weapons, shields, debris, and ruined siege gear
## from Kenney kits (graveyard / castle / mini-dungeon / fantasy-town).
## @tool so the field is visible in the editor as well as at runtime.

const GRAVEYARD := "res://assets/models/overworld/graveyard-kit/Models/GLB format/"
const CASTLE := "res://assets/models/overworld/castle-kit/Models/GLB format/"
const MINI_DUNGEON := "res://assets/models/mini/mini-dungeon/Models/GLB format/"
const TOWN := "res://assets/models/overworld/fantasy-town-kit/Models/GLB format/"

@export var battlefield_seed: int = 1945
@export var radius: float = 28.0
## Kenney kits are ~1m tall; ortho view needs a boost to read on screen.
@export var prop_scale: float = 3.5
@export var skeleton_count: int = 22
@export var weapon_count: int = 30
@export var shield_count: int = 18
@export var debris_count: int = 40
@export var landmark_count: int = 8

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _skeletons: Array[String] = [
	GRAVEYARD + "character-skeleton.glb",
	GRAVEYARD + "coffin-old.glb",
	GRAVEYARD + "coffin.glb",
	MINI_DUNGEON + "character-human.glb",
	MINI_DUNGEON + "character-orc.glb",
]

var _weapons: Array[String] = [
	MINI_DUNGEON + "weapon-sword.glb",
	MINI_DUNGEON + "weapon-spear.glb",
	TOWN + "blade.glb",
]

var _shields: Array[String] = [
	MINI_DUNGEON + "shield-round.glb",
	MINI_DUNGEON + "shield-rectangle.glb",
]

var _debris: Array[String] = [
	GRAVEYARD + "debris.glb",
	GRAVEYARD + "debris-wood.glb",
	GRAVEYARD + "gravestone-broken.glb",
	GRAVEYARD + "gravestone-debris.glb",
	GRAVEYARD + "rocks.glb",
	GRAVEYARD + "cross-wood.glb",
	GRAVEYARD + "grave.glb",
	CASTLE + "rocks-small.glb",
	MINI_DUNGEON + "barrel.glb",
	MINI_DUNGEON + "chest.glb",
	TOWN + "planks.glb",
	TOWN + "planks-half.glb",
]

var _landmarks: Array[String] = [
	CASTLE + "siege-catapult-demolished.glb",
	CASTLE + "siege-trebuchet-demolished.glb",
	CASTLE + "siege-ballista-demolished.glb",
	CASTLE + "siege-ram-demolished.glb",
	CASTLE + "siege-tower-demolished.glb",
	CASTLE + "flag-banner-long.glb",
	GRAVEYARD + "pillar-obelisk.glb",
	GRAVEYARD + "column-large.glb",
	GRAVEYARD + "stone-wall-damaged.glb",
]


func _ready() -> void:
	_generate()


func _generate() -> void:
	for child: Node in get_children():
		child.free()
	_rng.seed = battlefield_seed

	_scatter(_skeletons, skeleton_count, true)
	_scatter(_weapons, weapon_count, false, true)
	_scatter(_shields, shield_count, false, true)
	_scatter(_debris, debris_count, false)
	_scatter(_landmarks, landmark_count, false)
	_place_ring_fences()


func _scatter(
	paths: Array[String],
	count: int,
	lie_down: bool = false,
	ground_clutter: bool = false,
) -> void:
	if paths.is_empty() or count <= 0:
		return
	for _i: int in count:
		var path: String = paths[_rng.randi() % paths.size()]
		var instance: Node3D = _spawn(path)
		if instance == null:
			continue
		var pos: Vector3 = _random_point_in_disk(radius)
		instance.position = pos
		instance.rotation.y = _rng.randf_range(0.0, TAU)
		var scale_mul: float = prop_scale * _rng.randf_range(0.9, 1.2)
		instance.scale = Vector3.ONE * scale_mul
		if lie_down:
			# Fallen remains — tip onto the ground.
			instance.rotation.x = _rng.randf_range(-PI * 0.5, -PI * 0.35)
			instance.rotation.z = _rng.randf_range(-0.25, 0.25)
			instance.position.y = 0.2 * scale_mul
		elif ground_clutter:
			instance.rotation.x = _rng.randf_range(-0.4, 0.4)
			instance.rotation.z = _rng.randf_range(-0.5, 0.5)
			instance.position.y = 0.05 * scale_mul
		else:
			instance.position.y = 0.0
		add_child(instance)


func _place_ring_fences() -> void:
	## Broken perimeter suggests an abandoned war camp / field edge.
	var fence_paths: Array[String] = [
		GRAVEYARD + "fence-damaged.glb",
		GRAVEYARD + "iron-fence-damaged.glb",
		GRAVEYARD + "stone-wall-damaged.glb",
	]
	var steps: int = 16
	for i: int in steps:
		if _rng.randf() < 0.35:
			continue
		var angle: float = (float(i) / float(steps)) * TAU
		var dist: float = radius * _rng.randf_range(0.88, 1.02)
		var path: String = fence_paths[_rng.randi() % fence_paths.size()]
		var fence: Node3D = _spawn(path)
		if fence == null:
			continue
		fence.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		fence.rotation.y = -angle + PI * 0.5
		fence.scale = Vector3.ONE * prop_scale
		add_child(fence)


func _random_point_in_disk(r: float) -> Vector3:
	var t: float = TAU * _rng.randf()
	var u: float = _rng.randf() + _rng.randf()
	var rad: float = (2.0 - u if u > 1.0 else u) * r
	# Keep a small clear pocket around spawn / player origin.
	if rad < 3.5:
		rad = 3.5 + _rng.randf() * 2.0
	return Vector3(cos(t) * rad, 0.0, sin(t) * rad)


func _spawn(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		push_warning("OldBattlefield: missing asset %s" % path)
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_warning("OldBattlefield: failed to load %s" % path)
		return null
	var node: Node = packed.instantiate()
	if not (node is Node3D):
		node.queue_free()
		return null
	var root: Node3D = node as Node3D
	# Decorative only — don't block the player on clutter.
	_disable_collisions(root)
	return root


func _disable_collisions(root: Node) -> void:
	if root is CollisionObject3D:
		(root as CollisionObject3D).collision_layer = 0
		(root as CollisionObject3D).collision_mask = 0
	for child: Node in root.get_children():
		_disable_collisions(child)
