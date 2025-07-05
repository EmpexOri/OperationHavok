extends Enemy

@onready var sprite = $Sprite2D
@onready var buff_area: Area2D = $BuffArea

const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)

func _ready():
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()
	
	Speed = 50
	Health = 60
	Group = "Enemy" # having trouble here
	add_to_group("Support") # band aid solution for the time
	Target = null

func start():
	pass

func _process(delta):
	super._process(delta)

	if Health <= 0:
		Global.spawn_death_particles(global_position)
		queue_free()

func _physics_process(delta):
	
	# Print bodies currently overlapping the buff_area
	for body in buff_area.get_overlapping_bodies():
		print("Overlapping body:", body.name)
	
	# Don't find a new target if the current one is still valid
	if not is_instance_valid(Target) or Target.is_in_group("Buffed"):
		find_cluster_target()

	if Target:
		nav.target_position = Target.global_position
		var direction = (nav.get_next_path_position() - global_position).normalized()
		velocity = direction * Speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func find_cluster_target():
	var enemies = get_tree().get_nodes_in_group("Enemy")
	enemies = enemies.filter(func(enemy): return enemy != self and not enemy.is_in_group("Buffed") and not enemy.is_in_group("Support"))

	if enemies.size() == 0:
		Target = null
		return

	var best_target = null
	var best_count = -1
	var best_distance = INF
	var CLUSTER_RADIUS = 128

	for enemy in enemies:
		var count = 0
		for other in enemies:
			if enemy == other:
				continue
			if enemy.global_position.distance_squared_to(other.global_position) < CLUSTER_RADIUS * CLUSTER_RADIUS:
				count += 1

		var distance = global_position.distance_squared_to(enemy.global_position)
		if count > best_count or (count == best_count and distance < best_distance):
			best_target = enemy
			best_count = count
			best_distance = distance

	Target = best_target

func check_and_buff(target):
	if not is_instance_valid(target) or target.is_in_group("Buffed"):
		return

	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	ray_params.exclude = [self]
	ray_params.collision_mask = WALL_COLLISION_MASK

	var result = space_state.intersect_ray(ray_params)
	if result and result.collider != target:
		return  # Blocked by wall or object

	if target.has_method("apply_buff"):
		print("Buffing target via check:", target.name)
		target.apply_buff()

func deal_damage(damage, from_position = null):
	flash_white()
	Health -= damage
	if Health <= 0:
		on_death()

func get_flash_sprite() -> CanvasItem:
	return sprite


func _on_buff_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and not body.is_in_group("Buffed") and body.has_method("apply_buff") and not body.is_in_group("Support"):
		print("Entered buff area:", body)
		var ray_params = PhysicsRayQueryParameters2D.create(global_position, body.global_position)
		ray_params.exclude = [self]
		ray_params.collision_mask = WALL_COLLISION_MASK

		var result = get_world_2d().direct_space_state.intersect_ray(ray_params)
		if result and result.collider != body:
			return  # Blocked

		print("Buffing target via area:", body.name)
		check_and_buff(body)
