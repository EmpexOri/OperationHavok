extends Node2D

# The explosion effect for the rocket projectile

@export var lifetime: float = 0.25 # How long the debug circle lasts
@export var explosion_radius: float # For debug drawing explosion area

# Get shrapnel emitter references
@onready var shrapnel_emitter_1: GPUParticles2D = $ShrapnelParticles1
@onready var shrapnel_emitter_2: GPUParticles2D = $ShrapnelParticles2
@onready var shrapnel_emitter_3: GPUParticles2D = $ShrapnelParticles3
@onready var shrapnel_emitter_4: GPUParticles2D = $ShrapnelParticles4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start shrapnel emitters
	shrapnel_emitter_1.restart()
	shrapnel_emitter_2.restart()
	shrapnel_emitter_3.restart()
	shrapnel_emitter_4.restart()
	
	# Start lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	# TEMP Draw collision area
	queue_redraw()
	
func start(_radius: float):
	explosion_radius = _radius

func _draw():
	# Debug draw for the explosion scene itself
	draw_circle(Vector2.ZERO, explosion_radius, Color(1,0,0,0.3))
