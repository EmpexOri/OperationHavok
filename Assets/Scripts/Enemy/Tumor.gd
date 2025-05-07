extends Enemy

const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)

@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_area: Area2D = $Area2D

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

func _ready():
	super._ready()  # Runs Enemy's setup: groups, weapon, start()

	# Tumour-specific values
	Health = 60
	Speed = 50
	Group = "Enemy"  # Already default, so dw
	Target = "Player"

func start():
	# Tumour-specific startup logic if any, if u want any in future
	pass

func _process(delta):
	super._process(delta)
	if Health <= 0:
		if not has_dropped_xp:
			has_dropped_xp = true
			torpedo()
		
		death_frame_counter += 1
		if death_frame_counter >= 15:
			Global.spawn_meat_chunk(global_position)
			Global.spawn_blood_splatter(global_position)
			Global.spawn_death_particles(global_position)
			death_frame_counter = 0

		# Start the fuse when health reaches 0, regardless of player proximity
		if not FuseStarted:
			FuseStarted = true
			PlayerInRange = true  # PlayerInRange can be kept to handle player proximity but isn't critical for the fuse
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
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	
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
		var PreExplodeRad = explosion_radius
		if shape is CircleShape2D:
			explosion_radius = shape.radius * 2.0
		else:
			explosion_radius = PreExplodeRad  # fallback radius, fix @Will

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
	
	# Play a randomised death sound
	GlobalAudioController.HordlingDeath()
	Global.spawn_tumour_particles(global_position)
	on_death()
	queue_free()

func torpedo():
	IsTorpedo = true
	TorpedoVelocity = -LastHitDirection * Speed * 4
	print("Torpedo velocity: ", TorpedoVelocity)

func deal_damage(damage, from_position = null):
	Health -= damage
	if from_position:
		LastHitDirection = (global_position - from_position).normalized()
		print("LastHitDirection: ", LastHitDirection)
	else:
		print("NO from_position PASSED")
