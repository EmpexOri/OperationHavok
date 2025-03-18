extends CharacterBody2D

var Speed = 130
var Enemy = preload("res://Scenes/Misc/enemy_2.tscn")
var OrbitSpeed = 50
var OrbitDirection
var BulletSpeed = 800
var Bullet = preload("res://Scenes/Misc/bullet.tscn")
var xp_scene = preload("res://Scenes/Misc/xp.tscn")

func _ready():
	OrbitDirection = [-1, 1].pick_random()
	start_firing_timer()
	
	var timer = Timer.new()
	timer.wait_time = randf_range(3, 6)  # Change direction every 3-6 seconds
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "orbit_direction_change")) # Executes the spawn function once timer has ended
	timer.autostart = true
	add_child(timer)
	
func orbit_direction_change():
	OrbitDirection *= -1
	print("ORBIT DIRECTION CHANGE")
	
func _physics_process(_delta):
	var Player = get_parent().get_node("Player")
	
	var Direction = (Player.position - position).normalized()
	
	if position.distance_to(Player.position) >= 150:
		velocity = Direction * Speed
	else:
		var Angle = (position - Player.position).angle() + OrbitSpeed * OrbitDirection * _delta
		var OrbitRadius = 300  # Keep distance from player
		var OrbitPosition = Player.position + Vector2(OrbitRadius, 0).rotated(Angle)
		
		velocity = (OrbitPosition - position).normalized() * Speed
	
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
	BulletInstance.get_node("Sprite2D").modulate = Color(1, 0, 0)  # Red color
	BulletInstance.add_to_group("Laser")
	var Direction = (Player.position - position).normalized()
	var OffsetDistance = 30
	BulletInstance.position = position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	BulletInstance.linear_velocity = Direction * BulletSpeed
	get_tree().get_root().call_deferred("add_child", BulletInstance)
	
	start_firing_timer()

func drop_xp():
	var xp = xp_scene.instantiate()
	xp.global_position = global_position 
	get_parent().add_child(xp)

func _on_area_2d_body_entered(body: Node2D):
	if body.is_in_group("Bullet"): # Fixed
		drop_xp()
		queue_free()
