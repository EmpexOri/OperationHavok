extends Enemy

@onready var sprite := $AnimatedSprite2D 

func start():
	if not Speed or Speed == 100:
		Speed = 150
	Health = 20
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	super()
	add_to_group("Hordling")
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	else:
		var new_mat = ShaderMaterial.new()
		sprite.material = new_mat
	
	# Initialize animation direction
	if is_instance_valid(cached_player):
		var initial_dir = (cached_player.global_position - global_position).normalized()
		smooth_dir = initial_dir
		last_anim_dir = initial_dir

func _physics_process(_delta):
	if not nav or not is_instance_valid(cached_player):
		return

	# --- Base navigation toward player ---
	nav.target_position = cached_player.global_position
	var dir = (nav.get_next_path_position() - global_position).normalized()

	# --- Avoidance: prevent overlapping other enemies (best for our nav system) ---
	var avoidance_offset := Vector2.ZERO
	var nearby_allies := get_tree().get_nodes_in_group("Enemy")
	for enemy in nearby_allies:
		if enemy == self:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 24:
			avoidance_offset += (global_position - enemy.global_position).normalized() * (1.0 - dist / 24)

	# --- Grouping: move slightly toward center of nearby allies ---
	var group_offset := Vector2.ZERO
	var count := 0
	for other_enemy in nearby_allies:
		if other_enemy == self:
			continue
		# Only consider same kind ("Hordling") or same class group
		for hordling in get_tree().get_nodes_in_group("Hordling"):
			if hordling == self:
				continue
			var dist = global_position.distance_to(hordling.global_position)
			if dist < 100:  # perception radius
				group_offset += hordling.global_position
				count += 1

	if count > 0:
		group_offset = (group_offset / count - global_position).normalized()
		dir = (dir + group_offset * 0.3).normalized()  # weight toward group center (Yay AI for Games)

	if avoidance_offset != Vector2.ZERO:
		dir = (dir + avoidance_offset.normalized() * 0.5).normalized()

	# --- Smooth velocity ---
	velocity = velocity.lerp(dir * Speed, 0.2)
	move_and_slide()
	
	# --- Smooth direction for animation/flip ---
	smooth_dir = smooth_dir.lerp(velocity, 0.1)
	
	if smooth_dir.length() > 0.1:
		if last_anim_dir == Vector2.ZERO or abs(last_anim_dir.angle_to(smooth_dir)) > FLIP_THRESHOLD:
			last_anim_dir = smooth_dir.normalized()
			
			if abs(smooth_dir.y) > abs(smooth_dir.x):
				if smooth_dir.y > 0:
					sprite.play("right_down")
				else:
					sprite.play("right_up")
			else:
				sprite.play("right_down")
			sprite.flip_h = smooth_dir.x < 0
	else:
		sprite.stop()

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(8)
		
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

	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")

		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(1, 0.7, 0.7)

		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			Target = enemies[0].get_path()

	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")

func drop_xp():
	var xp_drop_chance := 0.4
	var xp_drop_range := Vector2i(1, 2)

	if randf() > xp_drop_chance:
		return

	var screen_size = get_viewport_rect().size
	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)

	for i in xp_amount:
		var pos = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))

		var xp_pickup = PickupFactory.build_pickup("Xp", pos)
		get_parent().add_child(xp_pickup)

func get_flash_sprite() -> CanvasItem:
	return sprite  # or $AnimatedSprite2D depending on the node used
