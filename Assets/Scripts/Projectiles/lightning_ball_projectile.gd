extends Projectile
class_name LightningBallProjectile

@onready var ball_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_ref = $Explosion
@onready var particles: GPUParticles2D = $GPUParticles2D

var exploded: bool = false

func _ready() -> void:
	super._ready()
	ball_anim.play()
	particles.emitting = true
	if visible_on_screen_notifier_2d.screen_exited.is_connected(queue_free):
		visible_on_screen_notifier_2d.screen_exited.disconnect(queue_free) #Don't free this projectile off screen <3
	explosion_ref.start(global_position, Vector2.ZERO)
	explosion_ref.explosion_delay = base_lifetime - 1

func _handle_movement(delta: float) -> void:
	if exploded:
		return
	
	var movement_vector = velocity * delta
	
	var shape = collision_shape_2d.shape
	var current_transform = global_transform

	var query := PhysicsShapeQueryParameters2D.new()
	query.collision_mask = collision_mask
	query.shape = shape
	query.transform = current_transform
	query.motion = movement_vector
	var enemies = get_tree().get_nodes_in_group("Enemy")
	query.exclude = enemies.map(func(e): return e.get_rid())

	var result: Array = _space_state.intersect_shape(query)

	if result:
		_trigger_explosion()
	else:
		global_position += movement_vector
		if explosion_ref:
			explosion_ref.global_position = self.global_position

func _trigger_explosion() -> void:
	if exploded:
		return
	exploded = true
	particles.emitting = false
	ball_anim.visible = false

	if explosion_ref and explosion_ref.has_method("explode"):
		explosion_ref.global_position = global_position
		explosion_ref.velocity = Vector2.ZERO 
		explosion_ref.explode()
		

func _on_explosion_tree_exited() -> void:
	queue_free()
