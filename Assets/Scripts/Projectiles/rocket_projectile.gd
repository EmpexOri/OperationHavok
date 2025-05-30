extends Projectile
class_name RocketProjectile

@export var explosion_radius_size: float = 50.0 # The AOE for explosion
@export var explosion_scene: PackedScene = null # The explosion VFX

# Variables to handle increasing the rockets speed over time
@export var initial_speed: float = 100.0
@export var max_speed: float = 700.0
@export var acceleration_rate: float = 1000.0

# Get references to our collision areas
@onready var explosion_area: Area2D = $ExplosionRadius
@onready var explosion_shape: CollisionShape2D = $ExplosionRadius/CollisionShape2D

var has_exploded:bool = false # Class variable for if the explosion has occurerd

func _ready() -> void:
	super._ready()
	explosion_shape.shape.radius = explosion_radius_size # Set the AOE size
	explosion_area.monitoring = false # Initially disable the aoe area
	explosion_area.monitorable = false # Ensure it doesn't get hit by other things

func start(start_position: Vector2, direction: Vector2, entity_owner: String, p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D):
	super.start(start_position, direction, entity_owner, p_effects, space_state) # Call super
	has_exploded = false # Ensure has_exploded is false
	explosion_area.collision_mask = self.collision_mask # Set collision mask based on projectile owner
	explosion_area.position = Vector2.ZERO # Set the collision areas local position to projectiles world location
	self.speed = initial_speed # Override speed to use initial speed
	self.velocity = direction.normalized() * self.speed # Calculate velocity based on new speed
	
# Override movement to increase acceleration over time, mimic a rocket...
func _handle_movement(delta: float):
	# Keep accelerating until max speed is reached
	if self.speed < max_speed:
		self.speed += acceleration_rate * delta # Accelerate
		if self.speed >= max_speed:
			self.speed = max_speed # clamp max speed
		
		self.velocity = self.velocity.normalized() * self.speed # Update velocity
	
	super._handle_movement(delta) # position += self.velocity * delta
	
# On projectle collision, explode, this overrides the defaut projectile behaviour
func _on_body_entered(body: Node2D):
	if not has_exploded:
		_explode()

# Explode...
func _explode():
	if has_exploded: return # Just in case
	has_exploded = true # We have exploded
	
	if lifetime_timer and not lifetime_timer.is_stopped():
		lifetime_timer.stop()
	
	# Explosion VFX
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate()
		explosion_instance.start(explosion_radius_size)
		get_parent().add_child(explosion_instance)
		explosion_instance.global_position = self.global_position
		
	
	explosion_area.monitoring = true # Enable collision monitoring for overlaps
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var bodies_in_aoe = explosion_area.get_overlapping_bodies() # Get overlapping bodies
	
	# Deal damage to AOE targets
	for body in bodies_in_aoe:
		if body == self: continue # Ignore self
		if body.has_method("deal_damage"):
			body.deal_damage(damage) # Deal damage to bodies
		
		# Apply projectile effects to AOE targets
		if current_effects:
			for effect in current_effects:
				if effect.has_method("on_hit"):
					effect.on_hit(self, body)
	
	explosion_area.monitoring = false # Dissable collision monitoring
	explosion_shape.disabled = true # Disable collision shape
	
	queue_free() # Destroy self
	
