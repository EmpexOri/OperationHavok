extends Node2D

#var MoveSpeed = 250
#var BulletSpeed = 1500
var Bullet = preload("res://Scenes/Misc/bullet.tscn")

func ability(Player: Node2D):
	var BulletInstance = Bullet.instantiate()
	BulletInstance.name = "Spell_" + str(randi())  # Assigns a unique name
	BulletInstance.get_node("Sprite2D").modulate = Color(0, 0, 0)  # Black color
	BulletInstance.add_to_group("Spell")
	var Direction = (Player.get_global_mouse_position() - Player.global_position).normalized()
	var OffsetDistance = 30
	BulletInstance.position = Player.global_position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	#BulletInstance.linear_velocity = Direction * BulletSpeed
	Player.get_tree().get_root().call_deferred("add_child", BulletInstance)
