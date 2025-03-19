extends CharacterBody2D

var Speed = 100
var Enemy = preload("res://Scenes/Misc/enemy_3.tscn")
var xp_scene = preload("res://Scenes/Misc/xp.tscn")
var Group = "Enemy"
var Colour = Color(0, 0.5, 0)
var Target = "Player"

func _ready():
	add_to_group(Group)
	var sprite = get_node("Sprite2D")
	sprite.modulate = Colour
	start_timer()
	
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

func start_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(4, 8)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "spawn")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()
	
func spawn():
	var EnemyInstance = Enemy.instantiate()
	EnemyInstance.name = "Enemy_" + str(randi()) # Assigns a unique named
	EnemyInstance.Colour = Colour
	EnemyInstance.Group = Group
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	get_parent().add_child(EnemyInstance)
	
	start_timer()

func drop_xp():
	var xp = xp_scene.instantiate()
	xp.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	get_parent().add_child(xp)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		for i in range(1):
			drop_xp()
		body.queue_free()
		queue_free()
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		Group = "Minion"
		var sprite = get_node("Sprite2D")
		Colour = Color(0.9, 1, 0.9)
		sprite.modulate = Colour
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			print(Target)
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")
