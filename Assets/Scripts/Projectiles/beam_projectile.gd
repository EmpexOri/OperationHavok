extends Projectile
class_name BeamProjectile

@export var range: float = 1000.0 # How far the beam will shoot
@export var width: float = 5.0 # The width of the beam

var start_point: Vector2 # The start point of the beam
var end_point: Vector2 # The end point of the beam

@onready var beam: Line2D = $Line2D # Grab a reference to our Line2D

var hit_this_beam: Array[Node2D] = [] # Bodies hit by this beam

func _ready() -> void:
	beam.width = width # Set the beams width
	beam.points = [Vector2.ZERO, Vector2.ZERO] # Initially set all points to zero

func start(start_position: Vector2, direction: Vector2, entity_owner: String, p_effects: Array[ProjectileEffect]):
	super.start(start_position, direction, entity_owner, p_effects) # Call the super
	
	start_point = global_position # Get the starting point
	
	hit_this_beam.clear() # Clear the hit entites array for safety
	
	var space_state = get_world_2d().direct_space_state # Get the space state
	if not space_state:
		return
		
	# Create the shape that will be used to query collisions
	var beam_shape = RectangleShape2D.new() 
	beam_shape.size = Vector2(range, width) 
	
	# Calculate beam position and rotation
	var beam_center = start_point + direction * (range / 2.0)
	var beam_angle = direction.angle()
	var beam_transform = Transform2D(beam_angle, beam_center)
	
	# Create the query
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = beam_shape
	query.transform = beam_transform
	query.collision_mask = self.collision_mask
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	# Perform the query, store the results
	var results = space_state.intersect_shape(query)
	
	# Print results for debugging
	print("Beam results count: ", results.size())
	for i in range(results.size()):
		print("Hit: ", results[i].collider.name, " at position: ", results[i].collider.global_position)
	
	# Draw the beam - this is distinct from the rect we use to query collisions
	end_point = start_point + direction * range
	beam.points = [Vector2.ZERO, to_local(end_point)]
	
# No movement on beam, override and pass
func _handle_movement(delta: float):
	pass

# Collision will be handled by a ray query, override and pass
func _on_body_entered(body: Node2D):
	pass
	
