extends Projectile
class_name RocketProjectile

@export var explosion_radius_size: float = 100.0 # The AOE for explosion

# Get references to our collision areas
@onready var explosion_area: Area2D = $ExplosionRadius
@onready var explosion_shape: CollisionShape2D = $ExplosionRadius/CollisionShape2D

var has_exploded:bool = false # Class variable for if the explosion has occurerd

func _ready() -> void:
	super._ready()
	explosion_shape.shape.radius = explosion_radius_size # Set the AOE size
	explosion_area.monitoring = false # Initially disable the aoe area
	explosion_area.monitorable = false # Ensure it doesn't get hit by other things

func start(start_position: Vector2, direction: Vector2, entity_owner: String, p_effects: Array[ProjectileEffect]):
	super.start(start_position, direction, entity_owner, p_effects) # Call super
	explosion_area.collision_mask = self.collision_mask # Set collision mask based on projectile owner

# Override movement later if needed, for now it just behaves like a normal projectile
func _handle_movement(delta: float):
	super._handle_movement(delta) # Default ballistic movement
	
# On projectle collision, explode, this overrides the defaut projectile behaviour
func _on_body_entered(body: Node2D):
	if not has_exploded:
		_explode()

# Explode...
func _explode():
	has_exploded = true # We have exploded
	
	'''
	TODO: Perform some VFX to show explosion in AOE radius
	'''
	
	explosion_area.monitoring = true # Enable collision monitoring for overlaps
	
	var bodies_in_aoe = explosion_area.get_overlapping_bodies() # Get overlapping bodies
	
	# Deal damage
	for body in bodies_in_aoe:
		if body == self: continue # Ignore self
		if body.has_method("deal_damage"):
			body.deal_damage(damage) # Deal damage to bodies
	
	explosion_area.monitoring = false # Dissable collision monitoring
	
	queue_free() # Destroy self
