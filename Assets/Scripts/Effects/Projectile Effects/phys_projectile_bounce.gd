extends ProjectileEffect
class_name PhysProjectileBounces

@export var max_bounces: int = 5
@export var explosion_scene: PackedScene
@export var bounce_sfx: AudioStream 

# Per-projectile state (reset on setup)
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
		return {"destroy_projectile": true, "apply_damage": true}  # Default fallback

	if last_bounced_body == body and bounce_cooldown_timer > 0:
		return false

	if current_bounces < max_bounces:
		current_bounces += 1
		last_bounced_body = body
		bounce_cooldown_timer = bounce_cooldown_ms

		# Optional explosion
		if explosion_scene:
			var explosion_instance = explosion_scene.instantiate()
			projectile.get_parent().add_child(explosion_instance)
			explosion_instance.global_position = collision.get_position()
			if explosion_instance.has_method("start"):
				explosion_instance.start()

		# Play bounce SFX without await
		if bounce_sfx and is_instance_valid(projectile):
			var sfx_player := AudioStreamPlayer2D.new()
			sfx_player.stream = bounce_sfx
			sfx_player.global_position = projectile.global_position
			projectile.get_parent().add_child(sfx_player)
			sfx_player.play()
			
			# Auto-free the SFX player using a one-shot timer
			var t := Timer.new()
			t.wait_time = bounce_sfx.get_length()
			t.one_shot = true
			t.autostart = true
			sfx_player.add_child(t)
			t.timeout.connect(Callable(sfx_player, "queue_free"))

		# Reflect velocity
		var reflect_velocity = projectile.velocity.bounce(collision.get_normal())
		var random_angle = deg_to_rad(randf_range(-5, 5))
		projectile.velocity = reflect_velocity.rotated(random_angle)
		projectile.rotation = projectile.velocity.angle()

		var separation_offset = collision.get_normal() * 3.5 
		projectile.global_position += separation_offset

		return {"destroy_projectile": false, "apply_damage": true} 
	else:
		return {"destroy_projectile": true, "apply_damage": true}  # Max bounces reached
