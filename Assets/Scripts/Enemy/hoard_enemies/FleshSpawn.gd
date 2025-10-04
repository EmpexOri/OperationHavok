extends Enemy

@onready var sprite = $AnimatedSprite2D
var Colour = Color(0, 0.5, 0)

# trail config
@export var max_trail_points := 75
@export var point_spacing := 4.0 
@export var trail_fade_speed := 0.5  
var last_trail_pos: Vector2
var trail_blobs: Array[Sprite2D] = []

func _ready():
	super._ready()
	Speed = 15
	Health = 10
	MaxHealth = Health
	add_to_group("Lesser_Enemy")

	sprite.modulate = Colour

	last_trail_pos = global_position

func deal_damage(damage, from_position = null):
	Health -= damage

func _physics_process(delta):
	super._physics_process(delta)
	update_trail(delta)

	# Enemy movement + animations
	if not nav:
		return

	var player_node = resolve_target()
	if player_node:
		nav.target_position = player_node.global_position
		var dir = nav.get_next_path_position() - global_position

		if dir.length() > 1:
			velocity = dir.normalized() * Speed
			move_and_slide()

			# -------------------------
			# Animation + Flip handling
			# -------------------------
			if dir.y > 0:
				sprite.play("right_down")
			else:
				sprite.play("right_up")

			# Flip horizontally if moving left
			sprite.flip_h = dir.x < 0
		else:
			velocity = Vector2.ZERO
			sprite.stop()

	# Death handling
	if Health <= 0:
		for i in range(1):
			drop_xp()

		$Area2D/CollisionShape2D.set_deferred("disabled", true)

		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position)
		queue_free()

func drop_xp():
	var xp_drop_chance := 0.1
	var xp_drop_range := Vector2i(1, 1)

	if randf() > xp_drop_chance:
		return

	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)
	var screen_size = get_viewport_rect().size

	for i in xp_amount:
		var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))

		var xp_pickup = PickupFactory.build_pickup("Xp", position)
		get_parent().add_child(xp_pickup)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(5)
		
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
		deal_damage(2)

	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		Group = "Minion"
		add_to_group("PlayerSummon")
		SummonGroup = "PlayerSummon"
		Colour = Color(0.9, 1, 0.9)
		$Sprite2D.modulate = Colour
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()

	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")

func get_flash_sprite() -> CanvasItem:
	return sprite 

func update_trail(delta):
	if global_position.distance_to(last_trail_pos) > point_spacing:
		var blob = Sprite2D.new()
		blob.texture = preload("res://Assets/Art/PlaceHolders/SmallGreenSplat.png")
		blob.z_index = -1
		blob.global_position = global_position
		blob.modulate = Colour
		
		var random_angle_deg = 15 * randi_range(1, 24)
		blob.rotation = deg_to_rad(random_angle_deg)
		
		get_parent().add_child(blob)
		trail_blobs.append(blob)
		last_trail_pos = global_position
		
		var tween = get_tree().create_tween()
		tween.tween_property(blob, "modulate:a", 0.0, 7.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(Callable(blob, "queue_free"))
		
	while trail_blobs.size() > max_trail_points:
		var old_blob = trail_blobs.pop_front()
		if is_instance_valid(old_blob):
			old_blob.queue_free()
