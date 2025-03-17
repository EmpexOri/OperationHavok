extends CharacterBody2D

var Speed = 175
var Enemy = preload("res://Assets/Scripts/Enemy/enemy3.gd")

func _ready():
	start_timer()
	
func _physics_process(_delta):
	var Player = get_parent().get_node("Player")
	
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
	var viewport = get_viewport_rect().size
	var random_x = randf_range(0, viewport.x)  # Random X position
	var random_y = randf_range(0, viewport.y)  # Random Y position
	EnemyInstance.position = Vector2(randf_range(100, random_x), randf_range(100, random_y))
	get_parent().add_child(EnemyInstance)
	
	start_timer()
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Collided with: ", body.name)
	if "Bullet" in body.name: # Fixed
		print("Bullet hit!")
		queue_free()
