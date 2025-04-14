extends Projectile

# Override projectile to get effects similar to a projectile but with melee movement

@export var arc_radius: float = 50.0 # How far the arc extends from the origin
@export var total_arc_degrees: float = 90.0 # The total angle the arc covers in degrees (e.g., 90 degrees sweep)
@export var push_back: float = 10.0
# How the arc is oriented relative to the initial direction.
# 0.0 = centered, -0.5 = starts fully behind, +0.5 = starts fully forward
@export var arc_start_bias: float = 0

var initial_position: Vector2
var base_aim_angle: float # The initial direction angle in radians
var start_arc_angle: float # Starting angle of the arc in radians
var end_arc_angle: float # Ending angle of the arc in radians

func start(start_position: Vector2, direction: Vector2, entity_owner: String, p_effects: Array[ProjectileEffect]):
	super.start(start_position, direction, entity_owner, p_effects) # Call the super class to setup inital parameters
	
	initial_position = start_position
	base_aim_angle = direction.angle()
	
	var half_arc_rad = deg_to_rad(total_arc_degrees) / 2.0
	var center_offset_from_aim = lerp(-half_arc_rad, half_arc_rad, arc_start_bias + 0.5)
	var arc_center_angle = base_aim_angle + center_offset_from_aim
	
	start_arc_angle = arc_center_angle - half_arc_rad
	end_arc_angle = arc_center_angle + half_arc_rad
	
	var initial_offset = Vector2.RIGHT.rotated(start_arc_angle) * arc_radius
	global_position = initial_position + initial_offset
	rotation = start_arc_angle 

func _handle_movement(delta: float):
	var elapsed_time  = lifetime - lifetime_timer.time_left
	
	var time_ratio = 0.0
	if lifetime > 0.001:
		time_ratio = clamp(elapsed_time  / lifetime, 0.0, 1.0)
	
	var current_angle = lerp_angle(start_arc_angle, end_arc_angle, time_ratio)
	
	var offset_vector = Vector2.RIGHT.rotated(current_angle) * arc_radius
	
	global_position = initial_position + offset_vector
	rotation = current_angle
