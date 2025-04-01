extends Area2D

# The base projectile script for the projectile super class, projectile should not be instantiated

# Parameters - Override in derived class
@export var speed: float = 100
@export var damage: float = 20.0
@export var lifetime: float = 10.0

# Projectile velocity
var velocity: Vector2 = Vector2.ZERO

# References
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var lifetime_timer = $LifetimeTimer
@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Basic movement, this can be overriden to get different behaviour depending on projectile type
	position += velocity * delta

# Called when instatiating the projectile, sets the initial position, rotation and velocity
func start(start_position: Vector2, direction: Vector2):
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	
# When we get a collision
func _on_body_entered(body: Node2D):
	# Damage the enemy
	if body.is_in_group("Enemy"):
		body.deal_damage()
	
	# Destroy the projectile, more groups will be added here when we have an environment
	if body.is_in_group("Enemy"):
		queue_free() 
