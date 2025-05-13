extends Enemy

@onready var sprite := $AnimatedSprite2D  # Ensure this matches your node path!

func start():
	Speed = 140
	Health = 10
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _physics_process(_delta):
	if not nav:
		return

	var player_node = resolve_target()
	if player_node:
		nav.target_position = player_node.global_position
		var dir = nav.get_next_path_position() - global_position

		if dir.length() > 1:
			velocity = dir.normalized() * Speed
			move_and_slide()

			# Play crawl animation and flip
			if abs(dir.x) > 0.1:
				sprite.play("crawl")  # Use your walk/crawl anim name
				sprite.flip_h = dir.x > 0  # Flip if going right
		else:
			velocity = Vector2.ZERO
			sprite.stop()

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
