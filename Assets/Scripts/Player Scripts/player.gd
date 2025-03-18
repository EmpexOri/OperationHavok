extends CharacterBody2D

var MoveSpeed = 250
var BulletSpeed = 1500
var Bullet = preload("res://Scenes/Misc/bullet.tscn")
var Class = preload("res://Assets/Scripts/Player Scripts/Technomancer.gd").new()
var Mode = "fire"
var Trigger_Timer = Timer.new()

func _ready():
	add_to_group("player")
	trigger()
	
func trigger():
	Trigger_Timer = Timer.new()
	Trigger_Timer.wait_time = 0.25
	Trigger_Timer.one_shot = false  # Timer only goes once
	Trigger_Timer.connect("timeout", Callable(self, Mode)) # Executes the spawn function once timer has ended
	add_child(Trigger_Timer)
	Trigger_Timer.start()
	
func _physics_process(_delta):
	var Motion = Vector2()
	
	if Input.is_action_pressed("up"):
		Motion.y -= 1
	if Input.is_action_pressed("down"):
		Motion.y += 1
	if Input.is_action_pressed("left"):
		Motion.x -= 1
	if Input.is_action_pressed("right"):
		Motion.x += 1
	
	Motion = Motion.normalized() * MoveSpeed
	velocity = Motion
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("LMB"):
		if Mode == "fire":
			Class.brainwash(self)
			Mode = "ability"
		elif Mode == "ability":
			fire()
			Mode = "fire"
			
		Trigger_Timer.stop()
		trigger()
		
func ability():
	Class.brainwash(self)
	
func fire():
	var BulletInstance = Bullet.instantiate()
	BulletInstance.name = "Bullet_" + str(randi())  # Assigns a unique named
	BulletInstance.add_to_group("Bullet")
	var Direction = (get_global_mouse_position() - global_position).normalized()
	var OffsetDistance = 30
	BulletInstance.position = global_position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	BulletInstance.linear_velocity = Direction * BulletSpeed
	get_tree().get_root().call_deferred("add_child", BulletInstance)
	
func kill():
	get_tree().reload_current_scene()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("Laser"):
		kill()
