extends CharacterBody2D

var Speed = 350
var Enemy = preload("res://Assets/Scripts/Enemy/enemy.gd")

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


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Collided with: ", body.name)
	if "Bullet" in body.name: # Fixed
		print("Bullet hit!")
		queue_free()
