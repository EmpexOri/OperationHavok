extends Enemy  # Inherit from Enemy.gd

@onready var sprite = $AnimatedSprite2D  # was $Sprite2D
@onready var fire_duration_timer = Timer.new()
@onready var move_timeout_timer := Timer.new()

var BulletSpeed = 900
var ShotsFired = 0
var ShotsBeforeMoving = randi_range(1, 3)
var IsMovingRandomly = false
var Weapon: PackedScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/EnemyMinigun.tscn")
@onready var fire_delay_timer = Timer.new()

var queued_fire = false
var fire_direction = Vector2.ZERO
var is_firing = false

var is_ramming = false
var ram_direction = Vector2.ZERO
const RAM_TRIGGER_DISTANCE = 100
const RAM_SPEED_MULTIPLIER = 1.75
const RAM_DURATION = 0.6
const RAM_DAMAGE = 20
@onready var ram_timer := Timer.new()

@onready var fire_sfx: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
const FIRE_SOUND_PATH := "res://Assets/Sound/SFX/WeaponSFX/Enemy/Gatling_Minigun.wav"

func start():
	Speed = 60
	Health = 75
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	fire_sfx.stream = load(FIRE_SOUND_PATH)
	fire_sfx.bus = "SFX" 
	fire_sfx.volume_db = -1.0
	add_child(fire_sfx)
	
	var firetimer = Timer.new()
	fire_duration_timer.one_shot = true
	fire_duration_timer.connect("timeout", Callable(self, "_on_fire_duration_timeout"))
	add_child(fire_duration_timer)
	firetimer.wait_time = randf_range(2, 4)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)
	move_timeout_timer.one_shot = true
	move_timeout_timer.wait_time = 5.0  
	move_timeout_timer.connect("timeout", Callable(self, "_on_move_timeout"))
	add_child(move_timeout_timer)
	
	WeaponScene = Weapon
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

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
		
		var anim_name = "move_down_right"
		if ram_direction.y < 0:
			anim_name = "move_up_right"
		if sprite.animation != anim_name:
			sprite.play(anim_name)
		sprite.flip_h = ram_direction.x < 0
		
		move_and_slide()
		return
		
	var Player = resolve_target()
	var target_pos: Vector2
	
	# Handle random movement
	if IsMovingRandomly:
		target_pos = nav.target_position
		
		if nav.is_navigation_finished() or position.distance_to(nav.get_next_path_position()) < 10:
			_cancel_random_move()
		elif Player and global_position.distance_to(Player.global_position) <= 100:
			_cancel_random_move()
			
	else:
		# Handle ramming trigger
		if not is_ramming and Player and global_position.distance_to(Player.global_position) <= RAM_TRIGGER_DISTANCE:
			start_ramming(Player)
			return
			
		if Player:
			target_pos = Player.global_position
			nav.target_position = target_pos
			
	var next_path = nav.get_next_path_position()
	var Direction = (next_path - global_position).normalized()
	if Direction == Vector2.ZERO:
		# Keep last direction to prevent animation flicker
		Direction = velocity.normalized()
		
	if is_firing:
		velocity = Vector2.ZERO
		sprite.modulate.a = 0.2
		
	elif IsMovingRandomly:
		Speed = 60
		sprite.modulate.a = 0.65
		velocity = Direction * Speed
		
	else:
		Speed = 80
		sprite.modulate.a = 1.0
		
		if Player and position.distance_to(Player.global_position) > 100:
			velocity = Direction * Speed
		else:
			velocity = Vector2.ZERO
			sprite.modulate.a = 0.4
			
	if not is_firing and not is_ramming:
		# Update facing only (do not play animation here)
		var to_player = Vector2.ZERO
		if Player:
			to_player = (Player.global_position - global_position).normalized()
			fire_direction = to_player
			sprite.flip_h = to_player.x < 0
			
	_update_animation()
	move_and_slide()
	
func _update_animation():
	if is_firing:
		# Choose the correct firing animation based on aim direction
		var anim_name = "fire_down_right"
		if fire_direction.y < 0:
			anim_name = "fire_up_right"
		sprite.play(anim_name)
		sprite.flip_h = fire_direction.x < 0

	elif IsMovingRandomly or velocity.length() > 0:
		# Choose the correct movement animation based on vertical direction
		var anim_name = "move_down_right"
		if velocity.y < 0:
			anim_name = "move_up_right"
		if sprite.animation != anim_name:
			sprite.play(anim_name)
		sprite.flip_h = velocity.x < 0

	else:
		sprite.stop()
		
func _update_facing_to_player():
	var Player = get_tree().get_nodes_in_group(Target).front()
	if Player:
		var to_player = (Player.global_position - global_position).normalized()
		fire_direction = to_player  # keep direction consistent for animation

		# Update facing based on where the player is
		var anim_name = "move_down_right"
		if to_player.y < 0:
			anim_name = "move_up_right"
		if sprite.animation != anim_name and not is_firing:
			sprite.play(anim_name)
		sprite.flip_h = to_player.x < 0

func fire():
	if IsMovingRandomly or velocity.length() > 1 or is_firing:
		return

	if CurrentWeapon:
		is_firing = true
		
		var fire_duration = randf_range(2.0, 5.0)
		fire_duration_timer.start(fire_duration)
		
		_fire_burst()  # Start firing loop
		
func _fire_burst():
	if not is_firing or not CurrentWeapon:
		return
		
	var Player = get_tree().get_nodes_in_group(Target).front()
	if Player:
		fire_direction = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, fire_direction)
		ShotsFired += 1
		
		if fire_sfx.playing:
			fire_sfx.stop() 
		fire_sfx.play()

	fire_delay_timer.start(randf_range(0.1, 0.2))

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
	move_timeout_timer.start()

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

func _cancel_random_move():
	IsMovingRandomly = false
	velocity = Vector2.ZERO
	sprite.stop()
	if not move_timeout_timer.is_stopped():
		move_timeout_timer.stop()
