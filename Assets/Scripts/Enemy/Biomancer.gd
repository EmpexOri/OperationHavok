extends Enemy

var FleshSpawn = preload("res://Prefabs/GamePrefabs/Enemy/FleshSpawn.tscn")
var firetimer: Timer

func start():
	Speed = 110
	Health = 20
	WeaponScene = preload("res://Prefabs/CodePrefabs/Weapons/EnemyWeapons/EnemyShotgun.tscn")
	setup_weapon()
	start_timer()
	
	firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)
	firetimer.one_shot = false
	firetimer.autostart = true
	firetimer.connect("timeout", Callable(self, "fire"))
	add_child(firetimer)
	
func _ready():
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

func update_navigation():
	var target_node = resolve_target()
	if not target_node:
		return
	
	var distance = global_position.distance_to(target_node.global_position)
	var dir = (nav.get_next_path_position() - global_position).normalized()
	
	# Custom Biomancer logic to retreat
	if distance < 150:
		velocity = -dir * Speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func start_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(4, 8)
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "spawn"))
	add_child(timer)
	timer.start()

func spawn():
	if get_tree().get_nodes_in_group(SummonGroup).size() < 51:
		var instance = FleshSpawn.instantiate()
		instance.name = "Enemy_" + str(randi())
		instance.Group = Group
		instance.SummonGroup = SummonGroup
		instance.position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		get_parent().add_child(instance)
	start_timer()

func fire():
	var target = resolve_target()
	if target and global_position.distance_to(target.global_position) <= 150:
		if CurrentWeapon:
			var direction = (target.global_position - global_position).normalized()
			CurrentWeapon.attempt_to_fire(global_position, direction)

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
	var sprite = $Sprite2D
	return sprite
