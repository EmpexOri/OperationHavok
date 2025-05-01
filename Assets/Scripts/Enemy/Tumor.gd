extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 175
var Health = 60
var Target = "Player"
var FuseTimer = Timer.new()
var TorpedoVelocity = Vector2(0,0)
var IsTorpedo = false
var LastHitDirection = Vector2(0,0)

var death_frame_counter := 0
var has_spawned_death_effects := false

var FuseStarted := false

#Efficency Improvements
@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_area: Area2D = $Area2D

func _ready():
	add_to_group("Enemy")
	print(Target)
	
	FuseTimer.wait_time = 3
	FuseTimer.one_shot = true  # Timer only goes once
	FuseTimer.connect("timeout", Callable(self, "explode")) # Executes the spawn function once timer has ended
	add_child(FuseTimer)
	
var death_effect_frame_counter := 0

func _process(delta):
	if Health <= 0:
		if not has_dropped_xp:
			drop_xp()
			has_dropped_xp = true
			torpedo()

		death_effect_frame_counter += 1
		if death_effect_frame_counter >= 10:
			Global.spawn_meat_chunk(global_position)
			Global.spawn_blood_splatter(global_position)
			Global.spawn_death_particles(global_position)
			death_effect_frame_counter = 0  # Reset to repeat every 10 frames

func _physics_process(_delta):
	var Player
	
	if IsTorpedo:
		velocity = TorpedoVelocity
		move_and_slide()
		return
	
	if is_in_group("Enemy"):
		Player = get_parent().get_node(Target)
	elif is_in_group("Minion") and get_tree().get_nodes_in_group("Enemy").size() > 0 and is_instance_valid(Target):
		Player = get_parent().get_node(Target)
	elif is_in_group("Minion") and get_tree().get_nodes_in_group("Enemy").size() > 0 and not is_instance_valid(Target):
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			Player = get_parent().get_node(Target)
	else:
		Player = get_parent().get_node(self.get_path())
	
	nav.target_position = Player.position
	#Direction = (Player.position - position).normalized()
	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()
	#velocity = Direction * Speed
	velocity = Direction * Speed
	
	#look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
var has_dropped_xp := false

# Configurable values (can be set per-enemy or globally)
var xp_drop_chance := 1.0  # 100% chance to drop XP
var xp_drop_range := Vector2i(1, 3)  # Drop between 1 and 3 XP pickups

#func explode():
	#print("KABOOM MF")
	#
	#var explosion_area = $Area2D
	#var collision_shape = explosion_area.get_child(0)  # Get CollisionShape2D
	#
	## Double the radius of the collision shape (aka the area)
	#if collision_shape is CollisionShape2D:
		#var shape = collision_shape.shape
		#if shape is CircleShape2D:
			#shape.radius *= 1.2  # Double it and give it to the next enemy
			#
	## Get all the entities within the range
	#var bodies_in_range = explosion_area.get_overlapping_bodies()
	#
	## Loop through all bodies and deal damage if they have the "deal_damage" method
	#for body in bodies_in_range:
		#if body.has_method("deal_damage"):
			#body.deal_damage(20, global_position)
			#
	#Global.spawn_meat_chunk(global_position)
	#Global.spawn_blood_splatter(global_position)
	#Global.spawn_death_particles(global_position)
	#
	#queue_free()
	
const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)	

func explode():
	Global.spawn_tumour_particles(global_position) 
	print("KABOOM MF")
	
	var explosion_area = $Area2D
	var collision_shape = explosion_area.get_child(0)
	
	var shape : Shape2D = null  # Declare shape outside the if block
	
	if collision_shape is CollisionShape2D:
		shape = collision_shape.shape
		if shape is CircleShape2D:
			shape.radius *= 1.5
			
	var space_state = get_world_2d().direct_space_state
	var bodies_in_range = explosion_area.get_overlapping_bodies()
	var already_checked = []
	
	for body in bodies_in_range:
		if body in already_checked:
			continue
		already_checked.append(body)
		
		if not body.has_method("deal_damage"):
			continue
			
		if global_position.distance_to(body.global_position) > shape.radius:
			continue
			
		# Create PhysicsRayQueryParameters2D to use with intersect_ray
		var ray_params = PhysicsRayQueryParameters2D.new()
		ray_params.from = global_position
		ray_params.to = body.global_position
		ray_params.exclude = [self]  # Exclude the object from the raycast
		ray_params.collision_mask = WALL_COLLISION_MASK
		
		# Perform the raycast using the PhysicsRayQueryParameters2D
		var result = space_state.intersect_ray(ray_params)
		
		if result and result.collider != body:
			# Check if the result is an enemy or a wall
				if result.collider.is_in_group("Enemy"):
					# If the result is an enemy, ignore it as a blocker
					continue
				print("Explosion blocked by: ", result.collider)
				continue
			
		print("Explosion hits: ", body)
		body.deal_damage(20, global_position)
		
	Global.spawn_meat_chunk(global_position)
	Global.spawn_blood_splatter(global_position)
	Global.spawn_death_particles(global_position)
	
	queue_free()
	
func torpedo():
	IsTorpedo = true
	TorpedoVelocity = -LastHitDirection * Speed * 2
	FuseTimer.start()
	print("Torpedo velocity: ", TorpedoVelocity)

func drop_xp():
	var xp_drop_chance := 1.0  # 10% chance to drop XP
	var xp_drop_range := Vector2i(1, 3)  # Drop between 1 and 3 XP pickups
	# Check if XP should drop at all, we might not want all enemies to drop it
	if randf() > xp_drop_chance:
		return

	# Determine how many XP pickups to drop, using above var's
	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)
	var screen_size = get_viewport_rect().size

	for i in xp_amount:
		var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)

		var xp_pickup = PickupFactory.build_pickup("Xp", position)
		get_parent().add_child(xp_pickup)

	# Optional: drop a bonus pickup. Disabled for now per Game Design
#	var extra_pickup = PickupFactory.try_chance_pickup(global_position)
#	if extra_pickup:
#		get_parent().add_child(extra_pickup)

func deal_damage(damage, from_position = null):
	Health -= damage
	if from_position:
		LastHitDirection = (global_position - from_position).normalized()
		print("LastHitDirection: ", LastHitDirection)
	else:
		print("NO from_position PASSED")
			
func _on_area_2d_body_entered(body: Node2D):
	if IsTorpedo and body and not body.is_in_group("Bullet"):
		print(body)
		explode()
		return
	
	if is_in_group("Enemy") and body.is_in_group("Player") and not FuseStarted:
		FuseStarted = true
		FuseTimer.start()
	else:
		print("Lets do something else")
		
	if is_in_group("") and body.is_in_group(""):
		body.deal_damage(2)
		# Calculate bounce direction (opposite of movement)
		var Direction = (position - body.position).normalized()
		var Bounce_Target = global_position + (Direction * Speed * 0.3)  # Move back slightly
		var Screen_Size = get_viewport_rect().size
		Bounce_Target.x = clamp(Bounce_Target.x, 0, Screen_Size.x)
		Bounce_Target.y = clamp(Bounce_Target.y, 0, Screen_Size.y)
		
		# Use Tween for smooth movement
		var Inbe_tween = get_tree().create_tween()
		Inbe_tween.tween_property(self, "global_position", Bounce_Target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		await Inbe_tween.finished  # Wait for the tween to finish
		return
		
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")): # Fixed
		deal_damage(10, body.global_position)
		body.queue_free()
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(1, 0.7, 0.7)
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			print(Target)
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")
