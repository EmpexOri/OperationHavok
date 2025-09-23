extends Node2D
class_name NovaGrenade

@export var throw_force: float = 500.0
@export var explosion_radius: float = 150.0
@export var explosion_delay: float = 0.5
@export var instant_damage: float = 10.0
@export var dot_damage: float = 5.0
@export var dot_duration: float = 10.0
@export var explode_on_walls: bool = true
@export var stop_on_enemy_hit: bool = false
@export var debug_nova: bool = true

@onready var explosion_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var grenade_area: Area2D = $Area2D
@onready var explosion_area: Area2D = $ExplosionRadius
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var velocity: Vector2 = Vector2.ZERO
var exploding: bool = false
var land_sound_played: bool = false

# Unique sounds
@export var throw_sound: AudioStream
@export var land_sound: AudioStream
@export var explosion_sound: AudioStream

func start(start_position: Vector2, direction: Vector2):
	global_position = start_position
	velocity = direction.normalized() * throw_force
	if throw_sound:
		GlobalAudioController.PlayFromPlayerSFX(throw_sound)

func _ready():
	await get_tree().process_frame

	# Start the explosion timer
	$ExplosionTimer.wait_time = explosion_delay
	$ExplosionTimer.one_shot = true
	$ExplosionTimer.timeout.connect(_explode)
	$ExplosionTimer.start()

	# Connect grenade collision
	if grenade_area:
		grenade_area.body_entered.connect(_on_grenade_body_entered)

func _physics_process(delta):
	if exploding:
		if explosion_anim.visible:
			var frame_count = explosion_anim.sprite_frames.get_frame_count("explode")
			if explosion_anim.frame >= frame_count - 1:
				queue_free()
	else:
		_handle_movement(delta)

func _handle_movement(delta):
	var new_position = position + velocity * delta
	var space_state = get_world_2d().direct_space_state
	var hit_something = false

	# Check walls
	var wall_query = PhysicsRayQueryParameters2D.create(position, new_position)
	wall_query.exclude = [self]
	wall_query.collision_mask = 1 << 2 # wall layer
	if space_state.intersect_ray(wall_query):
		hit_something = true
		position = wall_query.from
		velocity = Vector2.ZERO
		if explode_on_walls:
			_explode()

	# Optional: stop on enemy hit
	var enemy_query = PhysicsRayQueryParameters2D.create(position, new_position)
	enemy_query.exclude = [self]
	enemy_query.collision_mask = 1 << 3 # enemy layer
	if stop_on_enemy_hit and space_state.intersect_ray(enemy_query):
		hit_something = true
		position = enemy_query.from
		velocity = Vector2.ZERO
		_explode()

	if not hit_something:
		position = new_position

	# Slow down
	velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)

func _on_grenade_body_entered(body: Node2D):
	if stop_on_enemy_hit and body.is_in_group("Enemy"):
		velocity = Vector2.ZERO
		_explode()

func _explode():
	if exploding:
		return
	exploding = true
	velocity = Vector2.ZERO

	# Play land sound
	if land_sound and not land_sound_played:
		GlobalAudioController.PlayFromPlayerSFX(land_sound)
		land_sound_played = true

	# Disable grenade collision
	if collision_shape:
		collision_shape.disabled = true
	if grenade_area:
		grenade_area.monitoring = false
		grenade_area.monitorable = false

	# Play explosion visuals
	if $Sprite2D:
		$Sprite2D.visible = false
	explosion_anim.visible = true
	explosion_anim.frame = 0
	explosion_anim.play("explode")

	# Play explosion sound
	if explosion_sound:
		ScreenShake.shake(randf_range(10.0, 15.0), 0.2)
		for player in GlobalAudioController.PlayerSFXChannels:
			if not player.playing:
				player.stream = explosion_sound
				player.volume_db = 2.5
				player.pitch_scale = randf_range(0.95, 1.05)
				player.play()
				break

	await get_tree().physics_frame
	_apply_explosion_damage()

func _apply_explosion_damage():
	if not explosion_area:
		return

	var enemies = explosion_area.get_overlapping_bodies()
	if debug_nova:
		print("[NovaGrenade] Explosion hits:", enemies.size())

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.is_in_group("Enemy"):
			continue

		if enemy.has_method("deal_damage"):
			enemy.deal_damage(int(round(instant_damage)), global_position)
		if enemy.has_method("apply_dot"):
			enemy.apply_dot(dot_damage, dot_duration)
		if debug_nova:
			print("[NovaGrenade] Hit:", enemy.name)
