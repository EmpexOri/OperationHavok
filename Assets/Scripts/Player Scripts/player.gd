extends CharacterBody2D

var MoveSpeed = 500
var BulletSpeed = 2000
var Bullet = preload("res://Assets/Scripts/Player Scripts/bullet.gd")

func _ready():
	pass
	
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
		fire()
	
func fire():
	var BulletInstance = Bullet.instantiate()
	BulletInstance.name = "Bullet_" + str(randi())  # Assigns a unique named
	print(BulletInstance.name)
	var Direction = (get_global_mouse_position() - global_position).normalized()
	var OffsetDistance = 30
	BulletInstance.position = global_position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	BulletInstance.linear_velocity = Direction * BulletSpeed
	get_tree().get_root().call_deferred("add_child", BulletInstance)
	
func kill():
	get_tree().reload_current_scene()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if "Enemy" in body.name or "Laser" in body.name:
		kill()
