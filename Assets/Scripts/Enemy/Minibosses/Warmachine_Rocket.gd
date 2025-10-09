extends Enemy  # Inherit from Enemy.gd

@onready var sprite = $AnimatedSprite2D  # was $Sprite2D
@onready var fire_duration_timer = Timer.new()

var BulletSpeed = 900
var ShotsFired = 0
var ShotsBeforeMoving = randi_range(3, 9)
var IsMovingRandomly = false
var Weapon: PackedScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/WarmachineRocketLauncher.tscn")
@onready var fire_delay_timer = Timer.new()

@export var grenade_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Projectiles/EnemyProjectiles/EnemyGrenade.tscn")
var rocket_fire_sfx = preload("res://Assets/Sound/SFX/WeaponSFX/RocketLauncherShot.mp3")
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

# --- Shield variables ---
@onready var shield_sprite: Sprite2D = $ShieldBubble/Sprite
var ShieldMax := 500
var Shield := ShieldMax
var shield_regen_rate := 75.0      # HP per second when regenerating
var shield_regen_delay := 5.0      # seconds of no damage before regen starts
var shield_regen_timer := 0.0
var regen_multiplier := 1.0
var shield_taking_damage := false

var aggressive_mode := false
var normal_speed := 80
var aggressive_speed := 100       
var aggressive_fire_delay := 0.05   
var aggressive_grenade_chance := 40 

var last_position: Vector2
var move_timer := 0.0       
var move_timeout := 5.0    

func start():
	Speed = 80
	Health = 1000
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	randomize()
	add_to_group("Boss")
	add_to_group("WarmachineRocket")
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
	update_shield_visual()
	
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
	
	# Shield regen
	if Shield < ShieldMax:
		shield_regen_timer += delta
		if shield_regen_timer >= shield_regen_delay:
			regen_multiplier = 2.0 if Shield < ShieldMax * 0.3 else 1.0
			Shield = min(Shield + shield_regen_rate * regen_multiplier * delta, ShieldMax)
			update_shield_visual()
	
	if Shield > 0 and not aggressive_mode:
		enter_aggressive_mode()

	if Health <= 0:
		for i in range(1):
			drop_xp()  # Custom drop_xp in Needling.gd
		
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		
		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position) 
		queue_free()

func _physics_process(delta):
	if is_ramming:
		velocity = ram_direction * Speed * RAM_SPEED_MULTIPLIER
		if sprite.animation != "move":
			sprite.play("move")
		move_and_slide()
		last_position = global_position
		return

	var player = resolve_target()
	var stop_threshold = 10  # Distance considered "reached"

	if IsMovingRandomly:
		var next_pos = nav.get_next_path_position()
		var to_next = next_pos - global_position

		# Track movement time
		move_timer += delta

		if to_next.length() < stop_threshold or move_timer >= move_timeout:
			# Stop moving if close enough OR timed out
			IsMovingRandomly = false
			velocity = Vector2.ZERO
			sprite.stop()
			move_timer = 0.0  # reset timer
			fire()
		else:
			# Move at Speed per second
			velocity = to_next.normalized() * Speed
			if sprite.animation != "move":
				sprite.play("move")
			move_and_slide()  # only once

	elif player and not is_firing and not is_ramming:
		var distance = global_position.distance_to(player.global_position)
		if distance > 400:
			velocity = (player.global_position - global_position).normalized() * Speed
			if sprite.animation != "move":
				sprite.play("move")
			move_and_slide()  # only once
		else:
			velocity = Vector2.ZERO
			sprite.stop()

	last_position = global_position

func fire():
	if IsMovingRandomly or velocity.length() > 1 or is_firing or is_ramming:
		return

	var player = resolve_target()
	if player and global_position.distance_to(player.global_position) <= 400:
		var grenade_chance = aggressive_grenade_chance if aggressive_mode else 50
		if randi_range(0, 100) < grenade_chance:
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
		
		update_sprite_facing(fire_direction)
		
		CurrentWeapon.attempt_to_fire(global_position, fire_direction)
		ShotsFired += 1
		
		var sfx_player = AudioStreamPlayer2D.new()
		sfx_player.volume_db = -6.0
		sfx_player.stream = rocket_fire_sfx
		sfx_player.position = global_position
		sfx_player.bus = "SFX" 
		get_parent().add_child(sfx_player)
		sfx_player.play()
		sfx_player.connect("finished", Callable(sfx_player, "queue_free"))
		
	# Fire again in 0.1–0.2 seconds (simulate burst fire)
	var min_delay = aggressive_fire_delay if aggressive_mode else 0.1
	var max_delay = (aggressive_fire_delay + 0.05) if aggressive_mode else 0.2
	fire_delay_timer.start(randf_range(min_delay, max_delay))

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
		var grenade_scene: PackedScene = preload("res://Prefabs/CodePrefabs/Projectiles/EnemyProjectiles/EnemyGrenade.tscn")
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
	# Pick a random target near the player
	var player = resolve_target()
	if not player:
		return
	
	var max_offset = 200
	var raw_target = player.global_position + Vector2(randf_range(-max_offset, max_offset), randf_range(-max_offset, max_offset))

	# Snap to closest valid point on navmesh
	var nav_map_rid = nav.get_navigation_map()
	if nav_map_rid != RID():
		var closest_point = NavigationServer2D.map_get_closest_point(nav_map_rid, raw_target)
		nav.target_position = closest_point
		IsMovingRandomly = true
		last_position = global_position

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

func deal_damage(damage: int, from_position = null):
	if Shield > 0:
		Shield -= damage
		shield_regen_timer = 0.0
		update_shield_visual()

		# --- NEW: enable aggressive mode while shield is up
		if not aggressive_mode:
			enter_aggressive_mode()

		GlobalAudioController.PlayShieldPing()

		if Shield <= 0:
			var leftover = -Shield
			Shield = 0
			update_shield_visual()

			GlobalAudioController.PlayShieldBreak()

			# --- NEW: disable aggressive mode when shield breaks
			exit_aggressive_mode()

			super.deal_damage(leftover, from_position)
		return

	super.deal_damage(damage, from_position)

func update_shield_visual():
	var ratio := Shield / float(ShieldMax)
	if ratio <= 0:
		shield_sprite.visible = false
		return
	shield_sprite.visible = true
	var color_blue = Color(0.2, 0.6, 1.0, 0.4)
	var color_red  = Color(1.0, 0.2, 0.2, 0.4)
	shield_sprite.modulate = color_blue.lerp(color_red, 1.0 - ratio)
	shield_sprite.scale = Vector2.ONE * (0.5 + 0.2 * (1.0 - ratio))

func enter_aggressive_mode():
	aggressive_mode = true
	normal_speed = Speed
	Speed = aggressive_speed

func exit_aggressive_mode():
	aggressive_mode = false
	Speed = normal_speed

func update_sprite_facing(direction: Vector2) -> void:
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
