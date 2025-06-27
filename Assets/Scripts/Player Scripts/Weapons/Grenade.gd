extends Node2D
class_name Grenade

@export var throw_force: float = 500.0
@export var explosion_delay: float = 0.5
@export var explosion_radius: float = 150.0
@export var damage: float = 50.0
@export var stop_on_enemy_hit: bool = true
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
		var radius_in_pixels = explosion_radius * 1
		var tex_size = radius_indicator.texture.get_size()
		radius_indicator.scale = Vector2(radius_in_pixels, radius_in_pixels) / tex_size
		radius_indicator.modulate = Color(1, 0, 0, 0.3)

		# Optional: fade out before explosion
		var tween = create_tween()
		tween.tween_property(radius_indicator, "modulate:a", 0.0, explosion_delay).set_ease(Tween.EASE_IN)
	else:
		push_warning("ExplosionRadiusIndicator not found")

func start(start_position: Vector2, direction: Vector2):
	global_position = start_position
	velocity = direction.normalized() * throw_force

func _process(delta):
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func _on_body_entered(body: Node2D) -> void:
	if stop_on_enemy_hit and body.is_in_group("Enemy"):
		velocity = Vector2.ZERO

func _explode():
	velocity = Vector2.ZERO

	# Damage enemies in radius first
	for body in $Area2D.get_overlapping_bodies():
		if body.has_method("deal_damage") and body.is_in_group("Enemy"):
			body.deal_damage(damage, global_position)

	# Now disable monitoring so no further detections happen
	$Area2D.monitoring = false
	$Area2D.set_deferred("monitorable", false)

	# Play explosion animation
	$Sprite2D.visible = false  
	explosion_anim.visible = true
	GlobalAudioController.PlayGrenadeExplosion()
	explosion_anim.play("explode")

	await explosion_anim.animation_finished
	_on_explosion_animation_finished()

func _on_explosion_animation_finished():
	queue_free()
