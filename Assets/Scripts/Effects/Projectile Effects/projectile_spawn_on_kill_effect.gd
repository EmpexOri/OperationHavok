extends ProjectileEffect
class_name ProjectileSpawnOnKillEffect

@export var max_spawns: int = 3        # How many times it can spawn
@export var spawn_scene: PackedScene   # The projectile to spawn
@export var spawn_speed: float = 400.0 # Speed of new projectile
@export var spawn_angle_variation: float = 15.0 # Random deviation in degrees

# Per-projectile state
var current_spawns: int = 0

func _init() -> void:
	effect_name = "SpawnOnKill"

func setup(projectile):
	current_spawns = 0

func process_effect(projectile, delta: float, space_state: PhysicsDirectSpaceState2D):
	pass

func on_hit(projectile, body: Node2D, collision: KinematicCollision2D = null):
	if body.has_method("deal_damage"):
		# Check if hit would kill the target
		var killed = body.Health <= projectile.damage  # Adjust according to your projectile logic
		if killed and current_spawns < max_spawns and spawn_scene:
			current_spawns += 1

			# Instantiate new projectile
			var new_proj = spawn_scene.instantiate()
			# Add to the same parent as the original projectile
			projectile.get_parent().add_child(new_proj)
			new_proj.global_position = projectile.global_position

			# Copy velocity with small random variation
			var angle_offset = deg_to_rad(randf_range(-spawn_angle_variation, spawn_angle_variation))
			var new_dir = projectile.velocity.normalized().rotated(angle_offset)
			if "velocity" in new_proj:
				new_proj.velocity = new_dir * spawn_speed
				new_proj.rotation = new_dir.angle()

	return false # Let the original projectile still die
