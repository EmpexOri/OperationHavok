extends Node2D

#var MoveSpeed = 250
var BulletSpeed = 100
var Bullet = preload("res://Scenes/Projectiles/bullet.tscn")
var BurstAmount = 3
var CooldownTimer: float = 3
var Enabled = true

func ability(Player: Node2D):
	if not Player:
		return
		
	if not Enabled:
		return
	else:
		Enabled = false
		
		Player.velocity = Vector2.ZERO  # Stops movement completely
		Player.set_physics_process(false)  # Temporarily disable movement
		
		for i in range(BurstAmount):
			if not Player:
				return
			burst_fire(Player)
			await Player.get_tree().create_timer(1).timeout  # Wait between shots
		
		if not Player:
			return

		Player.set_physics_process(true)  # Re-enable movement
		
		await Player.get_tree().create_timer(CooldownTimer).timeout  # Cooldown delay
		Enabled = true  # Enable shooting again
	
#func burst_fire(Player: Node2D):
	#var BulletInstance = Bullet.instantiate()
	#BulletInstance.name = "Spell_" + str(randi())  # Assigns a unique name
	#BulletInstance.get_node("Sprite2D").modulate = Color(0, 0, 0)  # Black color
	#BulletInstance.add_to_group("Spell")
	#var Direction = (Player.get_global_mouse_position() - Player.global_position).normalized()
	#var OffsetDistance = 12
	#BulletInstance.position = Player.global_position + (Direction * OffsetDistance)
	#BulletInstance.rotation = Direction.angle()
	#BulletInstance.linear_velocity = Direction * BulletSpeed
	#Player.get_tree().get_root().call_deferred("add_child", BulletInstance)
	
func burst_fire(Player: Node2D):
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
		BulletInstance.position = Player.global_position + (Direction * OffsetDistance)
		BulletInstance.rotation = angle + 90
<<<<<<< HEAD
		BulletInstance.velocity = Direction * BulletSpeed
=======
		BulletInstance.linear_velocity = Direction * BulletSpeed
>>>>>>> parent of 1751937 (Quick fix for ability)
		
		Player.get_tree().get_root().call_deferred("add_child", BulletInstance)
