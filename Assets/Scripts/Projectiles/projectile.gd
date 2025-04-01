extends Area2D
class_name Projectile

# The base projectile script, to be extended, but also works for a typical balistic projectile

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
	# Connect signals
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(queue_free) # Destroy when lifetime expires
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free) # Destroy when off-screen
	body_entered.connect(_on_body_entered) # Handle collisions
	lifetime_timer.start() 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Basic movement, this can be overriden to get different behaviour depending on projectile type
	position += velocity * delta

# Called when instatiating the projectile, sets the initial position, rotation and velocity
func start(start_position: Vector2, direction: Vector2, entity_owner: String):
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	if entity_owner == "Enemy":
		collision_layer = 4  # Enemy projectile layer
		collision_mask = 1  # Only collides with players
	elif entity_owner == "Player":
		collision_layer = 3  # Player projectile layer
		collision_mask = 2  # Only collides with enemies
	else:
		print("Unknown owner set for projectile")
	
# When we get a collision, uses collision masks
func _on_body_entered(body: Node2D):
	# Damage the entity, destroy the projectile
	if body.has_method("deal_damage"):
		body.deal_damage(damage)
		queue_free()
