extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 140
var Health = 10 * GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["Level"]
#var Enemy = preload("res://Scenes/Misc/enemy.tscn")
var Target = "Player"

func _ready():
	add_to_group("Enemy")
	print(Target)
	
func _process(delta):
	if Health <= 0:
		if not has_dropped_xp:
			drop_xp()
			has_dropped_xp = true
			
			$Area2D/CollisionShape2D.set_deferred("disabled", true)
			
			Global.spawn_meat_chunk(global_position)
			Global.spawn_blood_splatter(global_position)
			Global.spawn_death_particles(global_position) 
			
			# Play a randomised death sound
			GlobalAudioController.HordlingDeath()

			queue_free()

func _physics_process(_delta):
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

func drop_xp():
	var xp_drop_chance := 0.25  # 25% chance to drop XP
	var xp_drop_range := Vector2i(1, 1)  # Drop between 1 and 1 XP pickups
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

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
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
		body.queue_free()
		deal_damage(10)
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
