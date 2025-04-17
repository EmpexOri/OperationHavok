# TODO: GIVE THIS CLASS MORE FEATURES FOR IT TO FEEL LIKE AN ACTUAL ROUGH CLONE OF THE TECHNOMANCER
extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 170
var Health = 20
var FleshSpawn = preload("res://Prefabs/Enemy/FleshSpawn.tscn")
var Group = "Enemy"
var SummonGroup = "EnemySummon"
var Target = "Player"

func _ready():
	add_to_group(Group)
	add_to_group(SummonGroup)
	var sprite = get_node("Sprite2D")
	start_timer()
	
func _process(delta):
	if Health <= 0:
		for i in range(1):
			drop_xp()
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
	# Create XP pickup
	var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	var Screen_Size = get_viewport_rect().size
	position.x = clamp(position.x, 0, Screen_Size.x)
	position.y = clamp(position.y, 0, Screen_Size.y)
	var pickup = PickupFactory.build_pickup("Xp", position)
	get_parent().add_child(pickup)
	pickup = null
	
	# Chance for other pickups
	pickup = PickupFactory.try_chance_pickup(position)
	if pickup:
		get_parent().add_child(pickup)

func deal_damage(damage):
	Health -= damage

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		# Calculate bounce direction (opposite of movement)
		var Direction = (position - body.position).normalized()
		var bounce_target = global_position + (Direction * Speed * 0.3)  # Move back slightly
		
		# Use Tween for smooth movement
		var Inbe_tween = get_tree().create_tween()
		Inbe_tween.tween_property(self, "global_position", bounce_target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
