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
	
	# Perform a ray query to detect collisions
	start_point = global_position 
	
	hit_this_beam.clear()

	var space_state = get_world_2d().direct_space_state
	
	var beam_shape = RectangleShape2D.new()
	beam_shape.size = Vector2(range / 2, width / 2)
	var beam_center = start_point + direction * (range / 2.0)
	var beam_angle = direction.angle()
	var beam_transform = Transform2D(beam_angle, beam_center)
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = beam_shape
	query.transform = beam_transform
	query.collision_mask = self.collision_mask
	query.exclude = [self]
	
	var results: Array = space_state.intersect_shape(query)
	
	if results.size() > 0:
		print("Beam Hit Count: ", results.size())
	
	# Draw the beam
	end_point = start_point + direction * range # Generate the end point of the beam
	beam.points = [Vector2.ZERO, to_local(end_point)] # Set the points for the Line2D
	
# No movement on beam, override and pass
func _handle_movement(delta: float):
	pass

# Collision will be handled by a ray query, override and pass
func _on_body_entered(body: Node2D):
	pass
