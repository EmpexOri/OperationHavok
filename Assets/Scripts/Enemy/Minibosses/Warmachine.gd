extends Enemy  # Inherit from Enemy.gd

@onready var sprite = $AnimatedSprite2D  # was $Sprite2D
@onready var fire_duration_timer = Timer.new()

var BulletSpeed = 900
var ShotsFired = 0
var ShotsBeforeMoving = randi_range(3, 9)
var IsMovingRandomly = false
var Weapon: PackedScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/WarmachineGun.tscn")
@onready var fire_delay_timer = Timer.new()

@export var grenade_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Projectiles/EnemyProjectiles/EnemyGrenade.tscn")
var grenade_mode = false
var grenade_shots_remaining = 0
var grenade_salvo_timer: Timer

var queued_fire = false
var fire_direction = Vector2.ZERO
var is_firing = false

var is_ramming = false
var ram_direction = Vector2.ZERO
const RAM_TRIGGER_DISTANCE = 100
const RAM_SPEED_MULTIPLIER = 1.5
const RAM_DURATION = 0.6
const RAM_DAMAGE = 30
@onready var ram_timer := Timer.new()

func start():
	Speed = 80
	Health = 750
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	var firetimer = Timer.new()
	fire_duration_timer.one_shot = true
	fire_duration_timer.connect("timeout", Callable(self, "_on_fire_duration_timeout"))
	add_child(fire_duration_timer)
	firetimer.wait_time = randf_range(1, 3)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)
	grenade_salvo_timer = Timer.new()
	grenade_salvo_timer.one_shot = true
	grenade_salvo_timer.connect("timeout", Callable(self, "_fire_grenade_salvo"))
	add_child(grenade_salvo_timer)
	
	WeaponScene = Weapon
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

	# Fire animation delay timer
	fire_delay_timer.one_shot = true
	fire_delay_timer.connect("timeout", Callable(self, "_on_fire_delay_timeout"))
	add_child(fire_delay_timer)
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
	ram_timer.one_shot = true
	ram_timer.wait_time = RAM_DURATION
	ram_timer.connect("timeout", Callable(self, "_on_ram_timeout"))
	add_child(ram_timer)

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
	if is_ramming:
		velocity = ram_direction * Speed * RAM_SPEED_MULTIPLIER
		sprite.modulate.a = 1.0
		sprite.speed_scale = 1.0
		if sprite.animation != "move":
			sprite.play("move")
		move_and_slide()
		return

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
		if not is_ramming and Player and global_position.distance_to(Player.global_position) <= RAM_TRIGGER_DISTANCE:
			start_ramming(Player)
			return  # Stop all normal logic during ramming
		target_pos = Player.position
		nav.target_position = target_pos

	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()

	if not IsMovingRandomly and (position.distance_to(target_pos) >= 100) or is_firing:
		velocity = Vector2.ZERO
		sprite.modulate.a = 0.2
	elif IsMovingRandomly:
		Speed = 80
		sprite.modulate.a = 0.65
		velocity = Direction * Speed
	else:
		Speed = 120
		sprite.modulate.a = 1
		velocity = Direction * Speed
			
	# ANIMATION HANDLING
	if is_firing:
		# Keep firing animation playing slowly
		sprite.speed_scale = 1 #0.35
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
	if IsMovingRandomly or velocity.length() > 1 or is_firing or is_ramming:
		return

	var player = resolve_target()
	if player and global_position.distance_to(player.global_position) <= 400:
		if randi_range(0, 100) < 50:  # 40% chance to grenade
			grenade_mode = true
			grenade_shots_remaining = randi_range(2, 4)  # 2-4 grenade salvos
			is_firing = true
			sprite.play("fire")
			_fire_grenade_salvo()
			return
	
	# Default gunfire
	if CurrentWeapon:
		is_firing = true
		sprite.play("fire")
		fire_duration_timer.start(randf_range(3.0, 9.0))
		_fire_burst()
		
func _fire_burst():
	if not is_firing or not CurrentWeapon:
		return

	var Player = get_tree().get_nodes_in_group(Target).front()
	if Player:
		fire_direction = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, fire_direction)
		ShotsFired += 1

	# Fire again in 0.1–0.2 seconds (simulate burst fire)
	fire_delay_timer.start(randf_range(0.1, 0.2))

func _fire_grenade_salvo():
	if not grenade_mode or grenade_shots_remaining <= 0 or is_ramming:
		# Cancel or end grenade attack
		grenade_mode = false
		is_firing = false
		sprite.stop()
		random_move()
		return

	var player = resolve_target()
	if not player:
		grenade_mode = false
		is_firing = false
		return

	# Play same fire animation
	if sprite.animation != "fire":
		sprite.play("fire")

	# Determine direction and offset baseline
	var base_dir = (player.global_position - global_position).normalized()
	var right = Vector2(-base_dir.y, base_dir.x)  # Perpendicular to direction

	for i in range(2):
		var grenade = grenade_scene.instantiate()
		get_parent().add_child(grenade)

		# 40% offset left or right
		var offset_dir = right * (randf_range(-0.4, 0.4))  # 40% sideways deviation
		var spawn_position = global_position + offset_dir * 48  # ~20-30 px shift

		var target_position = player.global_position + Vector2(randf_range(-24, 24), randf_range(-24, 24))
		grenade.start(spawn_position, target_position)

	grenade_shots_remaining -= 1
	grenade_salvo_timer.start(randf_range(0.4, 0.8))

func random_move():
	IsMovingRandomly = true
	ShotsFired = 0
	ShotsBeforeMoving = randi_range(1, 1)

	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var target_pos = global_position + offset

	var screen_size = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, 0, screen_size.x)
	target_pos.y = clamp(target_pos.y, 0, screen_size.y)

	nav.target_position = target_pos

func _on_fire_delay_timeout():
	_fire_burst()
	
func _on_fire_duration_timeout():
	is_firing = false
	sprite.stop()
	random_move()  # Move again after firing ends

func _on_animation_finished():
	if sprite.animation == "fire":
		is_firing = false
		
func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		if is_ramming:
			body.deal_damage(RAM_DAMAGE)
		else:
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

func start_ramming(player):
	is_ramming = true
	is_firing = false
	IsMovingRandomly = false
	ram_direction = (player.global_position - global_position).normalized()
	ram_timer.start()

func _on_ram_timeout():
	is_ramming = false
	velocity = Vector2.ZERO
