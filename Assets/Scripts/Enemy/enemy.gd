extends CharacterBody2D

var Speed = 180
var Enemy = preload("res://Assets/Scripts/Enemy/enemy.gd")
var xp_scene = preload("res://Scenes/Misc/xp.tscn")

func _ready():
	pass
	
func _physics_process(_delta):
	var Player = get_parent().get_node("Player")
	
	var Direction = (Player.position - position).normalized()
	velocity = Direction * Speed
	
	look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
func drop_xp() -> void:
	var xp = xp_scene.instantiate()
	xp.global_position = global_position 
	get_parent().add_child(xp)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Collided with: ", body.name)
	if "Bullet" in body.name: # Fixed
		print("Bullet hit!")
		drop_xp()
		queue_free()
