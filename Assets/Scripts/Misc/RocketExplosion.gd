extends Node2D

# The explosion effect for the rocket projectile

@export var lifetime: float = 2.0 # How long the  lasts
@export var explosion_radius: float = 50.0 # For debug drawing in this scene

# Get shrapnel emitter references
@onready var shrapnel_emitter_1: GPUParticles2D = $ShrapnelParticles1
@onready var shrapnel_emitter_2: GPUParticles2D = $ShrapnelParticles2
@onready var shrapnel_emitter_3: GPUParticles2D = $ShrapnelParticles3
@onready var shrapnel_emitter_4: GPUParticles2D = $ShrapnelParticles4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start shrapnel emitters
	lifetime = shrapnel_emitter_1.lifetime
	shrapnel_emitter_1.restart()
	shrapnel_emitter_2.restart()
	shrapnel_emitter_3.restart()
	shrapnel_emitter_4.restart()
	
	# Self-destruct after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	queue_redraw()

func _draw():
	# Debug draw for the explosion scene itself
	draw_circle(Vector2.ZERO, explosion_radius, Color(1,0,0,0.3))
