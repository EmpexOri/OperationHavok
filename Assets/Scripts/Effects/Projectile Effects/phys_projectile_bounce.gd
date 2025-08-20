extends ProjectileEffect
class_name PhysProjectileBounce

@export var max_bounces: int = 5

var current_bounces: int = 0

func _init() -> void:
	effect_name = "PhysProjectileBounce"

func setup(projectile):
	current_bounces = 0

func process_effect(projectile, delta: float, space_state: PhysicsDirectSpaceState2D):
	pass

func on_hit(projectile, body: Node2D, collision: KinematicCollision2D = null):
	if not "velocity" in projectile:
		return # Only works for physics projectiles
		
	if current_bounces < max_bounces:
		current_bounces += 1
		
		var reflect_velocity = projectile.velocity.bounce(collision.get_normal())
		projectile.velocity = reflect_velocity
		
		projectile.rotation = projectile.velocity.angle()
		
		return false # Keep bouncing
		
	else:
		
		return true # We done
