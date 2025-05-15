extends Enemy

@onready var sprite := $AnimatedSprite2D  
@onready var orbittimer: Timer
@onready var firetimer: Timer
var Weapon: PackedScene = preload("res://Prefabs/Weapons/EnemyWeapons/SpewlingWeapon.tscn")

var OrbitSpeed = 50
var OrbitDirection = 1
var BulletSpeed = 800

func start():
	OrbitDirection = [-1, 1].pick_random()

	# Orbit timer
	orbittimer = Timer.new()
	orbittimer.wait_time = randf_range(3, 6)
	orbittimer.one_shot = false
	orbittimer.connect("timeout", Callable(self, "orbit_direction_change"))
	orbittimer.autostart = true
	add_child(orbittimer)

	# Fire timer
	firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
	firetimer.autostart = true
	add_child(firetimer)
	
func _ready():
	WeaponScene = Weapon
	super._ready()

func orbit_direction_change():
	OrbitDirection *= -1
	print("ORBIT DIRECTION CHANGE")

func _physics_process(delta):
	var player = resolve_target()
	if player:
		nav.target_position = player.global_position
		if position.distance_to(player.global_position) >= 150:
			var dir = (nav.get_next_path_position() - global_position).normalized()
			velocity = dir * Speed

			# Play crawl animation and flip sprite
			if abs(dir.x) > 0.1:
				sprite.play("crawl")  # Use your crawl/walk animation
				sprite.flip_h = dir.x > 0  # Flip sprite if moving to the left
		else:
			handle_orbiting(player, delta)

	move_and_slide()
	#clamp_position_to_screen()

func fire():
	var player = resolve_target()
	if player and CurrentWeapon:
		var dir = (player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, dir)

func handle_orbiting(player: Node, delta: float):
	var angle = (position - player.position).angle() + OrbitSpeed * OrbitDirection * delta
	var orbit_radius = 300
	var orbit_pos = player.position + Vector2(orbit_radius, 0).rotated(angle)
	velocity = (orbit_pos - position).normalized() * Speed

#func clamp_position_to_screen():
	#var screen_size = get_viewport_rect().size
	#position.x = clamp(position.x, 0, screen_size.x)
	#position.y = clamp(position.y, 0, screen_size.y)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		handle_bounce(body)
	elif is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)
	elif body.is_in_group("Spell"):
		handle_spell_collision()
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await handle_minion_collision(body)

func handle_bounce(body: Node2D):
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

func handle_spell_collision():
	remove_from_group("Enemy")
	add_to_group("Minion")
	get_node("Sprite2D").modulate = Color(0.8, 0.9, 1)
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() > 0:
		Target = enemies[0].get_path()

func handle_minion_collision(body: Node2D):
	await get_tree().process_frame
	if not is_instance_valid(body) or not body.get_parent():
		call_deferred("queue_free")
