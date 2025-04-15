extends Projectile
class_name BeamProjectile

@export var range: float = 1000.0 # How far the beam will shoot
@export var width: float = 5.0 # The width of the beam

var start_point: Vector2 # The start point of the beam
var end_point: Vector2 # The end point of the beam

@onready var beam: Line2D = $Line2D # Grab a reference to our Line2D

func _ready() -> void:
	beam.width = width # Set the beams width
	beam.points = [Vector2.ZERO, Vector2.ZERO] # Initially set all points to zero

func start(start_position: Vector2, direction: Vector2, entity_owner: String, p_effects: Array[ProjectileEffect]):
	super.start(start_position, direction, entity_owner, p_effects) # Call the super
	
	#start_point = global_position 
	end_point = start_point + direction * range # Generate the end point of the beam
	beam.points = [Vector2.ZERO, to_local(end_point)] # Set the points for the Line2D
	
# No movement on beam, override and pass
func _handle_movement(delta: float):
	pass

# Collision will be handled by a ray query, override and pass
func _on_body_entered(body: Node2D):
	pass
