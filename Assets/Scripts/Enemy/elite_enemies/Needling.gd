extends Enemy  # Inherit from Enemy.gd

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aim_line: Line2D = $AimLine
@onready var laser_flash_tween := create_tween()

var BulletSpeed: float = 900
var ShotsFired: int = 0
var ShotsBeforeMoving: int = randi_range(1, 3)
var IsMovingRandomly: bool = false
var Weapon: PackedScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/enemy_sniper.tscn")

var los_check_ready: bool = false
var los_check

var queued_fire: bool = false
var fire_direction: Vector2 = Vector2.ZERO
var is_firing: bool = false

var flee_timer: float = 3.0
var is_fleeing: bool = false
const FLEE_DISTANCE: float = 120.0
const FLEE_RECALCULATE_INTERVAL: float = 0.5

func start():
	Speed = 150
	Health = 40
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	await get_tree().physics_frame  # Ensures physics state is initialized
	sprite.connect("frame_changed", Callable(self, "_on_sprite_frame_changed"))
	laser_flash_tween = get_tree().create_tween()
	los_check = get_world_2d().direct_space_state
	los_check_ready = true  

	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 4)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)

	WeaponScene = Weapon
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _process(delta):
	super._process(delta)  
	if Health <= 0:
		for i in range(1):
			drop_xp()  # Custom drop_xp in Needling.gd
		
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		
		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position) 
		queue_free()

func _physics_process(delta):
	var player = resolve_target()
	var target_pos: Vector2

	# Handle fleeing logic
	if player:
		var dist = global_position.distance_to(player.global_position)
		
		if dist < FLEE_DISTANCE:
			is_fleeing = true
			flee_timer -= delta
			if flee_timer <= 0:
				move_away_from_player()
				flee_timer = FLEE_RECALCULATE_INTERVAL
		else:
			is_fleeing = false

	# Only use random movement if fleeing or patrolling
	if IsMovingRandomly or is_fleeing:
		target_pos = nav.target_position

		if not is_fleeing:
			# If not fleeing, stop random move if we’re near target
			if nav.is_navigation_finished() or position.distance_to(nav.get_next_path_position()) < 10:
				IsMovingRandomly = false
				velocity = Vector2.ZERO
				sprite.stop()
	else:
		if player:
			target_pos = player.global_position
			nav.target_position = target_pos

	# Movement direction
	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()

	# Movement control
	if not IsMovingRandomly and not is_fleeing and (position.distance_to(target_pos) >= 100 or is_firing):
		velocity = Vector2.ZERO
		sprite.modulate.a = 0.2
	elif IsMovingRandomly or is_fleeing:
		Speed = 120
		sprite.modulate.a = 0.65
		velocity = Direction * Speed
	else:
		Speed = 120
		sprite.modulate.a = 1
		velocity = Direction * Speed

	# Animation control
	if is_firing:
		sprite.speed_scale = 1
	elif IsMovingRandomly or is_fleeing or velocity.length() > 0.1:
		if sprite.animation != "move":
			sprite.speed_scale = 1
			sprite.play("move")
		if abs(velocity.x) > 0.1:
			sprite.flip_h = velocity.x > 0
	else:
		sprite.speed_scale = 0

	update_aim_laser()

	move_and_slide()

func fire():
	if IsMovingRandomly or velocity.length() > 1 or is_firing or not los_check_ready:
		return

	var player = resolve_target()
	if not player:
		return

	var player_pos = player.global_position
	var query = PhysicsRayQueryParameters2D.create(global_position, player_pos)
	query.exclude = [self]
	query.collision_mask = 1 << 2  # Wall/environment

	var result = los_check.intersect_ray(query)

	if not result or result.collider.is_in_group("Player"):
		# Set up laser line
		aim_line.clear_points()
		aim_line.add_point(Vector2.ZERO)
		aim_line.add_point(to_local(player_pos))
		aim_line.visible = true
		aim_line.default_color = Color(0.0, 0.8, 0.0, 0.0)  # Start transparent

		# Flash the laser a few times
		var flashes = 6
		var flash_duration = 0.05
		laser_flash_tween = get_tree().create_tween()
		for i in range(flashes):
			laser_flash_tween.tween_property(aim_line, "modulate:a", 1.0, flash_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			laser_flash_tween.tween_property(aim_line, "modulate:a", 0.0, flash_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		# After flashing, fire
		laser_flash_tween.tween_callback(Callable(self, "_begin_fire_animation"))

func random_move():
	IsMovingRandomly = true
	ShotsFired = 0
	ShotsBeforeMoving = randi_range(1, 3)

	# Pick a random offset within 100–150 pixels
	var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
	var target_pos = global_position + offset

	# Clamp within viewport
	var screen_size = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, 0, screen_size.x)
	target_pos.y = clamp(target_pos.y, 0, screen_size.y)

	nav.target_position = target_pos


func shoot_now():
	var Player = get_tree().get_nodes_in_group(Target).front()
	if not Player:
		return

	if CurrentWeapon:
		fire_direction = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, fire_direction)
		ShotsFired += 1
		if ShotsFired >= ShotsBeforeMoving:
			random_move()

func _on_animation_finished():
	if sprite.animation == "fire":
		is_firing = false
		#aim_line.visible = false 
		
func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(2)
		
		var direction = (global_position - body.global_position).normalized()
		var dodge_distance = Speed * 0.6
		var start_position = global_position
		var dodge_vector = direction.normalized() * dodge_distance
		var end_position = start_position + dodge_vector
		
		# Temporarily disable collisions with enemies
		var collision_shape = $CollisionShape2D
		collision_shape.disabled = true
		
		# Use raycast-style check to find the first collision point along the path
		var space_state = get_world_2d().direct_space_state
		var ray_params = PhysicsRayQueryParameters2D.create(start_position, end_position)
		ray_params.exclude = [self]
		ray_params.collision_mask = 1 << 2  # Environment only (e.g., walls)
		
		var ray_result = space_state.intersect_ray(ray_params)
		if ray_result:
			# Adjust endpoint to stop just before hitting the wall
			end_position = ray_result.position - direction.normalized() * 4.0  # 2px offset for safety
			
		# Tween to final position smoothly
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", end_position, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		# Re-enable collision
		collision_shape.disabled = false
		return

	if is_in_group("Enemy") and body.is_in_group("Minion"):
		body.queue_free()
		deal_damage(10)
		
func get_flash_sprite() -> CanvasItem:
	return sprite 

func update_aim_laser():
	if not los_check_ready:
		aim_line.visible = false
		return

###
	# Hide aim line when moving or fleeing
	if velocity.length() > 0.5 or IsMovingRandomly or is_fleeing:
		aim_line.visible = false
		return
###

	var player = resolve_target()
	if not player:
		aim_line.visible = false
		return

	var player_pos = player.global_position
	var query = PhysicsRayQueryParameters2D.create(global_position, player_pos)
	query.exclude = [self]
	query.collision_mask = 1 << 2  # Only collide with walls

	var result = los_check.intersect_ray(query)

	var hit_pos = player_pos
	var has_los = true

	if result and not result.collider.is_in_group("Player"):
		hit_pos = result.position
		has_los = false

	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(to_local(hit_pos))
	aim_line.visible = true

	# Laser color while firing
	if is_firing:
		aim_line.default_color = Color(0.0, 0.8, 0.0, 0.8)  # Bright Green
	elif has_los:
		aim_line.default_color = Color(0.9, 0.1, 0.0, 0.8)  # Dim Red
	else:
		aim_line.default_color = Color(0.5, 0.2, 0.2, 0.4)  # Dim red 

func _on_sprite_frame_changed():
	if sprite.animation == "fire" and sprite.frame == 2 and is_firing:  # adjust frame index as needed
		shoot_now()

func _begin_fire_animation():
	aim_line.default_color = Color(1.0, 0.1, 0.1, 1.0)  # Bright red
	aim_line.modulate.a = 1.0
	is_firing = true
	sprite.play("fire")
	
	# Fallback: force stop after 1s if animation doesn't finish
	var stop_timer = get_tree().create_timer(1.0)
	stop_timer.timeout.connect(Callable(self, "_force_stop_fire"))
	
func _force_stop_fire():
	if is_firing:  # still stuck
		sprite.play("idle")
		aim_line.visible = false
		is_firing = false
		
func move_away_from_player():
	var player = resolve_target()
	if not player:
		return
	
	var direction_away = (global_position - player.global_position).normalized()
	var distance = randf_range(150, 250)
	var safe_position = global_position + direction_away * distance
	
	# Clamp within screen
	var screen_size = get_viewport_rect().size
	safe_position.x = clamp(safe_position.x, 0, screen_size.x)
	safe_position.y = clamp(safe_position.y, 0, screen_size.y)
	
	IsMovingRandomly = true
	nav.target_position = safe_position
