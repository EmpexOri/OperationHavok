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

# Projectile effects are stored in this array
var current_effects: Array[ProjectileEffect] = []

# References
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var lifetime_timer = $LifetimeTimer
@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Bullet")
	# Connect signals
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free) # Destroy when off-screen
	body_entered.connect(_on_body_entered) # Handle collisions

# This method MUST be created and called with super() in the derived class
func _process(delta: float) -> void:
	_handle_movement(delta) # Call the interal movement method
	_process_effects(delta) # Call the interal effects process method

# If creating a projectile with different movement, say a grenade arch, you would override this class
func _handle_movement(delta: float):
	# Basic movement ballistic movement
	position += velocity * delta

# This method is always called from _process, it does not need to be touched or created in the derived class
func _process_effects(delta: float):
	# Process effects for projectiles
	if current_effects:
		for effect in current_effects:
			if effect.has_method("process_effect"):
				effect.process_effect(self, delta)

# Called when instatiating the projectile, sets the initial position, rotation and velocity
func start(start_position: Vector2, direction: Vector2, entity_owner: String, p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D):
	# Store any effects attached to the projectile
	current_effects = p_effects
	
	# Initialize projectile stats
	speed = base_speed
	damage = base_damage
	lifetime = base_lifetime
	
	# Setup any effects if they support initialization
	if current_effects:
		for effect in current_effects:
			if effect.has_method("setup"):
				effect.setup(self)
	
	# Set initial position
	global_position = start_position
	
	# Apply direction vector and scale by speed to get final velocity
	velocity = direction.normalized() * speed

	# Set the projectile's visual rotation to match movement direction
	rotation = direction.angle()

	# Flip sprite vertically if it's aiming to the left to avoid upside-down visuals
	if abs(rotation) > PI / 2:
		sprite_2d.scale.y = -1
	else:
		sprite_2d.scale.y = 1
	
	# Configure collision layers depending on the projectile owner
	if entity_owner == "Enemy":
		collision_layer = 4  # Enemy projectile layer
		collision_mask = 1   # Collides with player layer
	elif entity_owner == "Player":
		collision_layer = 3  # Player projectile layer
		collision_mask = 2   # Collides with enemy layer
	else:
		print("Unknown owner set for projectile")  # Fallback warning
	
	# Start lifetime timer to automatically free the projectile after expiration
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()
	
# When we get a collision, uses collision masks
func _on_body_entered(body: Node2D):
	# Damage the entity, destroy the projectile
	if body.has_method("deal_damage"):
		body.deal_damage(damage, global_position) # Deal damage to entity if it has the deal_damage method
	
	if current_effects:
		for effect in current_effects:
			if effect.has_method("on_hit"):
				if effect.on_hit(self, body):
					queue_free() # If the effects on hit returns true we remove the projectile
	else:
		queue_free() # If we have no effects, just remove the projectile on hit
