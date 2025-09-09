extends Enemy

@onready var sprite = $Sprite2D
@onready var buff_area: Area2D = $BuffArea

const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)
const WANDER_CHANGE_INTERVAL = 2.0
const WANDER_SPEED = 40
const AVOID_PLAYER_RADIUS = 256
const WALL_AVOID_DISTANCE = 32
@export var retarget_interval: float = 1.5   # seconds between retargets
var retarget_timer: float = 0.0

@export var orbit_radius: float = 48.0      # how far to stay from target
@export var orbit_speed: float = 40.0       # speed of orbiting
@export var orbit_direction: int = 1        # 1 = clockwise, -1 = counter-clockwise

var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

func _ready():
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()
	
	Speed = 50
	Health = 150
	MaxHealth = Health
	Group = "Enemy"
	add_to_group("Support")
	Target = null

func start():
	pass

func _process(delta):
	super._process(delta)

	if Health <= 0:
		Global.spawn_death_particles(global_position)
		queue_free()

func _physics_process(delta):
	# Buff logic unchanged
	for body in buff_area.get_overlapping_bodies():
		if body.is_in_group("Enemy") and not body.is_in_group("Support") and body.has_method("apply_buff"):
			check_and_buff(body)

	# Update retarget timer
	retarget_timer -= delta

	# Only try to find a new target if timer is ready
	if (not is_instance_valid(Target) or Target.is_in_group("Buffed")) and retarget_timer <= 0.0:
		find_cluster_target()
		retarget_timer = retarget_interval

	if Target:
		var to_target = Target.global_position - global_position
		var distance = to_target.length()

		# --- ORBIT LOGIC (Kind brokie but works for my reasons) ---
		if distance <= orbit_radius * 1.5:
			# Compute orbit point around target
			var angle = atan2(to_target.y, to_target.x)
			angle += orbit_direction * 0.5   # adjust step size (radians per update)
			
			var orbit_point = Target.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius
			nav.target_position = orbit_point
		else:
			# Otherwise move straight toward the target
			nav.target_position = Target.global_position

		var direction = (nav.get_next_path_position() - global_position).normalized()
		velocity = direction * Speed
		move_and_slide()
		update_animation(direction)

func handle_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0 or is_heading_into_wall():
		wander_timer = WANDER_CHANGE_INTERVAL
		choose_new_wander_direction()

	velocity = wander_direction * WANDER_SPEED
	move_and_slide()

func choose_new_wander_direction():
	# Base random direction
	wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	# Run away from player if nearby
	var player = get_tree().get_first_node_in_group("Player")
	if player and global_position.distance_to(player.global_position) < AVOID_PLAYER_RADIUS:
		var away = (global_position - player.global_position).normalized()
		# Blend random wander with "away from player"
		wander_direction = (wander_direction + away).normalized()

func is_heading_into_wall() -> bool:
	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(global_position, global_position + wander_direction * WALL_AVOID_DISTANCE)
	ray_params.exclude = [self]
	ray_params.collision_mask = WALL_COLLISION_MASK
	var result = space_state.intersect_ray(ray_params)
	return result != null

func find_cluster_target():
	# Keep existing target if still valid
	if is_instance_valid(Target) and not Target.is_in_group("Buffed"):
		return

	var enemies = get_tree().get_nodes_in_group("Enemy")
	enemies = enemies.filter(
		func(enemy): return enemy != self and not enemy.is_in_group("Buffed") and not enemy.is_in_group("Support")
	)

	if enemies.is_empty():
		Target = null
		return

	var best_target = null
	var best_count = -1
	var best_distance = INF
	var CLUSTER_RADIUS = 128

	for enemy in enemies:
		var path := NavigationServer2D.map_get_path(
			nav.get_navigation_map(),   # use this agent’s navmap
			global_position,
			enemy.global_position,
			false   # optimize = false (cheaper, still fine for checks)
		)

		if path.size() < 2:
			continue # No path, skip this enemy

		var count = 0
		for other in enemies:
			if enemy == other:
				continue
			if enemy.global_position.distance_squared_to(other.global_position) < CLUSTER_RADIUS * CLUSTER_RADIUS:
				count += 1

		# 🔍 Step 3: Pick the “best” target (cluster size > distance)
		var distance = global_position.distance_squared_to(enemy.global_position)
		if count > best_count or (count == best_count and distance < best_distance):
			best_target = enemy
			best_count = count
			best_distance = distance

	Target = best_target

func check_and_buff(target):
	if not is_instance_valid(target):
		return

	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	ray_params.exclude = [self]
	ray_params.collision_mask = WALL_COLLISION_MASK

	var result = space_state.intersect_ray(ray_params)
	if result and result.collider != target:
		return  # Blocked by wall or object

	# Refresh buff duration each frame
	if target.has_method("apply_buff"):
		#print("Refreshing buff on:", target.name)
		target.apply_buff()

func deal_damage(damage, from_position = null):
	flash_white()
	Health -= damage
	if Health <= 0:
		on_death()

func get_flash_sprite() -> CanvasItem:
	return sprite

# Not used anymore, buffing handled in _physics_process
func _on_buff_area_body_entered(body: Node2D) -> void:
	pass

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		sprite.play("idle")
		return

	# Check vertical tilt
	if direction.y < -0.2:  # moving upward
		sprite.play("move_up_left")
		sprite.flip_h = direction.x > 0
	elif direction.y > 0.2: # moving downward
		sprite.play("move_down_left")
		sprite.flip_h = direction.x > 0
	else:
		# If mostly horizontal, just pick one
		sprite.play("move_down_left")
		sprite.flip_h = direction.x > 0
