extends RigidBody2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Collided with: ", body.name)
	if "Enemy" in body.name or "Player" in body.name: # Fixed
		print("Bullet hit!")
		queue_free()
