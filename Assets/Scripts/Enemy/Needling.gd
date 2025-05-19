extends Enemy  # Inherit from Enemy.gd

@onready var sprite = $AnimatedSprite2D  # was $Sprite2D

var BulletSpeed = 900
var ShotsFired = 0
var ShotsBeforeMoving = randi_range(1, 3)
var IsMovingRandomly = false
var Weapon: PackedScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/enemy_sniper.tscn")
@onready var fire_delay_timer = Timer.new()

var queued_fire = false
var fire_direction = Vector2.ZERO
var is_firing = false

func start():
	Speed = 80
	Health = 50
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 4)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)
	
	WeaponScene = Weapon
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

	# Fire animation delay timer
	fire_delay_timer.one_shot = true
	fire_delay_timer.connect("timeout", Callable(self, "_on_fire_delay_timeout"))
	add_child(fire_delay_timer)
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

func _physics_process(_delta):
	var target_pos: Vector2

	if IsMovingRandomly:
		var player = resolve_target()
		target_pos = nav.target_position
		if global_position.distance_to(player.global_position) <= 100:
			IsMovingRandomly = false
		elif nav.is_navigation_finished() or position.distance_to(nav.get_next_path_position()) < 10:
			IsMovingRandomly = false
			velocity = Vector2.ZERO
			sprite.stop()
	else:
		var Player = resolve_target()
		target_pos = Player.position
		nav.target_position = target_pos

	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()

	if not IsMovingRandomly and (position.distance_to(target_pos) >= 100) or is_firing:
		velocity = Vector2.ZERO
		sprite.modulate.a = 0.2
	elif IsMovingRandomly:
		Speed = 60
		sprite.modulate.a = 0.65
		velocity = Direction * Speed
	else:
		Speed = 120
		sprite.modulate.a = 1
		velocity = Direction * Speed
			
	# ANIMATION HANDLING
	if is_firing:
		# Keep firing animation playing slowly
		sprite.speed_scale = 0.35
		# Moving animation stays the same
	elif IsMovingRandomly or (not IsMovingRandomly and velocity.length() > 0):
		if sprite.animation != "move":
			sprite.speed_scale = 1
			sprite.play("move")
		if abs(velocity.x) > 0.1:
			sprite.flip_h = velocity.x > 0
	else:
		# Stop the animation (just don't PAUSE it)
		sprite.speed_scale = 0

	move_and_slide()

func fire():
	print("Trying to fire...")
	if IsMovingRandomly or velocity.length() > 1 or is_firing:
		return # Don't fire while moving or while already firing

	if CurrentWeapon:
		is_firing = true
		sprite.play("fire")
		fire_delay_timer.start(1.5)

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

func _on_fire_delay_timeout():
	var Player = get_tree().get_nodes_in_group(Target).front()
	if CurrentWeapon:
		fire_direction = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, fire_direction)
		ShotsFired += 1
		if ShotsFired >= ShotsBeforeMoving:
			random_move()

func _on_animation_finished():
	if sprite.animation == "fire":
		is_firing = false
		
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

	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)
		
func get_flash_sprite() -> CanvasItem:
	return sprite 
