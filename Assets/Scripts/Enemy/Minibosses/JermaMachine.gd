extends "res://Assets/Scripts/Enemy/Minibosses/Warmachine.gd"

@onready var jump_cooldown_timer := Timer.new()
@onready var collision_shape: CollisionShape2D = $CollisionShape2D  

# --- Jump constants ---
const JUMP_RANGE := 300
const JUMP_COOLDOWN := 6.0  # seconds between jumps
const JUMP_DURATION := 0.6  # animation duration before landing
const JUMP_CHANCE := 0.25 
const JUMP_SCALE_PEAK := 1.3
const JUMP_ATTEMPTS := 6  # how many random tries to find a clear jump spot

var is_jumping := false

func _ready():
	super._ready()
	
	jump_cooldown_timer.one_shot = true
	add_child(jump_cooldown_timer)
	
	if sprite.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		sprite.disconnect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished_custom"))

func fire():
	if IsMovingRandomly or velocity.length() > 1 or is_firing or is_ramming or is_jumping:
		return
		
	var player = resolve_target()
	if player and global_position.distance_to(player.global_position) <= 400:
		var grenade_chance = aggressive_grenade_chance if aggressive_mode else 50
		if randi_range(0, 100) < grenade_chance:
			grenade_mode = true
			grenade_shots_remaining = randi_range(2, 4)
			is_firing = true
			sprite.play("Attack_Right")
			_fire_grenade_salvo()
			return
			
	if CurrentWeapon:
		is_firing = true
		sprite.play("Attack_Right")
		fire_duration_timer.start(randf_range(3.0, 9.0))
		_fire_burst()

func attempt_jump():
	if is_jumping or jump_cooldown_timer.time_left > 0 or is_firing or is_ramming:
		return
		
	var nav_map_rid = nav.get_navigation_map()
	if nav_map_rid == RID():
		return
		
	var space_state = get_world_2d().direct_space_state
	
	for i in range(JUMP_ATTEMPTS):
		var raw_target = global_position + Vector2(
			randf_range(-JUMP_RANGE, JUMP_RANGE),
			randf_range(-JUMP_RANGE, JUMP_RANGE)
		)
		
		var closest_point = NavigationServer2D.map_get_closest_point(nav_map_rid, raw_target)
		if closest_point == Vector2.ZERO:
			continue
			
		var ray_params = PhysicsRayQueryParameters2D.create(global_position, closest_point)
		ray_params.exclude = [self]
		ray_params.collision_mask = 1 << 2
		
		var result = space_state.intersect_ray(ray_params)
		if result.size() == 0:
			jump_to_position(closest_point)
			return
	# If no valid point after several tries, do nothing
	return

func jump_to_position(target_pos: Vector2):
	is_jumping = true
	is_firing = false
	IsMovingRandomly = false
	is_ramming = false
	velocity = Vector2.ZERO
	
	# Disable collision while jumping
	if collision_shape:
		collision_shape.disabled = true
		
	update_sprite_facing(target_pos - global_position)
	sprite.play("Move_Jump_Right")
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move horizontally
	tween.tween_property(self, "global_position", target_pos, JUMP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Scale sprite up and down to simulate height
	tween.tween_property(sprite, "scale", Vector2(JUMP_SCALE_PEAK, JUMP_SCALE_PEAK), JUMP_DURATION / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), JUMP_DURATION / 2).set_delay(JUMP_DURATION / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Reset
	is_jumping = false
	sprite.scale = Vector2(1.0, 1.0)
	sprite.stop()
	jump_cooldown_timer.start(JUMP_COOLDOWN)
	
	# Re-enable collision after landing
	if collision_shape:
		collision_shape.disabled = false
	

func _physics_process(delta):
	super._physics_process(delta)
	
	if is_jumping:
		return
		
	if velocity.length() > 5:
		update_sprite_facing(velocity)
		
	# Handle upward movement animation
	if not is_firing and not is_ramming and velocity.length() > 10:
		if abs(velocity.y) > abs(velocity.x) and velocity.y < 0:
			if sprite.animation != "Move_Up":
				sprite.play("Move_Up")
				
	# Randomly decide to jump instead of moving normally
	if not is_firing and not is_ramming and not is_jumping and jump_cooldown_timer.is_stopped():
		if IsMovingRandomly or (randi_range(0, 100) < int(JUMP_CHANCE * 100)):
			attempt_jump()
			

func _on_animation_finished_custom():
	if sprite.animation == "Attack_Right":
		is_firing = false
	elif sprite.animation == "Move_Jump_Right":
		is_jumping = false
		sprite.stop()
		

func update_sprite_facing(direction: Vector2) -> void:
	sprite.flip_h = direction.x < 0
