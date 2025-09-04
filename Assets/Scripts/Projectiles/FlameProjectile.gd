extends Projectile
class_name FlameProjectile

@export var ground_effect_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Misc/GroundEffect.tscn")
@export var ground_effect_offset: Vector2 = Vector2.ZERO

@export var min_lifetime: float = 0.1
@export var max_lifetime: float = 0.3

var pierce_effect: PenetrationEffect

func _ready() -> void:
	super._ready()
	# Ensure FlameProjectile always has penetration
	pierce_effect = PenetrationEffect.new()
	pierce_effect.max_hits = 999 # flames can pass through almost everything
	current_effects.append(pierce_effect)
	if pierce_effect.has_method("setup"):
		pierce_effect.setup(self)

	# Replace lifetime expiry signal with custom one
	if lifetime_timer.timeout.is_connected(queue_free):
		lifetime_timer.timeout.disconnect(queue_free)
	lifetime_timer.timeout.connect(_on_lifetime_expired)

# Override start to always add piercing and randomize lifetime
func start(start_position: Vector2, direction: Vector2, entity_owner: String,
		p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D,
		damage_multiplier: float):

	# Force in penetration effect
	if p_effects == null:
		p_effects = []
	p_effects.append(pierce_effect)

	super.start(start_position, direction, entity_owner, p_effects, space_state, damage_multiplier)

	# Randomize lifetime
	var lifetime = randf_range(min_lifetime, max_lifetime)
	lifetime_timer.wait_time = lifetime
	lifetime_timer.start()

func _on_lifetime_expired():
	_spawn_ground_effect()
	queue_free()

# Handle collisions with environment (not enemies)
func _on_body_entered(body: Node2D):
	if body.is_in_group("Enemy"):
		# Use normal on_hit pipeline for enemies
		super._on_body_entered(body)
	else:
		# Hit a wall/obstacle → spawn GroundEffect
		_spawn_ground_effect()
		queue_free()

func _spawn_ground_effect():
	if ground_effect_scene:
		var effect = ground_effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position + ground_effect_offset
