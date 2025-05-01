extends CharacterBody2D

const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_area: Area2D = $Area2D

var Speed = 50
var Health = 60
var Target = "Player"
var TorpedoVelocity = Vector2.ZERO
var IsTorpedo = false
var LastHitDirection = Vector2.ZERO
var death_frame_counter := 0
var has_spawned_death_effects := false
var has_dropped_xp := false

var explosion_radius = 1.0

# Fuse countdown system
var FuseStarted := false
var FuseCounter := 3  # Number of seconds before explosion
var FuseTickTimer := 0.0
var PlayerInRange := false

# XP drop configuration
var xp_drop_chance := 1.0
var xp_drop_range := Vector2i(1, 3)

func _ready():
	add_to_group("Enemy")
	print(Target)

func _process(delta):
	if Health <= 0:
		if not has_dropped_xp:
			drop_xp()
			has_dropped_xp = true
			torpedo()
		
		death_frame_counter += 1
		if death_frame_counter >= 10:
			Global.spawn_meat_chunk(global_position)
			Global.spawn_blood_splatter(global_position)
			Global.spawn_death_particles(global_position)
			death_frame_counter = 0

		# Start the fuse when health reaches 0, regardless of player proximity
		if not FuseStarted:
			FuseStarted = true
			PlayerInRange = true  # You can keep this if you want, but PlayerInRange won't block the fuse
			print("Fuse started because HP reached 0.")

	if FuseStarted:
		FuseTickTimer += delta
		if FuseTickTimer >= 1.0:
			FuseCounter -= 1
			FuseTickTimer = 0.0
			print("Fuse ticking down: ", FuseCounter)
			if FuseCounter <= 0:
				explode()

func _physics_process(delta):
	var player = null

	if IsTorpedo:
		velocity = TorpedoVelocity
		move_and_slide()
		return

	if is_in_group("Enemy"):
		player = get_parent().get_node(Target)
	elif is_in_group("Minion") and is_instance_valid(Target):
		player = get_parent().get_node(Target)
	elif is_in_group("Minion"):
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			Target = enemies[0].get_path()
			player = get_parent().get_node(Target)
	else:
		player = get_parent().get_node(get_path())

	if player:
		nav.target_position = player.position
		var direction = (nav.get_next_path_position() - global_position).normalized()
		velocity = direction * Speed
		move_and_slide()

	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

	# Handle fuse countdown
	if FuseStarted and PlayerInRange:
		FuseTickTimer += delta
		if FuseTickTimer >= 1.0:
			FuseCounter -= 1
			FuseTickTimer = 0.0
			print("Fuse ticking down: ", FuseCounter)
			if FuseCounter <= 0:
				explode()

func _on_area_2d_body_entered(body: Node2D):
	if IsTorpedo and body and not body.is_in_group("Bullet"):
		explode()
		return

	if is_in_group("Enemy") and body.is_in_group("Player") and not FuseStarted:
		FuseStarted = true
		PlayerInRange = true
	elif is_in_group("Enemy") and body.is_in_group("Player"):
		PlayerInRange = true

	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		deal_damage(10, body.global_position)
		body.queue_free()
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		sprite.modulate = Color(1, 0.7, 0.7)
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			Target = enemies[0].get_path()
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")

func _on_area_2d_body_exited(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		PlayerInRange = false

func explode():
	# Additional visual effects
	Global.spawn_meat_chunk(global_position)
	Global.spawn_blood_splatter(global_position)
	Global.spawn_tumour_particles(global_position)
	Global.spawn_death_particles(global_position)
	print("KABOOM MF")

	var explosion_area = $Area2D
	var collision_shape = explosion_area.get_child(0)

	var shape : Shape2D = null
	if collision_shape is CollisionShape2D:
		shape = collision_shape.shape
		if shape is CircleShape2D:
			explosion_radius = shape.radius * 1.5
		else:
			explosion_radius = 900  # fallback radius, fix @Will

	var space_state = get_world_2d().direct_space_state
	var bodies_in_range = explosion_area.get_overlapping_bodies()
	var already_checked = []

	for body in bodies_in_range:
		if body in already_checked:
			continue
		already_checked.append(body)

		if not body.has_method("deal_damage"):
			continue

		# Use correct explosion radius for the damage check
		if global_position.distance_to(body.global_position) > explosion_radius:
			continue

		var ray_params = PhysicsRayQueryParameters2D.new()
		ray_params.from = global_position
		ray_params.to = body.global_position
		ray_params.exclude = [self]
		ray_params.collision_mask = WALL_COLLISION_MASK

		var result = space_state.intersect_ray(ray_params)
		if result and result.collider != body:
			if result.collider.is_in_group("Enemy"):
				continue
			print("Explosion blocked by: ", result.collider)
			continue

		print("Explosion hits: ", body)
		body.deal_damage(20, global_position)

	queue_free()

func torpedo():
	IsTorpedo = true
	TorpedoVelocity = -LastHitDirection * Speed * 4
	print("Torpedo velocity: ", TorpedoVelocity)

func drop_xp():
	if randf() > xp_drop_chance:
		return

	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)
	var screen_size = get_viewport_rect().size

	for i in xp_amount:
		var pos = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		pos.x = clamp(pos.x, 0, screen_size.x)
		pos.y = clamp(pos.y, 0, screen_size.y)
		var xp_pickup = PickupFactory.build_pickup("Xp", pos)
		get_parent().add_child(xp_pickup)

func deal_damage(damage, from_position = null):
	Health -= damage
	if from_position:
		LastHitDirection = (global_position - from_position).normalized()
		print("LastHitDirection: ", LastHitDirection)
	else:
		print("NO from_position PASSED")
