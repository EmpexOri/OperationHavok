extends Node2D
class_name SuperGrenade

@export var throw_force: float = 500.0
@export var explosion_delay: float = 0.5
@export var explosion_radius: float = 150.0
@export var damage: float = 50.0
@export var stop_on_enemy_hit: bool = false
@export var explode_on_walls: bool = true 
@onready var explosion_anim: AnimatedSprite2D = $AnimatedSprite2D

var velocity: Vector2
var timer: Timer
var radius_indicator: Sprite2D
var exploding: bool = false 

func start(start_position: Vector2, direction: Vector2):
	global_position = start_position
	velocity = direction.normalized() * throw_force

func explode():
	_explode()

func start_explosion():
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO
	_do_explosion_effects()

# ----------------------------
# Internal functionality
# ----------------------------
func _ready():
	await get_tree().process_frame
	timer = $ExplosionTimer
	timer.wait_time = explosion_delay
	timer.one_shot = true
	timer.timeout.connect(_explode)
	timer.start()

	if $Area2D:
		$Area2D.body_entered.connect(_on_body_entered)

	radius_indicator = $ExplosionRadiusIndicator
	if radius_indicator:
		var radius_in_pixels = explosion_radius * 1
		var tex_size = radius_indicator.texture.get_size()
		radius_indicator.scale = Vector2(radius_in_pixels, radius_in_pixels) / tex_size
		radius_indicator.modulate = Color(1, 0, 0, 0.3)

		var tween = create_tween()
		tween.tween_property(radius_indicator, "modulate:a", 0.0, explosion_delay).set_ease(Tween.EASE_IN)
	else:
		push_warning("ExplosionRadiusIndicator not found")

func _physics_process(delta):
	if exploding:
		if explosion_anim.visible:
			var frame_count = explosion_anim.sprite_frames.get_frame_count("explode")
			if explosion_anim.frame >= frame_count - 1:
				_on_explosion_animation_finished()
	else:
		_handle_movement(delta)

func _handle_movement(delta: float):
	var new_position = position + velocity * delta
	var query = PhysicsRayQueryParameters2D.create(position, new_position)
	query.exclude = [self]
	query.collision_mask = 1 << 2 

	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return

	var result = space_state.intersect_ray(query)
	if result:
		velocity = Vector2.ZERO
		position = result.position
		if explode_on_walls:
			_explode()
	else:
		position = new_position

	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func _on_body_entered(body: Node2D) -> void:
	if stop_on_enemy_hit and body.is_in_group("Enemy"):
		velocity = Vector2.ZERO

func _explode():
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO
	_do_explosion_effects()

func _do_explosion_effects():
	# Damage enemies
	for body in $Area2D.get_overlapping_bodies():
		if body.has_method("deal_damage") and body.is_in_group("Enemy"):
			body.deal_damage(damage, global_position)

	# Disable monitoring
	$Area2D.monitoring = false
	$Area2D.set_deferred("monitorable", false)

	# Explosion visuals
	$Sprite2D.visible = false
	explosion_anim.visible = true
	explosion_anim.frame = 0
	explosion_anim.play("explode")

	GlobalAudioController.PlayGrenadeExplosion()

func _on_explosion_animation_finished():
	queue_free()
