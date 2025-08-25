extends ProjectileEffect
class_name PhysProjectileBounce

@export var max_bounces: int = 5

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
		return true # Allow destruction if no physics collision info
	if not "velocity" in projectile:
		print("PhysBounce: Projectile destroy due to not being physics projectile")
		return true # Allow destruction if not a CharacterBody2D
	
	# Prevent multiple bounces on the same target
	if last_bounced_body == body and bounce_cooldown_timer > 0:
		return false # Ignore this collision
		
	if current_bounces < max_bounces:
		current_bounces += 1
		
		print("PhysBounce: Projectile bounced off {0}! {1}/{2}".format([body.name, current_bounces, max_bounces]))
		
		# Store last hit body and start cooldown
		last_bounced_body = body
		bounce_cooldown_timer = bounce_cooldown_ms
		
		var reflect_velocity = projectile.velocity.bounce(collision.get_normal())
		projectile.velocity = reflect_velocity
		projectile.rotation = projectile.velocity.angle()
		
		return false # Keep bouncing
		
	else:
		
		return true # Allow destruction
