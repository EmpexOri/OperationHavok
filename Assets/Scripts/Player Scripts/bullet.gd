extends RigidBody2D

func _ready():
	var LifeTimer = Timer.new()
	LifeTimer.wait_time = 1
	LifeTimer.one_shot = true  # Timer only goes once
	LifeTimer.connect("timeout", Callable(self, "queue_free")) # Executes the spawn function once timer has ended
	add_child(LifeTimer)
	LifeTimer.start()

func _on_area_2d_body_entered(body: Node2D):
	if "Enemy" in body.name or "Player" in body.name: # Fixed
		queue_free()
