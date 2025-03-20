extends CharacterBody2D

var Speed = 180
var Health = 60
#var Enemy = preload("res://Scenes/Misc/enemy.tscn")
var Target = "Player"

func _ready():
	add_to_group("Enemy")
	print(Target)
	
func _process(delta):
	if Health <= 0:
		for i in range(2):
			drop_xp()
		queue_free()

func _physics_process(_delta):
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
	
	var Direction = (Player.position - position).normalized()
	velocity = Direction * Speed
	
	look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
func drop_xp():
	# Create XP pickup
	var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	var pickup = PickupFactory.build_pickup("Xp", position)
	get_parent().add_child(pickup)
	pickup = null
	
	# Chance for other pickups
	pickup = PickupFactory.try_chance_pickup(position)
	if pickup:
		get_parent().add_child(pickup)

func deal_damage():
	Health -= 20

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")): # Fixed
		body.queue_free()
		deal_damage()
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
