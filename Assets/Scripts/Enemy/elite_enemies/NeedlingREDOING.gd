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

# --- Flee variables ---
var movement_timer: float = 0.0
var is_fleeing: bool = false
const BASE_SPEED: float = 150
const MOVE_MULTIPLIER: float = 2.0
const FLEE_DISTANCE: float = 120.0
const MAX_MOVE_TIME: float = 3.0

var flee_timer: float = 3.0
const FLEE_RECALCULATE_INTERVAL: float = 0.5

func start():
	Speed = BASE_SPEED
	Health = 40
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	await get_tree().physics_frame
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
		drop_xp()
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position) 
		queue_free()

func _physics_process(delta):
	super._physics_process(delta)

	var player = resolve_target()

	# --- Fleeing / Movement Logic ---
	if player:
		var dist = global_position.distance_to(player.global_position)

		if dist < FLEE_DISTANCE:
			# Player too close → flee toward cover
			if not is_fleeing:
				move_away_from_player()

			if is_fleeing:
				# Dynamic peek-ahead adjustment
				var flee_dir = (nav.target_position - global_position).normalized()
				var player_dir = (player.global_position - global_position).normalized()
				var approach_angle = rad_to_deg(flee_dir.angle_to(player_dir))
				
				if abs(approach_angle) < 60:
					var adjust_angle = deg_to_rad(randf_range(-30, 30))
					flee_dir = flee_dir.rotated(adjust_angle)
					var new_target = global_position + flee_dir * randf_range(200, 300)

					# Clamp to screen bounds
					var screen_size = get_viewport_rect().size
					new_target.x = clamp(new_target.x, 0, screen_size.x)
					new_target.y = clamp(new_target.y, 0, screen_size.y)

					nav.target_position = new_target
		else:
			is_fleeing = false
			IsMovingRandomly = false

	# --- Fail-safe Timer ---
	if IsMovingRandomly or is_fleeing:
		movement_timer += delta
		if movement_timer >= MAX_MOVE_TIME:
			IsMovingRandomly = false
			is_fleeing = false
			velocity = Vector2.ZERO
			sprite.stop()
			movement_timer = 0.0

	# --- Movement Speed & Direction ---
	if IsMovingRandomly or is_fleeing:
		var Direction = (nav.target_position - global_position)
		if Direction.length() > 0:
			Direction = Direction.normalized()
		Speed = BASE_SPEED * MOVE_MULTIPLIER
		velocity = Direction * Speed
		sprite.modulate.a = 0.65
	else:
		velocity = Vector2.ZERO
		Speed = BASE_SPEED
		sprite.modulate.a = 1

	# --- Animation ---
	if velocity.length() > 0.1:
		if sprite.animation != "move":
			sprite.speed_scale = 1
			sprite.play("move")
		sprite.flip_h = velocity.x > 0
	else:
		sprite.speed_scale = 0

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
	query.collision_mask = 1 << 2

	var result = los_check.intersect_ray(query)

	if not result or result.collider.is_in_group("Player"):
		aim_line.clear_points()
		aim_line.add_point(Vector2.ZERO)
		aim_line.add_point(to_local(player_pos))
		aim_line.visible = true
		aim_line.default_color = Color(0.0, 0.8, 0.0, 0.0)

		var flashes = 6
		var flash_duration = 0.05
		laser_flash_tween = get_tree().create_tween()
		for i in range(flashes):
			laser_flash_tween.tween_property(aim_line, "modulate:a", 1.0, flash_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			laser_flash_tween.tween_property(aim_line, "modulate:a", 0.0, flash_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

		laser_flash_tween.tween_callback(Callable(self, "_begin_fire_animation"))

func _on_sprite_frame_changed():
	if sprite.animation == "fire" and sprite.frame == 2 and is_firing:
		shoot_now()

func _begin_fire_animation():
	aim_line.default_color = Color(1.0, 0.1, 0.1, 1.0)
	aim_line.modulate.a = 1.0
	is_firing = true
	sprite.play("fire")
	var stop_timer = get_tree().create_timer(1.0)
	stop_timer.timeout.connect(Callable(self, "_force_stop_fire"))

func _force_stop_fire():
	if is_firing:
		sprite.play("idle")
		aim_line.visible = false
		is_firing = false

func move_away_from_player():
	var player = resolve_target()
	if not player:
		return

	var base_direction = (global_position - player.global_position).normalized()
	base_direction = base_direction.rotated(deg_to_rad(randf_range(-30, 30)))

	var max_distance = 300
	var min_distance = 200
	var space_state = get_world_2d().direct_space_state

	var best_position: Vector2 = global_position + base_direction * randf_range(min_distance, max_distance)
	var best_score = 0.0

	for angle_offset in range(-30, 31, 15):
		var dir = base_direction.rotated(deg_to_rad(angle_offset))
		var target = global_position + dir * max_distance
		var query = PhysicsRayQueryParameters2D.create(global_position, target)
		query.exclude = [self]
		query.collision_mask = 1 << 2

		var result = space_state.intersect_ray(query)
		if result:
			var cover_pos = result.position - dir * 20
			var player_dir = (player.global_position - global_position).normalized()
			var approach_angle = rad_to_deg(dir.angle_to(player_dir))
			var angle_penalty = 0.0
			if abs(approach_angle) < 60:
				angle_penalty = 50.0
			var score = cover_pos.distance_to(player.global_position) - angle_penalty
			if score > best_score:
				best_score = score
				best_position = cover_pos

	var screen_size = get_viewport_rect().size
	best_position.x = clamp(best_position.x, 0, screen_size.x)
	best_position.y = clamp(best_position.y, 0, screen_size.y)

	nav.target_position = best_position
	IsMovingRandomly = true
	is_fleeing = true
	movement_timer = 0.0

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

func random_move():
	IsMovingRandomly = true
	ShotsFired = 0
	ShotsBeforeMoving = randi_range(1, 3)
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var target_pos = global_position + offset
	var screen_size = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, 0, screen_size.x)
	target_pos.y = clamp(target_pos.y, 0, screen_size.y)
	nav.target_position = target_pos

func get_flash_sprite() -> CanvasItem:
	return sprite

func update_aim_laser():
	if not los_check_ready:
		aim_line.visible = false
		return

	if velocity.length() > 0.5 or IsMovingRandomly or is_fleeing:
		aim_line.visible = false
		return

	var player = resolve_target()
	if not player:
		aim_line.visible = false
		return

	var player_pos = player.global_position
	var query = PhysicsRayQueryParameters2D.create(global_position, player_pos)
	query.exclude = [self]
	query.collision_mask = 1 << 2

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

	if is_firing:
		aim_line.default_color = Color(0.0, 0.8, 0.0, 0.8)
	elif has_los:
		aim_line.default_color = Color(0.9, 0.1, 0.0, 0.8)
	else:
		aim_line.default_color = Color(0.5, 0.2, 0.2, 0.4)

func _on_animation_finished():
	if sprite.animation == "fire":
		is_firing = false
