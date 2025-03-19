extends RigidBody2D

func _ready():
	var LifeTimer = Timer.new()
	LifeTimer.wait_time = 1
	LifeTimer.one_shot = true  # Timer only goes once
	LifeTimer.connect("timeout", Callable(self, "queue_free")) # Executes the spawn function once timer has ended
	add_child(LifeTimer)
	LifeTimer.start()

func _on_area_2d_body_entered(body: Node2D):
	if body != self and (body.is_in_group("Player") or body.is_in_group("Enemy") or body.is_in_group("Bullet") or body.is_in_group("Laser")): # Fixed
		queue_free()
