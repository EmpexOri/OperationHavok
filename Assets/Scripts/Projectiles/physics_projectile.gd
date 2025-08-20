extends CharacterBody2D
class_name PhysicsProjectile

# Base stats, you set these in the inspector for each projectile
@export var base_speed: float = 100
@export var base_damage: float = 20.0
@export var base_lifetime: float = 10.0

# Current values for projectile stats - these will be modified by effects
var speed: float
var damage: float
var lifetime: float

# Projectile effects are stored in this array
var current_effects: Array[ProjectileEffect] = []

# The space state, used to pass to weapon effects
var _space_state: PhysicsDirectSpaceState2D 

# References
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite_2d = $Sprite2D
@onready var lifetime_timer = $LifetimeTimer
@onready var visible_on_screen_notifier_2d = $VisibleOnScreenNotifier2D

func _ready() -> void:
	add_to_group("Bullet")
	# Connect signals
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free) # Destroy when off-screen

func _process(delta: float) -> void:
	_handle_movement(delta) # Call the interal movement method
	_process_effects(delta) # Call the interal effects process method

func _handle_movement(delta: float):
	var collision_info: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision_info:
		_on_collision(collision_info) # Process physics collisions

func _process_effects(delta: float):
	# Process effects for projectiles
	if current_effects:
		for effect in current_effects:
			if effect.has_method("process_effect"):
				effect.process_effect(self, delta, _space_state)

func start(start_position: Vector2, direction: Vector2, entity_owner: String, 
		p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D, 
		damage_multiplier: float):
	# Store any effects attached to the projectile
	current_effects = p_effects
	
	# Set space state for effects
	_space_state = space_state
	
	# Initialize projectile stats
	speed = base_speed
	damage = base_damage * damage_multiplier
	lifetime = base_lifetime
	
	# Setup any effects if they support initialization
	if current_effects:
		for effect in current_effects:
			if effect.has_method("setup"):
				effect.setup(self)
	
	# Set initial position
	global_position = start_position
	
	# Apply direction vector and scale by speed to get final velocity
	self.velocity = direction.normalized() * speed

	# Set the projectile's visual rotation to match movement direction
	rotation = direction.angle()
	
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
	

func _on_collision(collision: KinematicCollision2D):
	var body: Node2D = collision.get_collider()
	if not is_instance_valid(body):
		return
	
	if body.has_method("deal_damage"):
			body.deal_damage(damage, global_position)
	
	if current_effects:
		for effect in current_effects:
			if effect.has_method("on_hit"):
				if effect.on_hit(self, body, collision):
					queue_free()
				else:
					return
	
	queue_free()
