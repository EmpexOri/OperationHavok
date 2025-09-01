extends ProjectileEffect
class_name PhysProjectileBounce

@export var max_bounces: int = 5
@export var bounce_random_degrees: float = 10.0   # max random angle per bounce

var current_bounces: int = 0
var bounce_cooldown_ms: float = 100.0
var bounce_cooldown_timer: float = 0.0
var last_bounced_body: Node2D = null

func _init() -> void:
	effect_name = "PhysProjectileBounce"

func setup(projectile):
	current_bounces = 0
	last_bounced_body = null
	bounce_cooldown_timer = 0.0

func process_effect(projectile, delta: float, space_state: PhysicsDirectSpaceState2D):
	if bounce_cooldown_timer > 0:
		bounce_cooldown_timer -= delta * 1000.0
		if bounce_cooldown_timer <= 0:
			last_bounced_body = null

func on_hit(projectile, body: Node2D, collision: KinematicCollision2D = null):
	if collision == null:
		print("PhysBounce: Projectile destroy due to collision being null")
		return true
	if not "velocity" in projectile:
		print("PhysBounce: Projectile destroy due to not being physics projectile")
		return true
	
	# Prevent multiple bounces on the same target
	if last_bounced_body == body and bounce_cooldown_timer > 0:
		return false
		
	if current_bounces < max_bounces:
		current_bounces += 1
		
		print("PhysBounce: Projectile bounced off {0}! {1}/{2}".format([body.name, current_bounces, max_bounces]))
		
		last_bounced_body = body
		bounce_cooldown_timer = bounce_cooldown_ms
		
		# Base reflection
		var reflect_velocity = projectile.velocity.bounce(collision.get_normal())
		
		# Add random angular variance
		var random_angle = deg_to_rad(randf_range(-bounce_random_degrees, bounce_random_degrees))
		reflect_velocity = reflect_velocity.rotated(random_angle)
		
		projectile.velocity = reflect_velocity
		projectile.rotation = projectile.velocity.angle()
		
		return false # Keep bouncing
	else:
		return true # Allow destruction
