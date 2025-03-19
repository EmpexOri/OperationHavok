extends CharacterBody2D

var Bullet = preload("res://Scenes/Misc/bullet.tscn")
var Class = preload("res://Assets/Scripts/Player Scripts/Technomancer.gd").new()
#var Mode = "fire"
var Trigger_Timer = Timer.new()
var Damage_Timer = Timer.new()

# Remove MoveSpeed and BulletSpeed as hardcoded variables
var MoveSpeed = 0
var BulletSpeed = 0

func _ready():
	add_to_group("Player")
	trigger()
	damage_timer()
	
	# Retrieve the class-specific MoveSpeed and BulletSpeed from Global
	MoveSpeed = Global.ClassData[Global.CurrentClass]["MoveSpeed"]
	BulletSpeed = Global.ClassData[Global.CurrentClass]["BulletSpeed"]
	
func trigger():
	Trigger_Timer = Timer.new()
	Trigger_Timer.wait_time = 0.25
	Trigger_Timer.one_shot = false
	Trigger_Timer.connect("timeout", Callable(self, "fire")) # Executes the spawn function once timer has ended
	add_child(Trigger_Timer)
	Trigger_Timer.start()
	
func damage_timer():
	Damage_Timer = Timer.new()
	Damage_Timer.wait_time = 1
	Damage_Timer.one_shot = false
	Damage_Timer.connect("timeout", Callable(self, "deal_damage"))
	add_child(Damage_Timer)
	
func _process(delta):
	if Global.PlayerHP <= 0:
		print("DEAD")
		Global.PlayerHP = Global.PlayerHPMax
		kill()
	
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

func _input(event):
	if Input.is_action_just_pressed("LMB"):
		Trigger_Timer.stop()
		Class.ability(self)
		await get_tree().create_timer(3).timeout
		#Mode = "ability"
		Trigger_Timer.start()
		
#func ability():
	#Class.ability(self)
	
func fire():
	var BulletInstance = Bullet.instantiate()
	BulletInstance.name = "Bullet_" + str(randi())  # Assigns a unique name
	BulletInstance.add_to_group("Bullet")
	var Direction = (get_global_mouse_position() - global_position).normalized()
	var OffsetDistance = 12 # How far away the bullet spawns from the player
	BulletInstance.position = global_position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	BulletInstance.linear_velocity = Direction * BulletSpeed
	get_tree().get_root().call_deferred("add_child", BulletInstance)
	
func deal_damage():
	Global.PlayerHP -= 10
	
func kill():
	get_tree().reload_current_scene()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") or body.is_in_group("Laser"):
		Global.PlayerHP -= 10
		Damage_Timer.start()

func _on_area_2d_body_exited(body: Node2D) -> void:
	Damage_Timer.stop()
