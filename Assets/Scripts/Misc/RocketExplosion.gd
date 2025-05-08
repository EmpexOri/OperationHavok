extends Node2D

# The explosion effect for the rocket projectile

@export var lifetime: float = 0.5 # How long the  lasts
@export var explosion_radius: float = 50.0 # For debug drawing in this scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Self-destruct after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	queue_redraw()

func _draw():
	# Debug draw for the explosion scene itself
	draw_circle(Vector2.ZERO, explosion_radius, Color(1,0,0,0.3))
