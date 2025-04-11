extends Node2D

@export var Bullet = preload("res://Scenes/Projectiles/bullet.tscn")  # Ensure Bullet scene is linked
@export var FireDuration := 3.0  # Duration of beam in seconds
@export var BulletsPerSecond := 10  # Number of bullets fired per second
@export var BulletSpeed := 200  # Speed of the bullet
@export var RotationOffset := 90  # Adjust to fit rotation as needed
@export var OwnerName := "Player"  # Set the owner of the bullets (e.g., "Player")

var _player_ref

func activate(player: Node2D):
	if not player:
		print("Player is null, aborting activate.")
		return
	
	_player_ref = player
	global_position = player.global_position
	rotation = player.rotation
	
	fire_beam(player)

func fire_beam(Player: Node2D):
	if not Player:
		return
		
	for i in range(20):
		if not Player:
			return
			
		var angle = (i / float(20)) * TAU  # TAU = "2 * PI" (aka a full circle)
		var Direction = Vector2(cos(angle), sin(angle))  # Convert angle to direction vector
		
		var BulletInstance = Bullet.instantiate()
		BulletInstance.name = "Spell_" + str(randi())  # Assigns a unique name
		BulletInstance.get_node("Sprite2D").modulate = Color(0, 0, 0)  # Black color
		BulletInstance.add_to_group("Spell")
		
		BulletInstance.collision_layer = 3  # Player projectile layer
		BulletInstance.collision_mask = 2  # Only collides with enemies
		
		var OffsetDistance = 12
		var position = Player.global_position + (Direction * OffsetDistance)
		rotation = angle + 90
		BulletInstance.start(position, Direction, "Player")
		
		Player.get_tree().get_root().call_deferred("add_child", BulletInstance)
