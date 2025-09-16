extends Enemy
class_name Destructible
"""
Generic destructible object:
• Has HP/Armor inherited from Enemy
• Does not navigate or attack
• Emits a `destroyed` signal when killed
• Supports optional effect callbacks
"""

signal destroyed(node)

@export var start_health: int = 20
@export var start_armor: int = 0
@export var destroy_effect: PackedScene      # Optional particle/explosion scene
@export var spawn_on_destroy: PackedScene    # Optional scene to spawn (loot, etc.)
@export var drop_xp_on_destroy: bool = false # Toggle XP drop from Enemy

func _ready() -> void:
	# Disable inherited enemy-like behavior
	Speed = 0
	WeaponScene = null
	CurrentWeapon = null
	Group = "Destructible"
	SummonGroup = ""
	Target = ""

	Health = start_health
	MaxHealth = start_health
	Armor = start_armor
	MaxArmor = start_armor
	BaseScale = scale

	add_to_group(Group)
	connect("died", Callable(self, "_on_destroyed"))

func update_navigation(_delta: float) -> void:
	# Override to prevent movement logic
	return

func resolve_target() -> Node2D:
	return null

func start() -> void:
	# Nothing to start
	pass

func on_death() -> void:
	if dead:
		return
	dead = true
	emit_signal("destroyed", self)

	# Optional VFX
	if destroy_effect:
		var fx = destroy_effect.instantiate()
		fx.global_position = global_position
		get_tree().current_scene.add_child(fx)

	# Optional spawn (e.g., loot crate)
	if spawn_on_destroy:
		var obj = spawn_on_destroy.instantiate()
		obj.global_position = global_position
		get_tree().current_scene.add_child(obj)

	if drop_xp_on_destroy:
		drop_xp()

	queue_free()

func _on_destroyed(_who):
	# Extra hook for code-based effects.
	# Connect to this signal from other nodes if you want custom reactions.
	pass
