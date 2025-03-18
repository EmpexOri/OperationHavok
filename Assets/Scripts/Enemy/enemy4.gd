extends CharacterBody2D

var Speed = 120
var Enemy = preload("res://Scenes/Misc/enemy_4.tscn")
var BulletSpeed = 800
var Bullet = preload("res://Scenes/Misc/bullet.tscn")
var xp_scene = preload("res://Scenes/Misc/xp.tscn")

func _ready():
	start_firing_timer()
	
func _physics_process(_delta):
	var Player = get_parent().get_node("Player")
	
	var Direction = (Player.position - position).normalized()
	
	if position.distance_to(Player.position) >= 100:
		velocity = Vector2(0, 0)
	else:
		velocity = Direction * Speed
	
	look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)	

func start_firing_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(3, 5)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "fire")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func fire():
	var Player = get_parent().get_node("Player")
	
	var BulletInstance = Bullet.instantiate()
	BulletInstance.name = "Laser_" + str(randi())  # Assigns a unique named
	BulletInstance.get_node("Sprite2D").modulate = Color(1, 0.5, 0.1)  # Orange color
	BulletInstance.add_to_group("Laser")
	var Direction = (Player.position - position).normalized()
	var OffsetDistance = 30
	BulletInstance.position = position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	BulletInstance.linear_velocity = Direction * BulletSpeed
	get_tree().get_root().call_deferred("add_child", BulletInstance)
	
	start_firing_timer()

func drop_xp() -> void:
	var xp = xp_scene.instantiate()
	xp.global_position = global_position 
	get_parent().add_child(xp)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Bullet"): # Fixed
		drop_xp()
		queue_free()
