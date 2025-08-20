extends Projectile
class_name LightningBallProjectile

@onready var ball_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_ref: Grenade = $Explosion

var exploded: bool = false

func _ready() -> void:
	super._ready()
	ball_anim.play()
	if visible_on_screen_notifier_2d.screen_exited.is_connected(queue_free):
		visible_on_screen_notifier_2d.screen_exited.disconnect(queue_free) #Don't free this projectile off screen <3
	explosion_ref.start(global_position, Vector2.ZERO)
	explosion_ref.explosion_delay = base_lifetime - 1

func _physics_process(delta: float) -> void:
	if explosion_ref:
		explosion_ref.global_position = global_position

	if not exploded:
		_handle_movement(delta)
		_check_wall_collision(delta)

func _handle_movement(delta: float) -> void:
	if not exploded:
		position += velocity * delta

func _check_wall_collision(delta: float) -> void:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var from: Vector2 = global_position - velocity.normalized() * 1.0
	var to: Vector2 = global_position + velocity * delta

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = collision_mask

	# Exclude enemies so the ray won't hit them
	var enemies = get_tree().get_nodes_in_group("Enemy")
	query.exclude = enemies.map(func(e): return e.get_rid())

	var result: Dictionary = space_state.intersect_ray(query)

	if not result.is_empty() and not exploded:
		_trigger_explosion()

func _trigger_explosion() -> void:
	if exploded:
		return
	exploded = true
	ball_anim.visible = false

	if explosion_ref and explosion_ref.has_method("explode"):
		explosion_ref.global_position = global_position
		explosion_ref.velocity = Vector2.ZERO 
		explosion_ref.explode()
