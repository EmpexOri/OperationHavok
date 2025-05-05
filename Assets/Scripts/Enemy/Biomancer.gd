# TODO: GIVE THIS CLASS MORE FEATURES FOR IT TO FEEL LIKE AN ACTUAL ROUGH CLONE OF THE TECHNOMANCER
extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 110
var Health = 20
var FleshSpawn = preload("res://Prefabs/Enemy/FleshSpawn.tscn")
var Group = "Enemy"
var SummonGroup = "EnemySummon"
var Target = "Player"

var WeaponScene = preload("res://Prefabs/Weapons/EnemyWeapons/EnemyShotgun.tscn") 
var CurrentWeapon: Weapon = null

func _ready():
	add_to_group(Group)
	add_to_group(SummonGroup)
	var sprite = get_node("Sprite2D")
	start_timer()
	
	#Shooting
	CurrentWeapon = WeaponScene.instantiate() # Create new weapon instance
	CurrentWeapon.owning_entity = "Enemy" # Set the owning entity, used to set collisions for projectile
	add_child(CurrentWeapon) # Add our new weapon as a child
	
	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)  # Fire every 2-3 seconds
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire")) # Executes the spawn function once timer has ended
	firetimer.autostart = true
	add_child(firetimer)
	
func _process(delta):
	if Health <= 0:
		for i in range(1):
			drop_xp()
			
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
			
		Global.spawn_meat_chunk(global_position)
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position) 	
		
		# Play sound on death
		GlobalAudioController.BiomancerDeath()
		queue_free()
	
func _physics_process(_delta):
	var target_pos: Vector2
	var Player
	
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
		
	target_pos = Player.position
	nav.target_position = target_pos
	
	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()
	
	# TODO: FIGURE OUT A BETTER WAY FOR THE BIOMANCER TO RUN AWAY
	if position.distance_to(target_pos) >= 150:
		velocity = Vector2(0, 0)
	else:
		velocity = -Direction * Speed
		
	#look_at(target_pos)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func start_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(4, 8)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()
	
func spawn():
	if get_tree().get_nodes_in_group(SummonGroup).size() < 51: # Can only use it's ability if there is less than the specified amount
		var EnemyInstance = FleshSpawn.instantiate()
		EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
		EnemyInstance.Group = Group
		EnemyInstance.SummonGroup = SummonGroup
		var viewport = get_viewport_rect().size
		var random_x = randf_range((position.x - 50), (position.x + 50))  # Random X position
		var random_y = randf_range((position.y - 50), (position.y + 50))  # Random Y position
		EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
		get_parent().add_child(EnemyInstance)
	
	start_timer()

func drop_xp():
	var xp_drop_chance := 1.0  # 100% chance to drop XP
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

func deal_damage(damage, from_position = null):
	Health -= damage
	#pass

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		# Calculate bounce direction (opposite of movement)
		var Direction = (position - body.position).normalized()
		var bounce_target = global_position + (Direction * Speed * 0.3)  # Move back slightly
		
		# Use Tween for smooth movement
		var Inbe_tween = get_tree().create_tween()
		Inbe_tween.tween_property(self, "global_position", bounce_target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		await Inbe_tween.finished  # Wait for the tween to finish
		return
		
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		Group = "Minion"
		add_to_group("PlayerSummon")
		SummonGroup = "PlayerSummon"
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(0.9, 1, 0.9)
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			print(Target)
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")
			
func fire():
	var Player = get_parent().get_node(Target)
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
		return
	
	# Only fire if player is within 1.5 meters (150 pixels)
	if global_position.distance_to(Player.global_position) <= 50:
		print("Player In Range")
		if CurrentWeapon:
			var direction_to_player = (Player.global_position - global_position).normalized()
			CurrentWeapon.attempt_to_fire(global_position, direction_to_player)
