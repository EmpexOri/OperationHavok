extends CharacterBody2D

var Speed = 180
#var Enemy = preload("res://Scenes/Misc/enemy.tscn")
var xp_scene = preload("res://Scenes/Misc/xp.tscn")
var Target = "Player"

func _ready():
	add_to_group("Enemy")
	print(Target)
	
func _physics_process(_delta):
	var Player = Target
	if is_in_group("Enemy"):
		Player = get_parent().get_node(Target)
	elif is_in_group("Bullet") and get_tree().get_nodes_in_group("Enemy").size() > 0 and is_instance_valid(Target):
		Player = get_parent().get_node(Target)
	elif is_in_group("Bullet") and get_tree().get_nodes_in_group("Enemy").size() > 0 and not is_instance_valid(Target):
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			Player = get_parent().get_node(Target)
	else:
		Player = get_parent().get_node("Player")
	
	var Direction = (Player.position - position).normalized()
	velocity = Direction * Speed
	
	look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
func drop_xp():
	var xp = xp_scene.instantiate()
	xp.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	get_parent().add_child(xp)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Bullet"): # Fixed
		for i in range(2):
			drop_xp()
		queue_free()
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Bullet")
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(0.8, 0.8, 0.8)
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			print(Target)
	elif is_in_group("Bullet") and body.is_in_group("Enemy"):
		queue_free()
