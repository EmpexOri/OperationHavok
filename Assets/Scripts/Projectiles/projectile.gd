extends Area2D
class_name Projectile

# The base projectile script, to be extended, but also works for a typical balistic projectile

# Base stats, you set these in the inspector for each projectile
@export var base_speed: float = 100
@export var base_damage: float = 20.0
@export var base_lifetime: float = 10.0

# Current values for projectile stats - these will be modified by effects
var speed: float
var damage: float
var lifetime: float

# Projectile velocity
var velocity: Vector2 = Vector2.ZERO

# Projectile effects
var current_effects: Array[ProjectileEffect] = []

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
	
	# Process effects for projectiles
	if current_effects:
		for effect in current_effects:
			effect.proccess_effect(self, delta)

# Called when instatiating the projectile, sets the initial position, rotation and velocity
func start(start_position: Vector2, direction: Vector2, entity_owner: String):
	# Initialise our stats from base stats
	speed = base_speed
	damage = base_damage
	lifetime = base_lifetime
	
	#if p_effects:
		#for effect in p_effects:
			#current_effects.push_front(effect)
	
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	if entity_owner == "Enemy" or entity_owner == "Enemy2" or entity_owner == "Enemy4":
		collision_layer = 4  # Enemy projectile layer
		collision_mask = 1  # Only collides with players
		
		if entity_owner == "Enemy2":
			sprite_2d.modulate = Color(0.3, 0.5, 1)
		if entity_owner == "Enemy4":
			sprite_2d.modulate = Color(0.9, 0.9, 0)
		
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
	
	if current_effects:
		for effect in current_effects:
			if effect.on_hit(self, body):
				queue_free()
	else:
		queue_free()
