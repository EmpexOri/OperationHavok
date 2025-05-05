extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var sprite = $Sprite2D

var Speed = 100
var Health = 80
var BulletSpeed = 900
var Target = "Player"
var WeaponScene = preload("res://Prefabs/Weapons/EnemyWeapons/enemy_sniper.tscn") 
var CurrentWeapon: Weapon = null

var ShotsFired = 0
var ShotsBeforeMoving = randi_range(1, 3)
var IsMovingRandomly = false

func _ready():
	add_to_group("Enemy")
	CurrentWeapon = WeaponScene.instantiate() # Create new weapon instance
	CurrentWeapon.owning_entity = "Enemy" # Set the owning entity, used to set collisions for projectile
	add_child(CurrentWeapon) # Add our new weapon as a child
	
	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 4) # Fire every 2-4 seconds
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire"))
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
		queue_free()
		
func _physics_process(_delta):
	var target_pos: Vector2
	
	if IsMovingRandomly:
		var player = get_parent().get_node(Target)
		target_pos = nav.target_position
		if global_position.distance_to(player.global_position) <= 100:
			# Cancel random movement and start charging at the player
			IsMovingRandomly = false
		elif nav.is_navigation_finished() or position.distance_to(nav.get_next_path_position()) < 10:
			IsMovingRandomly = false
			velocity = Vector2(0, 0)
	else:
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
	
	if not IsMovingRandomly and (position.distance_to(target_pos) >= 100):
		velocity = Vector2(0, 0)
		sprite.modulate.a = 0.2 # 20% visible
	elif IsMovingRandomly:
		Speed = 60 # Half Speed
		sprite.modulate.a = 0.65 # 65% visible
		velocity = Direction * Speed
	else:
		Speed = 120 # Full Speed
		sprite.modulate.a = 1 # 100% visible
		velocity = Direction * Speed
		
	#look_at(target_pos)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
func fire():
	var Player = get_parent().get_node(Target)
	if IsMovingRandomly or velocity.length() > 1:
		return # Don't fire while moving
	
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
	
	if CurrentWeapon:
		var direction_to_player = (Player.global_position - global_position).normalized()
		CurrentWeapon.attempt_to_fire(global_position, direction_to_player)
		
		ShotsFired += 1
		if ShotsFired >= ShotsBeforeMoving:
			random_move()
			
func random_move():
	IsMovingRandomly = true
	ShotsFired = 0
	ShotsBeforeMoving = randi_range(1, 3)
	
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var target_pos = global_position + offset
	
	var screen_size = get_viewport_rect().size
	target_pos.x = clamp(target_pos.x, 0, screen_size.x)
	target_pos.y = clamp(target_pos.y, 0, screen_size.y)
	
	nav.target_position = target_pos
	
func drop_xp():
	var xp_drop_chance := 0.75  # 75% chance to drop XP
	var xp_drop_range := Vector2i(1, 5)  # Drop between 1 and 5 XP pickups
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
	
func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		var Direction = (position - body.position).normalized()
		var bounce_target = global_position + (Direction * Speed * 0.3) # Move back slightly
		
		var Inbe_tween = get_tree().create_tween()
		Inbe_tween.tween_property(self, "global_position", bounce_target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		await Inbe_tween.finished # Wait for the tween to finish
		return
		
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(1, 1, 0.8)
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			print(Target)
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")
