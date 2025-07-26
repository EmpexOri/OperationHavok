extends Node2D
class_name EnemyGrenade

@export var throw_force: float = 500.0
@export var explosion_delay: float = 1.0
@export var explosion_radius: float = 150.0
@export var damage: float = 15.0
@export var stop_on_enemy_hit: bool = false
@onready var explosion_anim: AnimatedSprite2D = $AnimatedSprite2D

var velocity: Vector2
var timer: Timer
var radius_indicator: Sprite2D

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
		var radius_in_pixels = explosion_radius
		var tex_size = radius_indicator.texture.get_size()
		radius_indicator.scale = Vector2(radius_in_pixels, radius_in_pixels) / tex_size
		radius_indicator.modulate = Color(1, 0, 0, 0.3)

		var tween = create_tween()
		tween.tween_property(radius_indicator, "modulate:a", 0.0, explosion_delay).set_ease(Tween.EASE_IN)
	else:
		push_warning("ExplosionRadiusIndicator not found")

func start(start_position: Vector2, target_position: Vector2):
	global_position = start_position

	var displacement = target_position - start_position
	var time = explosion_delay

	# Use slightly higher velocity to compensate for slowing down
	velocity = displacement / time * 1.2  # Tweak multiplier to taste

func _physics_process(delta):
	var new_position = position + velocity * delta

	var query = PhysicsRayQueryParameters2D.create(position, new_position)
	query.exclude = [self]
	query.collision_mask = 1 << 2  # Adjust layer to match walls

	var space_state = get_world_2d().direct_space_state
	if space_state:
		var result = space_state.intersect_ray(query)
		if result:
			velocity = Vector2.ZERO
			position = result.position
		else:
			position = new_position

	# Apply smooth deceleration
	velocity = velocity.move_toward(Vector2.ZERO, 100 * delta)

func _on_body_entered(body: Node2D) -> void:
	if stop_on_enemy_hit and body.is_in_group("Player"):
		velocity = Vector2.ZERO

func _explode():
	velocity = Vector2.ZERO

	for body in $Area2D.get_overlapping_bodies():
		# Damage enemies
		if body.has_method("deal_damage") and body.is_in_group("Enemy"):
			body.deal_damage(damage, global_position)
		
		# Damage player
		elif body.has_method("deal_damage") and body.is_in_group("Player"):
			body.deal_damage(damage, global_position)

	$Area2D.monitoring = false
	$Area2D.set_deferred("monitorable", false)

	$Sprite2D.visible = false  
	explosion_anim.visible = true
	GlobalAudioController.PlayGrenadeExplosion()
	explosion_anim.play("explode")

	await explosion_anim.animation_finished
	_on_explosion_animation_finished()

func _on_explosion_animation_finished():
	queue_free()
