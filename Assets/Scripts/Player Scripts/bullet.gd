extends RigidBody2D


func _on_area_2d_body_entered(body: Node2D):
	if "Enemy" in body.name or "Player" in body.name: # Fixed
		queue_free()
